from brownie import auction, accounts


def deploy():
    Auction = auction.deploy({"from": accounts[0]})


def main():
    deploy()
