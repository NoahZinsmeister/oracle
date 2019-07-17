# Exponential Moving Average Implementation - Irregular Intervals

import os
import math
import numpy as np
from numpy import random
from scipy import stats
import pandas as pd
from pandas.plotting import register_matplotlib_converters
import matplotlib.pyplot as plt

np.random.seed(123)
register_matplotlib_converters()


file_dir = os.path.dirname(os.path.realpath(__file__))

# τs of 1 hour, 1 day
τs = [3600, 86400]

# fake data parameters
μ = 10
σ2 = 1
norm = stats.norm(μ, math.sqrt(σ2))


def get_data():
    return (
        pd
        .read_csv(os.path.join(file_dir, "..", "mkr.csv"))
        .assign(timestamp=lambda x: pd.to_datetime(x["timestamp"], unit="s"))
        .groupby("timestamp").last()  # get the price after the last trade in every block
        .shift().dropna()  # and use the last block"s data for the current block
        .reset_index()
        .assign(timedelta=lambda x: (x["timestamp"] - x["timestamp"].shift()).dt.seconds)
        .assign(price_mkr=lambda x: x["eth_balance"] / x["token_balance"])
        .drop(["eth_balance", "token_balance"], axis=1)
        .assign(price_fake=lambda x: norm.rvs(size=x.shape[0]))
    )


def step(τ, mean_old, x_old, timedelta):
    """http://www.eckner.com/papers/Algorithms%20for%20Unevenly%20Spaced%20Time%20Series.pdf"""
    w = math.exp(-timedelta / τ)
    return (mean_old * w) + (x_old * (1 - w))


def main():
    data = get_data()
    x_ticks = data["timestamp"]

    for τ in τs:
        ema_mkr = [data["price_mkr"][0]]
        ema_fake = [data["price_fake"][0]]

        # loop through blocks
        for i in range(data.shape[0]):
            # skip the first observation
            if i == 0:
                continue

            ema_mkr_new = step(τ, ema_mkr[i - 1], data.iloc[i - 1]["price_mkr"], data.iloc[i]["timedelta"])
            ema_mkr = np.append(ema_mkr, [ema_mkr_new])

            ema_fake_new = step(τ, ema_fake[i - 1], data.iloc[i - 1]["price_fake"], data.iloc[i]["timedelta"])
            ema_fake = np.append(ema_fake, [ema_fake_new])

        loss_mkr = ((data["price_mkr"].shift().dropna() - ema_mkr[1:]) ** 2).mean()
        loss_fake = ((data["price_fake"].shift().dropna() - ema_fake[1:]) ** 2).mean()

        fig, (ax_mkr, ax_fake) = plt.subplots(2, 1, figsize=(24, 12), sharex=True)

        ax_mkr.plot(x_ticks, data["price_mkr"], "-o", alpha=.02, color="blue")
        ax_mkr.plot(x_ticks, ema_mkr, linestyle="--", color="red")
        ax_mkr.set_title(f"MKR (Loss: {loss_mkr:.6f})")

        ax_fake.plot(x_ticks, data["price_fake"], "-o", alpha=.02, color="blue")
        ax_fake.plot(x_ticks, ema_fake, linestyle="--", color="red")
        ax_fake.set_title(f"N({μ}, {σ2}) (Loss: {loss_fake:.6f})")

        hours = int(τ / 60 / 60)
        fig.suptitle(f"{hours}-Hour EMA", fontsize=16)
        fig.autofmt_xdate()
        plt.savefig(os.path.join(file_dir, f"ema_{hours}.png"))


main()
