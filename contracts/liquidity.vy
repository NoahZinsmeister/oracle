struct Liquidity:
    amount_eth: uint256
    amount_token: uint256
    block_number: uint256


liquidity_cumulative: Liquidity # the cumulative blockwise liquidity up to the most recent block with a trade


# @dev Construct a Liquidity struct.
@private
@constant
def get_liquidity(amount_eth: uint256, amount_token: uint256, block_number: uint256) -> Liquidity:
    return Liquidity({amount_eth: amount_eth, amount_token: amount_token, block_number: block_number})


# @dev ETH/Token amounts should be interpreted as the amounts on the first addition of liquidity.
@public
def __init__(amount_eth_initial: uint256, amount_token_initial: uint256):
    # initialize the cumulative liquidity (replicate self.get_liquidity)
    self.liquidity_cumulative = (
        Liquidity({amount_eth: amount_eth_initial, amount_token: amount_token_initial, block_number: block.number})
    )


# @dev Increment the liquidity accumulator.
@public
@constant
def get_liquidity_cumulative_next(liquidity_current: Liquidity) -> Liquidity:
    blocks_passed: uint256 = liquidity_current.block_number - self.liquidity_cumulative.block_number
    amount_eth_next: uint256 = self.liquidity_cumulative.amount_eth + liquidity_current.amount_eth * blocks_passed
    amount_token_next: uint256 = self.liquidity_cumulative.amount_token + liquidity_current.amount_token * blocks_passed
    block_number_next: uint256 = liquidity_current.block_number
    return self.get_liquidity(amount_eth_next, amount_token_next, block_number_next)


# @dev Simulate trading. ETH/Token amounts should be interpreted as the amounts currently in the contract.
@public
def trade(amount_eth_current: uint256, amount_token_current: uint256):
    # if self.liquidity_cumulative i.e. it hasn't been updated this block i.e. this is the first trade of the block...
    if block.number > self.liquidity_cumulative.block_number:
        # ...update self.liquidity_cumulative with current liquidity
        liquidity_current: Liquidity = self.get_liquidity(amount_eth_current, amount_token_current, block.number)
        self.liquidity_cumulative = self.get_liquidity_cumulative_next(liquidity_current)


# @dev Get the latest accumulator. ETH/Token amounts should be interpreted as the amounts currently in the contract.
@public
@constant
def get_liquidity_cumulative(amount_eth_current: uint256, amount_token_current: uint256) -> Liquidity:
    if block.number > self.liquidity_cumulative.block_number:
        liquidity_current: Liquidity = self.get_liquidity(amount_eth_current, amount_token_current, block.number)
        return self.get_liquidity_cumulative_next(liquidity_current)
    else:
        return self.liquidity_cumulative
