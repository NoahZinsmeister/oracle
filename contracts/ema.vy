tau: constant(decimal) = 3600.0 # 1 hour

e: constant(decimal) =   2.7182818285 # e
e2: constant(decimal) =  7.3890560989 # e**2
e3: constant(decimal) = 20.0855369232 # e**3
e4: constant(decimal) = 54.5981500331 # e**4

struct Price:
  price: decimal
  time: timestamp

average_price: Price # the ema for the most recent block with a trade, updated before the first trade of every block

@public
@constant
def get_weight(elapsed_time: timedelta) -> decimal:
    x: decimal = convert(as_unitless_number(elapsed_time), decimal) / tau

    # compute the padé approximant for e**-x at y = 0, 1, 2, 3, and 4. for x >= 4.5, truncate at 0 i.e. ~1.1%
    w: decimal
    if x < .5:
        w = 1.0 - (12.0*x / (x * (x + 6.0) + 12.0))                # 0
    elif x < 1.5:
        w = (x * (x - 8.0) + 19.0) / (e * (x * (x + 4.0) + 7.0))   # 1
    elif x < 2.5:
        w = (x * (x - 10.0) + 28.0) / (e2 * (x * (x + 2.0) + 4.0)) # 2
    elif x < 3.5:
        w = (x * (x - 12.0) + 39.0) / (e3 * (x * x + 3.0))         # 3
    elif x < 4.5:
        w = (x * (x - 14.0) + 52.0) / (e4 * (x * (x - 2.0) + 4.0)) # 4
    else:
        w = 0

    return w


@public
@constant
def get_next_average_price(last_average_price: decimal, last_price: decimal, elapsed_time: timedelta) -> decimal:
    w: decimal = self.get_weight(elapsed_time)
    return (w * last_average_price) + ((1.0 - w) * last_price)

@public
@constant
def get_average_price(last_price_DEV: decimal) -> decimal:
    assert self.average_price.time != 0

    if self.average_price.time != block.timestamp:
        return self.get_next_average_price(
            self.average_price.price,
            last_price_DEV,
            block.timestamp - self.average_price.time
        )
    else:
        return self.average_price.price

@public
def trade(last_price_DEV: decimal):
    # before the first trade of every block...
    if self.average_price.time != block.timestamp:
        # ...observe current price, which happens to be the price as of after the last trade of the last traded block...
        last_price: decimal = last_price_DEV

        # ...if we don't yet have an ema (i.e. this is the first trade ever), set it to the last_price...
        if self.average_price.time == 0:
            self.average_price.price = last_price
        # ...and if we do, update it appropriately...
        else:
            self.average_price.price = self.get_next_average_price(
                self.average_price.price,
                last_price,
                block.timestamp - self.average_price.time
            )

        self.average_price.time = block.timestamp
