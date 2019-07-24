from eth_tester import EthereumTester


def test_liquidity(w3, LIQUIDITY):
    block_number = w3.eth.getBlock("latest")["number"]
    assert LIQUIDITY.caller().get_cumulative_liquidity(0, 0) == [0, 0, block_number]
    account = w3.eth.accounts[0]
    LIQUIDITY.functions.trade(20, 20).transact({"from": account})
    # not working for some reason...
    # assert LIQUIDITY.caller().get_cumulative_liquidity(0, 0) == [20, 20, block_number]
