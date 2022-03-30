from scripts.deploy import deploy, start, increasePayout, enterAuction, endAuction
from brownie import accounts, exceptions
import pytest

amount = 1000000000000000000
enterAmount = amount


def test_canChooseOwner():

    Auction, account = deploy()
    # make sure constructor went well
    assert Auction.auctionIsActive() == False

    # make sure owner is correctly chosen
    assert Auction.owner() == account
    # make sure can't enter auction
    with pytest.raises(exceptions.VirtualMachineError):
        enterAuction(Auction, account, enterAmount)
    with pytest.raises(exceptions.VirtualMachineError):
        endAuction(Auction, account)

    return Auction, account


def test_canStartAuction():
    Auction, account = test_canChooseOwner()

    with pytest.raises(exceptions.VirtualMachineError):
        start(Auction, accounts[1], amount)
    start(Auction, account, amount)
    with pytest.raises(exceptions.VirtualMachineError):
        start(Auction, account, amount)

    # make sure payout was recieved
    assert Auction.auctionPayout() == amount

    # make sure auction started
    assert Auction.auctionIsActive() == True

    return Auction, account


def test_canEnterAuction():
    Auction, account = test_canStartAuction()

    enterAuction(Auction, account, enterAmount)

    enterAuction(Auction, accounts[1], enterAmount + 1)

    assert Auction.highestBidder() == accounts[1]
    assert Auction.participantTotalValue(account) == enterAmount
    assert Auction.participantTotalValue(accounts[1]) == enterAmount + 1
    # make sure total value works
    assert Auction.totalValue() == Auction.participantTotalValue(
        accounts[1]
    ) + Auction.participantTotalValue(account)

    # also making sure can increase payout
    increasePayout(Auction, account, enterAmount)
    increasePayout(Auction, accounts[1], enterAmount)
    assert Auction.auctionPayout() == amount + enterAmount + enterAmount

    # just adding a bit of extra tests to make triple sure everything works right
    with pytest.raises(exceptions.VirtualMachineError):
        enterAuction(Auction, account, 1)
    enterAuction(Auction, account, 2)
    with pytest.raises(exceptions.VirtualMachineError):
        enterAuction(Auction, accounts[1], 1)
    enterAuction(Auction, accounts[1], 2)

    return Auction, account


def test_canEndAuction():
    Auction, account = test_canEnterAuction()
    winnerBalance = accounts[1].balance()
    payout = Auction.auctionPayout()
    hostBalance = account.balance()
    value = Auction.totalValue()
    with pytest.raises(exceptions.VirtualMachineError):
        endAuction(Auction, accounts[1])
    txFee = endAuction(Auction, account)
    with pytest.raises(exceptions.VirtualMachineError):
        endAuction(Auction, account)
    assert accounts[1].balance() == winnerBalance + payout
    assert account.balance() == hostBalance + value - txFee
