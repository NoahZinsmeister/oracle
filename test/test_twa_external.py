from decimal import Decimal


def test_liquidity(w3, TWA_EXTERNAL):
    block_number = w3.eth.getBlock("latest")["number"]
    assert TWA_EXTERNAL.caller().get_price_average(0, 0) == (Decimal('1'), block_number)
