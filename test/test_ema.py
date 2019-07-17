from decimal import Decimal

tau = 3600


def test_approximation(w3, EMA):
    # make sure our approximation is monotonic around the bounds
    for boundary_check in [1/2, 3/2]:
        print(f'Checking boundary: {boundary_check}.')
        # make sure none of our boundary_check values are getting rounded
        assert tau * boundary_check % 1 == 0
        assert EMA.caller.get_weight(int(tau * boundary_check) - 1) > EMA.caller.get_weight(int(tau * boundary_check))

    # benchmark some points of interest
    benchmarks = {
        # 1/e**x:  0.9997222608
        # pade(0): 0.9997222608
        1 / tau:  '0.9997222609',

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
        2:        '0.1353352832'
    }
    for benchmark, expected_value in benchmarks.items():
        print(f'Checking benchmark: {benchmark}.')
        # make sure none of our benchmark values are getting rounded
        assert tau * benchmark % 1 == 0
        assert EMA.caller.get_weight(int(tau * benchmark)) == Decimal(expected_value)

    # check that anything larger than tau * 2 has weight tau * 2
    assert EMA.caller.get_weight(int(tau * 10)) == EMA.caller.get_weight(int(tau * 2))
