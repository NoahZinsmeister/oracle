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


tau: public(timedelta) # the time period (in seconds) of the ema
price_average: Price # the ema up to the timestamp of the most recent block with a trade


# @dev Construct a Price struct.
@private
@constant
def get_price(price: decimal, time: timestamp) -> Price:
    return Price({price: price, time: time})
 

# @dev Calculate the price for a specified liquidity pool size.
@private
@constant
def get_price_from_liquidity(amount_eth: uint256, amount_token: uint256, time: timestamp) -> Price:
    price: decimal = convert(amount_eth, decimal) / convert(amount_token, decimal)
    return self.get_price(price, time)


# @dev ETH/Token amounts should be interpreted as the amounts on the first addition of liquidity.
@public
def __init__(_tau: timedelta, amount_eth_initial: uint256, amount_token_initial: uint256):
    self.tau = _tau
    # initialize the ema (replicate self.get_price_from_liquidity)
    price: decimal = convert(amount_eth_initial, decimal) / convert(amount_token_initial, decimal)
    self.price_average = Price({price: price, time: block.timestamp})


# @dev Calculate the weight to assign to the current ema vs the latest observation.
@public
@constant
def get_weight(time_elapsed: timedelta) -> decimal:
    x: decimal = convert(as_unitless_number(time_elapsed), decimal) / convert(as_unitless_number(self.tau), decimal)

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


# @dev Increment the ema.
@public
@constant
def get_price_average_next(price_current: Price) -> Price:
    w: decimal = self.get_weight(price_current.time - self.price_average.time)
    price_next: decimal = (w * self.price_average.price) + ((1.0 - w) * price_current.price)
    time_next: timestamp = price_current.time
    return self.get_price(price_next, time_next)


# @dev Simulate trading. ETH/Token amounts should be interpreted as the amounts currently in the contract.
@public
def trade(amount_eth_current: uint256, amount_token_current: uint256):
    # if self.price_average is stale i.e. it hasn't been updated this block i.e. this is the first trade of the block...
    if block.timestamp > self.price_average.time:
        # ...update self.price_average with current price i.e. price as of after the last trade of the most recent block
        price_current: Price = self.get_price_from_liquidity(amount_eth_current, amount_token_current, block.timestamp)
        self.price_average = self.get_price_average_next(price_current)


# @dev Get the latest ema. ETH/Token amounts should be interpreted as the amounts currently in the contract.
@public
@constant
def get_price_average(amount_eth_current: uint256, amount_token_current: uint256) -> Price:
    if block.timestamp > self.price_average.time:
        price_current: Price = self.get_price_from_liquidity(amount_eth_current, amount_token_current, block.timestamp)
        return self.get_price_average_next(price_current)
    else:
        return self.price_average
