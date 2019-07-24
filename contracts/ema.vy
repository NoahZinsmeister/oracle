e0: constant(decimal) =   1.0000000000 # e**0
e1: constant(decimal) =   2.7182818285 # e**1
e2: constant(decimal) =   7.3890560989 # e**2
e3: constant(decimal) =  20.0855369232 # e**3
e4: constant(decimal) =  54.5981500331 # e**4
e5: constant(decimal) = 148.4131591026 # e**5
e6: constant(decimal) = 403.4287934927 # e**6


struct Price:
    price: decimal
    time: timestamp


tau: public(timedelta) # the time period (in seconds) of our ema
average_price: Price # the ema up to (non-inclusive) the timestamp of the most recent block with a trade


# @dev Construct a Price struct.
@public
@constant
def get_price(price: decimal, time: timestamp) -> Price:
    return Price({price: price, time: time})
 

# @dev Calculate the price for the specified liquidity pool size.
@public
@constant
def get_price_from_liquidity(eth_amount: uint256, token_amount: uint256, time: timestamp) -> Price:
    return self.get_price(convert(eth_amount, decimal) / convert(token_amount, decimal), time)


# @dev Calculate the weight which our new ema should give to the current ema vs the latest value.
@public
@constant
def get_weight(elapsed_time: timedelta) -> decimal:
    x: decimal = convert(as_unitless_number(elapsed_time), decimal) / convert(as_unitless_number(self.tau), decimal)

    # compute (2, 2) padé approximant of e^-x around x = 0, 1, 2, 3, 4, 5, 6...
    # ...for x >= 6.5, truncate to w = 0 i.e. for weights guaranteed to be <~.15%
    w: decimal
    if x < .5:
        w = (x * (x -  6.0) + 12.0) / (e0 * (x * (x + 6.0) + 12.0)) # x = 0
    elif x < 1.5:
        w = (x * (x -  8.0) + 19.0) / (e1 * (x * (x + 4.0) +  7.0)) # x = 1
    elif x < 2.5:
        w = (x * (x - 10.0) + 28.0) / (e2 * (x * (x + 2.0) +  4.0)) # x = 2
    elif x < 3.5:
        w = (x * (x - 12.0) + 39.0) / (e3 * (x * (x + 0.0) +  3.0)) # x = 3
    elif x < 4.5:
        w = (x * (x - 14.0) + 52.0) / (e4 * (x * (x - 2.0) +  4.0)) # x = 4
    elif x < 5.5:
        w = (x * (x - 16.0) + 67.0) / (e5 * (x * (x - 4.0) +  7.0)) # x = 5
    elif x < 6.5:
        w = (x * (x - 18.0) + 84.0) / (e6 * (x * (x - 6.0) + 12.0)) # x = 6
    else:
        w = 0.0

    return w



@public
def __init__(_tau: timedelta, eth_amount_DEV: uint256, token_amount_DEV: uint256):
    self.tau = _tau
    eth_amount: uint256 = eth_amount_DEV
    token_amount: uint256 = token_amount_DEV
    self.average_price = Price({
        price: convert(eth_amount, decimal) / convert(token_amount, decimal), time: block.timestamp
    })


# @dev Increment our ema.
@public
@constant
def get_next_average_price(last_average_price: Price, last_price: Price) -> Price:
    w: decimal = self.get_weight(last_price.time - last_average_price.time)
    next_price: decimal = (w * last_average_price.price) + ((1.0 - w) * last_price.price)
    next_time: timestamp = last_price.time
    return self.get_price(next_price, next_time)


# @dev Simulate trading. Liquidity values passed in for illustrative purposes.
@public
def trade(eth_amount_DEV: uint256, token_amount_DEV: uint256):
    # if self.average_price is old, i.e. this is the first trade in this block...
    if self.average_price.time < block.timestamp:
        # ...update self.average_price with current price i.e. as of after the last trade of the most recent block
        eth_amount: uint256 = eth_amount_DEV
        token_amount: uint256 = token_amount_DEV
        self.average_price = self.get_next_average_price(
            self.average_price,
            self.get_price_from_liquidity(eth_amount, token_amount, block.timestamp)
        )


# @dev Get the latest ema.
@public
@constant
def get_average_price(eth_amount_DEV: uint256, token_amount_DEV: uint256) -> Price:
   # if self.average_price is old, mock what it should be, else report the already calculated value
    if self.average_price.time < block.timestamp:
        eth_amount: uint256 = eth_amount_DEV
        token_amount: uint256 = token_amount_DEV
        return self.get_next_average_price(
            self.average_price,
            self.get_price_from_liquidity(eth_amount, token_amount, block.timestamp)
        )
    else:
        return self.average_price
