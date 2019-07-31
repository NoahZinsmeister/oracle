def test_liquidity(w3, LIQUIDITY):
    block_number = w3.eth.getBlock("latest")["number"]
    assert LIQUIDITY.caller().get_liquidity_cumulative(0, 0) == (1, 1, block_number)
    LIQUIDITY.functions.trade(20, 20).transact()
    assert LIQUIDITY.caller().get_liquidity_cumulative(0, 0) == (21, 21, block_number + 1)
