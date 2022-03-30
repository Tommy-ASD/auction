// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

contract auction is Ownable {
    //holy shit this is inoptimal
    //hi if you're reading this in the future this is pretty much my first independent project
    //i can tell it's bad, but i can't tell how to improve it (yet)
    bool private _auctionIsActive;
    address private _highestBidder;
    uint256 private _auctionPayout;
    mapping(address => uint256) private _participantTotalValue;

    constructor() {
        _auctionIsActive = true;
        //total value sent on auction start is auction payout
        _auctionPayout = msg.value;
    }

    // VIEW FUNCTIONS
    function auctionIsActive() public view virtual returns (bool) {
        return _auctionIsActive;
    }

    function highestBidder() public view virtual returns (address) {
        return _highestBidder;
    }

    function auctionPayout() public view virtual returns (uint256) {
        return _auctionPayout;
    }

    function participantTotalValue(address _address)
        public
        view
        virtual
        returns (uint256)
    {
        return _participantTotalValue[_address];
    }

    //END VIEW FUNCTIONS

    function enterAuction() public payable {
        require(_auctionIsActive, "Auction is not currently active");
        //only work if new entry is higher than last highest entry
        require(
            msg.value + _participantTotalValue[msg.sender] >
                _participantTotalValue[_highestBidder],
            "Your bid is lower than the highest bid"
        );
        //add new entry to total value entered with (to know how much can be withdrawn)
        _participantTotalValue[msg.sender] += msg.value;
        //update highest bid and bidder
        _highestBidder = msg.sender;
        //add msg.sender to participants mapping
    }

    function ownerWithdraw() internal {
        //only be able to withdraw if auction isn't running
        require(!_auctionIsActive, "Cannot withdraw while auction is active");
        //cast owner as payable address
        //address(this).balance should be obvious
        payable(owner()).transfer(address(this).balance - _auctionPayout);
    }

    function startAuction() private {
        _auctionIsActive = true;
    }

    function endAuction() public onlyOwner {
        _auctionIsActive = false;
        payable(_highestBidder).transfer(_auctionPayout);
        ownerWithdraw();
        startAuction();
    }

    function increasePayout() public {
        require(
            auctionIsActive,
            "Can only increase payout while auction is active"
        );
        _auctionPayout += msg.value;
    }
}
