from decimal import Decimal

from constants import TAU


def test_approximation(w3, EMA):
    # check some general properties (relies on largest approximation being centered around 6) #
    assert (TAU * 1/2) % 1 == 0

    # make sure our approximation is monotonic around the bounds
    for boundary_check in [1/2 + x for x in range(0, 7)]:
        print(f'Checking boundary: {boundary_check}.')
        assert EMA.caller.get_weight(int(TAU * boundary_check) - 1) > EMA.caller.get_weight(int(TAU * boundary_check))

    assert (TAU * 1/4) % 1 == 0

    # benchmark some points of interest
    benchmarks = {
        # 1/e**x:  0.7788007831
        # pade(0): 0.7788018433
        1/4:      '0.7788018433',

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
        assert EMA.caller.get_weight(int(TAU * benchmark)) == Decimal(expected_value)

    # check some things specific to tau = 86400 #

    # check the smallest increment (1)
    # 1/e**x:                                   0.9999884260
    # pade(0):                                  0.9999884260
    assert EMA.caller.get_weight(1) == Decimal('0.9999884260')

    # check the biggest increment (tau * 6.5 - 1)
    # 1/e**x:                                                          0.0015034566
    # pade(6):                                                         0.0015035228
    assert EMA.caller.get_weight(int(TAU * (1/2 + 6) - 1)) == Decimal('0.0015035228')

    # check that anything >= than tau * 6.5 has weight 0
    assert EMA.caller.get_weight(int(TAU * (1/2 + 6))) == Decimal('0')
    assert EMA.caller.get_weight(int(TAU * 7)) == Decimal('0')
