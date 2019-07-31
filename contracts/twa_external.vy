struct Liquidity:
    amount_eth: uint256
    amount_token: uint256
    block_number: uint256


struct Price:
    price: decimal
    block_number: uint256


contract Oracle():
    def get_liquidity_cumulative(amount_eth_current: uint256, amount_token_current: uint256) -> Liquidity: constant


oracle: Oracle
liquidity_cumulative: Liquidity # the cumulative blockwise liquidity up to the most recent block with a trade
tau: public(uint256) # the time period (in blocks) of the twa
price_average: Price # the twa up to the most recent block with a trade


# @dev Construct a Price struct.
@private
@constant
def get_price(price: decimal, block_number: uint256) -> Price:
    return Price({price: price, block_number: block_number})


# @dev ETH/Token amounts should be interpreted as the amounts currently in the oracle contract.
@public
def __init__(_oracle: address, amount_eth_current: uint256, amount_token_current: uint256, _tau: uint256, ):
    self.oracle = Oracle(_oracle)
    # initialize the liquidity accumulator
    self.liquidity_cumulative = self.oracle.get_liquidity_cumulative(amount_eth_current, amount_token_current)
    self.tau = _tau
    # initialize the twa
    price: decimal = convert(amount_eth_current, decimal) / convert(amount_token_current, decimal)
    self.price_average = Price({price: price, block_number: block.number})


# @dev Calculate the weight to assign to the current twa vs the latest observation.
@public
@constant
def get_weight(blocks_elapsed: uint256) -> decimal:
    return max(1.0, convert(blocks_elapsed, decimal) / convert(self.tau, decimal))


# @dev Increment the twa.
@public
@constant
def get_price_average_next(liquidity_cumulative_current: Liquidity) -> Price:
    amount_eth_delta: uint256 = liquidity_cumulative_current.amount_eth - self.liquidity_cumulative.amount_eth
    amount_token_delta: uint256 = liquidity_cumulative_current.amount_token - self.liquidity_cumulative.amount_token
    price_delta: decimal = convert(amount_eth_delta, decimal) / convert(amount_token_delta, decimal)
    block_number_next: uint256 = liquidity_cumulative_current.block_number

    w: decimal = self.get_weight(block_number_next - self.price_average.block_number)
    price_next: decimal = ((1.0 - w) * self.price_average.price) + (w * price_delta)
    return self.get_price(price_next, block_number_next)


# @dev Poke the twa. ETH/Token amounts should be interpreted as the amounts currently in the oracle contract.
@public
def poke(amount_eth_current: uint256, amount_token_current: uint256):
    if block.number > self.liquidity_cumulative.block_number:
        liquidity_cumulative_current: Liquidity = (
            self.oracle.get_liquidity_cumulative(amount_eth_current, amount_token_current)
        )
        self.price_average = self.get_price_average_next(liquidity_cumulative_current)
        self.liquidity_cumulative = liquidity_cumulative_current


# @dev Get the latest twa. ETH/Token amounts should be interpreted as the amounts currently in the oracle contract.
@public
@constant
def get_price_average(amount_eth_current: uint256, amount_token_current: uint256) -> Price:
    if block.number > self.price_average.block_number:
        liquidity_cumulative_current: Liquidity = (
            self.oracle.get_liquidity_cumulative(amount_eth_current, amount_token_current)
        )
        return self.get_price_average_next(liquidity_cumulative_current)
    else:
        return self.price_average
