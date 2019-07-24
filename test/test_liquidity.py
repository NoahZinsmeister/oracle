from eth_tester import EthereumTester


def test_liquidity(w3, LIQUIDITY):
    block_number = w3.eth.getBlock("latest")["number"]
    assert LIQUIDITY.caller().get_cumulative_liquidity(0, 0) == (0, 0, block_number)
    LIQUIDITY.functions.trade(20, 20).transact()
    assert LIQUIDITY.caller().get_cumulative_liquidity(0, 0) == (20, 20, block_number + 1)
    # w3.testing.mine()
    # assert LIQUIDITY.caller().get_cumulative_liquidity(1, 1) == (21, 21, block_number + 2)
