from scripts.helpfulScripts import getAccount
from brownie import auction, accounts, config, network
from web3 import Web3


def deploy():
    account = getAccount()
    Auction = auction.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    return Auction, account


def start(Auction, account, amount):
    tx = Auction.startAuction({"from": account, "amount": amount})
    tx.wait(1)


def increasePayout(Auction, account, amount):
    tx = Auction.increasePayout({"from": account, "amount": amount})
    tx.wait(1)


def enterAuction(Auction, account, amount):
    tx = Auction.enterAuction({"from": account, "amount": amount})
    tx.wait(1)


def endAuction(Auction, account):
    tx = Auction.endAuction({"from": account})
    tx.wait(1)
    txFee = tx.gas_price * tx.gas_used
    return txFee


def main():
    deploy()
