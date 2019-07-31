import os
import pytest

from web3 import Web3
import eth_tester
from eth_tester import EthereumTester, PyEVMBackend
from vyper import compiler

from .constants import TAU

setattr(eth_tester.backends.pyevm.main, 'GENESIS_GAS_LIMIT', 10**9)
setattr(eth_tester.backends.pyevm.main, 'GENESIS_DIFFICULTY', 1)


def create_contract(w3, path, *args, **kwargs):
    wd = os.path.dirname(os.path.realpath(__file__))
    with open(os.path.join(wd, os.pardir, path)) as f:
        source = f.read()
    out = compiler.compile_code(source, ['abi', 'bytecode'], interface_codes=None)
    return w3.eth.contract(abi=out['abi'], bytecode=out['bytecode'])


@pytest.fixture
def tester():
    return EthereumTester(backend=PyEVMBackend())


@pytest.fixture
def w3(tester):
    w3 = Web3(Web3.EthereumTesterProvider(tester))
    w3.eth.setGasPriceStrategy(lambda web3, params: 0)  # pylint: disable=no-member
    w3.eth.defaultAccount = w3.eth.accounts[0]  # pylint: disable=no-member
    return w3


@pytest.fixture
def EMA(w3):
    deploy = create_contract(w3, 'contracts/ema.vy')
    tx_hash = deploy.constructor(TAU, 1, 1).transact()
    tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
    return w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=deploy.abi
    )


@pytest.fixture
def LIQUIDITY(w3):
    deploy = create_contract(w3, 'contracts/liquidity.vy')
    tx_hash = deploy.constructor(1, 1).transact()
    tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
    return w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=deploy.abi
    )


@pytest.fixture
def TWA_EXTERNAL(w3, LIQUIDITY):
    deploy = create_contract(w3, 'contracts/twa_external.vy')
    tx_hash = deploy.constructor(LIQUIDITY.address, 1, 1, TAU).transact()
    tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
    return w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=deploy.abi
    )
