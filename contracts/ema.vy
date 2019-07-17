e: constant(decimal) = 2.7182818285
e2: constant(decimal) = 7.3890560989
tau: constant(decimal) = 3600.0 # 1 hour


@public
def get_weight(elapsed_time: timedelta) -> decimal:
    x: decimal = convert(as_unitless_number(elapsed_time), decimal) / tau

    # cap the influence that long-standing observations have at tau * 2
    if (x > 2.0):
        x = 2.0

    w: decimal
    if (x < .5):
        # PadeApproximant[E^(-x), {x, 0, {2, 2}}]
        w = 1.0 - (12.0*x / (x * (x + 6.0) + 12.0))
    elif x < 1.5:
        # PadeApproximant[E^(-x), {x, 1, {2, 2}}]
        w = (x * (x - 8.0) + 19.0) / (e * (x * (x + 4.0) + 7.0))
    else:
        # PadeApproximant[E^(-x), {x, 2, {2, 2}}]
        w = (x * (x - 10.0) + 28.0) / (e2 * (x * (x + 2.0) + 4.0))

    return w
