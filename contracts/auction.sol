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

/// @title Auction
/// @author TommyASD
/// @notice This is an auction project where people can bid on something, but they can't withdraw their bid (based off of a vSauce video I saw once)
/// @dev Not audited, use with caution. Will add support for tokens at a later time.

pragma solidity ^0.8.0;

contract auction is Ownable {
    bool private _auctionIsActive;
    address private _highestBidder;
    uint256 private _auctionPayout;
    uint256 private _totalValue;
    /// @dev Added _currentRound variable because functions are immutable
    /// @dev Storing current round makes it easier to reset how much money participants have added
    uint256 private _currentRound;
    mapping(uint256 => mapping(address => uint256))
        private _participantTotalValue;

    event startedAuction(uint256 payout, uint256 round);
    event increasedPayout(
        address increaser,
        uint256 increasedBy,
        uint256 newPayout,
        uint256 round
    );
    event newTopBidder(
        address topBidder,
        uint256 addedValue,
        uint256 topBidderTotalValue,
        uint256 round
    );
    event endedAuction(address winner, uint256 winnerTotalValue, uint256 round);
    event withdrew(address owner, uint256 amount, uint256 round);

    constructor() {
        _auctionIsActive = false;
        _auctionPayout = 0;
        _highestBidder = address(0);
        _currentRound = 0;
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

    function totalValue() public view virtual returns (uint256) {
        return _totalValue;
    }

    function participantTotalValue(address _address)
        public
        view
        virtual
        returns (uint256)
    {
        return _participantTotalValue[_currentRound][_address];
    }

    function previousParticipantTotalValue(uint256 round, address _address)
        public
        view
        virtual
        returns (uint256)
    {
        return _participantTotalValue[round][_address];
    }

    function currentRound() public view virtual returns (uint256) {
        return _currentRound;
    }

    //END VIEW FUNCTIONS

    /// @notice Only owner can start the auction, and can only start if the auction is inactive
    /// @notice The amount of money the owner sends becomes the auction payout
    function startAuction() public payable onlyOwner {
        require(!_auctionIsActive);
        _auctionPayout = msg.value;
        _auctionIsActive = true;
        emit startedAuction(msg.value, _currentRound);
    }

    /// @notice Anyone can do the function to increase the payout.
    /// @notice The amount of money sent with the transaction gets added on to the total payout
    /// @notice This can only be done if auction is active
    function increasePayout() public payable {
        require(
            _auctionIsActive,
            "Can only increase payout while auction is active"
        );
        _auctionPayout += msg.value;
        emit increasedPayout(
            msg.sender,
            msg.value,
            _auctionPayout,
            _currentRound
        );
    }

    /// @notice Can only enter if your previous amount deposited + the amount sent is greater than last highest entry
    /// @notice Can also only enter if auction is active
    function enterAuction() public payable {
        require(_auctionIsActive, "Auction is not currently active");
        require(
            msg.value + _participantTotalValue[_currentRound][msg.sender] >
                _participantTotalValue[_currentRound][_highestBidder],
            "Your bid is lower than the highest bid"
        );
        //update total value
        _totalValue += msg.value;
        //update highest bid and bidder
        _participantTotalValue[_currentRound][msg.sender] += msg.value;
        _highestBidder = msg.sender;
        emit newTopBidder(
            msg.sender,
            msg.value,
            _participantTotalValue[_currentRound][msg.sender],
            _currentRound
        );
    }

    /// @notice This function transfers the entire balance of the contract to the owner
    /// @notice This includes a possible auction payout
    /// @notice The function is only ever called after the payout is payed to highest bidder
    function ownerWithdraw() internal {
        emit withdrew(msg.sender, address(this).balance, _currentRound);
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Can't end if anyone has entered auction, can't end if auction isn't active
    /// @notice This is the only time the previous function is ever done
    /// @notice Which makes it impossible for the owner to withdraw payout

    /// @dev Variables are reset at the end of the function
    /// @dev This is to make the contract ready for the next round
    function endAuction() public onlyOwner {
        require(
            _auctionIsActive,
            "Cannot end auction unless auction is active"
        );
        require(_highestBidder != address(0), "Winner cannot be nulladdress");
        //do stuff before reset
        payable(_highestBidder).transfer(_auctionPayout);
        emit endedAuction(
            _highestBidder,
            _participantTotalValue[_currentRound][_highestBidder],
            _currentRound
        );
        ownerWithdraw();

        //reset
        _highestBidder = address(0);
        _auctionIsActive = false;
        _auctionPayout = 0;
        _totalValue = 0;
        _currentRound += 1;
    }

    /// @dev This was made to (possibly) save gas
    /// @dev Still pretty new to this, so I don't know if it helps
    function resetAuction() public payable onlyOwner {
        endAuction();
        startAuction();
    }
}
