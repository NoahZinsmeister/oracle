struct Liquidity:
    eth_amount: uint256
    token_amount: uint256
    block_number: uint256


cumulative_liquidity: Liquidity # cumulative blockwise liquidity up to (non-inclusive) most recent block with a trade


# @dev Construct a Liquidity struct.
@public
@constant
def get_liquidity(eth_amount: uint256, token_amount: uint256, block_number: uint256) -> Liquidity:
    return Liquidity({eth_amount: eth_amount, token_amount: token_amount, block_number: block_number})


@public
def __init__(eth_amount_DEV: uint256, token_amount_DEV: uint256):
    eth_amount: uint256 = eth_amount_DEV
    token_amount: uint256 = token_amount_DEV
    self.cumulative_liquidity = Liquidity({
        eth_amount: eth_amount, token_amount: token_amount, block_number: block.number
    })


# @dev Increment our liquidity accumulator.
@public
@constant
def get_next_cumulative_liquidity(
    last_cumulative_liquidity: Liquidity, current_cumulative_liquidity: Liquidity
) -> Liquidity:
    blocks_passed: uint256 = current_cumulative_liquidity.block_number - last_cumulative_liquidity.block_number
    next_eth_amount: uint256 = (
        last_cumulative_liquidity.eth_amount + current_cumulative_liquidity.eth_amount * blocks_passed
    )
    next_token_amount: uint256 = (
        last_cumulative_liquidity.token_amount + current_cumulative_liquidity.token_amount * blocks_passed
    )
    next_block_number: uint256 = current_cumulative_liquidity.block_number
    return self.get_liquidity(next_eth_amount, next_token_amount, next_block_number)


# @dev Simulate trading. Liquidity values passed in for illustrative purposes.
@public
def trade(eth_amount_DEV: uint256, token_amount_DEV: uint256):
    # if self.last_liquidity is old, i.e. this is the first trade in this block...
    if self.cumulative_liquidity.block_number < block.number:
        # ...update self.last_liquidity with current liquidity i.e. as of after the last trade of the most recent block
        eth_amount: uint256 = eth_amount_DEV
        token_amount: uint256 = token_amount_DEV
        self.cumulative_liquidity = self.get_next_cumulative_liquidity(
            self.cumulative_liquidity,
            self.get_liquidity(eth_amount, token_amount, block.number)
        )


# @dev Get the latest liquidity.
@public
@constant
def get_cumulative_liquidity(eth_amount_DEV: uint256, token_amount_DEV: uint256) -> Liquidity:
   # if self.last_liquidity is old, mock what it should be, else report the already calculated value
    if self.cumulative_liquidity.block_number < block.number:
        eth_amount: uint256 = eth_amount_DEV
        token_amount: uint256 = token_amount_DEV
        return self.get_next_cumulative_liquidity(
            self.cumulative_liquidity,
            self.get_liquidity(eth_amount, token_amount, block.number)
        )
    else:
        return self.cumulative_liquidity
