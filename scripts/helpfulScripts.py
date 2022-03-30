from brownie import (
    network,
    config,
    accounts,
)

FORKED_LOCAL_ENVIRONMENTS = ["mainnet-fork", "mainnet-fork-dev", "mainnet-fork-dev2"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "Ganache-local"]
DECIMALS = 18
STARTING_PRICE = 2000 * 10**18


def getAccount(index=None, id=None):
    # if local network, use local account
    if index:
        # load from local ganache
        return accounts[index]
    if id:
        # brownie accounts list in terminal to see account IDs
        return accounts.load(id)
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):
        return accounts[0]

    return accounts.add(config["wallets"]["from_key"])
