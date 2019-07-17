from decimal import Decimal

tau = 3600


def test_approximation(w3, EMA):
    print(EMA.caller.average_price__price())
    print(EMA.caller.average_price__time())

    assert False

    assert tau * 1/2 % 1 == 0
    assert tau * 1/4 % 1 == 0

    # make sure our approximation is monotonic around the bounds
    for boundary_check in [1/2, 3/2, 5/2, 7/2, 9/2]:
        print(f'Checking boundary: {boundary_check}.')
        assert EMA.caller.get_weight(int(tau * boundary_check) - 1) > EMA.caller.get_weight(int(tau * boundary_check))

    # check the smallest increment (1)
    # 1/e**x:                                   0.9997222608
    # pade(0):                                  0.9997222608
    assert EMA.caller.get_weight(1) == Decimal('0.9997222609')

    # check the biggest increment (tau * 4.5 -1)
    # 1/e**x:                                                    0.0111120828
    # pade(4):                                                   0.0111125709
    assert EMA.caller.get_weight(int(tau * 9/2 - 1)) == Decimal('0.0111125709')

    # benchmark some points of interest
    benchmarks = {
        # 1/e**x:  0.7788007831
        # pade(0): 0.7788018433
        1/4:      '0.7788018434',

        # 1/e**x:  0.6065306597
        # pade(1): 0.6065039436
        1/2:      '0.6065039435',

        # 1/e**x:  0.4723665527
        # pade(1): 0.4723659097
        3/4:      '0.4723659096',

        # 1/e**x:  0.3678794412
        # pade(1): 0.3678794412
        1:        '0.3678794411',

        # 1/e**x:  0.2231301601
        # pade(2): 0.2231203318
        3/2:      '0.2231203318',

        # 1/e**x:  0.1353352832
        # pade(2): 0.1353352832
        2:        '0.1353352832',

        # 1/e**x:  0.0497870684
        # pade(3): 0.0497870684
        3:        '0.0497870683'
    }
    for benchmark, expected_value in benchmarks.items():
        print(f'Checking benchmark: {benchmark}.')
        assert EMA.caller.get_weight(int(tau * benchmark)) == Decimal(expected_value)

    # check that anything >= than tau * 4.5 has weight 0
    assert EMA.caller.get_weight(int(tau * 9/2)) == Decimal('0')
    assert EMA.caller.get_weight(int(tau * 5)) == Decimal('0')
