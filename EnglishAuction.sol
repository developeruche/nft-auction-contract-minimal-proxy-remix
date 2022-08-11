pragma solidity 0.8.10;


// NOTE: In this contract the currency used to bid is ethereum and the funds would be taken from you want to bid and would be returned if you lose the bid


/// @dev This is an ERC721 interface (this would help us interact with an ERC721 token passed into the auction contract)
interface IERC721 {
    function transfer(address, uint) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

/// @title This is an auction contract for NFTs
/// @author developeruche
contract Auction {
    // Declaration of some event that would be used by the frontend application
    event Start();
    event End(address highestBidder, uint highestBid);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);

    // Declaration of constants and varibles
    address payable public seller;
    bool public started;
    bool public ended;
    uint public endAt;
    IERC721 public nft;
    uint public nftId;
    uint public highestBid;
    address public highestBidder;
    mapping(address => uint) public bids;


    // Declaration of constants
    uint256 constant BID_DURATION = 2 days;


    constructor () {
        seller = payable(msg.sender);
    }


    // MODIFIERS


    /// @dev This modifier would make sure that the next bid is higher than the current highest bid and also if a user has been out bidded and want to top up, the modifer would sum up the he/her previous bid and the current to be higher than the current highest bid
    // modifier sandwich() {
    //     // 1. Making sure the sender is not the current highest bidder
    //     require(msg.sender != highestBidder, "You are the highest bidder");
    //     if(bids[msg.sender] == 0) {
    //         // This means the address has not bidded or have been out bidded
    //     }
    // }


    // CUSTOM ERRORS


    /// Bid has already started
    error AlreadyStarted();

    /// You are not the seller
    error NotSeller();

    /// Bid has not started
    error NotStarted();

    /// Bid has ended
    error HasEnded();

    /// You can't bid if you are the 
    error YouAreTheHighestBidder();

    /// Your bid is lower then the highest bid
    error BidLowerThanHighestBid();

    

    function start(IERC721 _nft, uint _nftId, uint startingBid) external {
        if(started) {
            revert AlreadyStarted();
        }

        if(msg.sender != seller) {
            revert NotSeller();
        }
        
        highestBid = startingBid;

        nft = _nft;
        nftId = _nftId;


        // @dev transfering the ownership of the nft to the contract (so the bid can holder), fisrt from the frontend, the user must give the contract the authorization to spend NFTs from he/her wallet (NOTE: if this is not successful, it would be reverted)
        nft.transferFrom(msg.sender, address(this), nftId);

        started = true;
        // Bidding time is two days (after two days, the bid would not be possible)
        endAt = block.timestamp + BID_DURATION;
    }

    function bid() external payable {
        if(!started) {
            revert NotStarted();
        }

        if (block.timestamp > endAt) {
            revert HasEnded();
        }

        // This would make sure that the next bid is higher than the current highest bid and also if a user has been out bidded and want to top up, the modifer would sum up the he/her previous bid and the current to be higher than the current highest bid
        // 1. Making sure the sender is not the current highest bidder
        if(msg.sender == highestBidder) {
            revert YouAreTheHighestBidder();
        }

        if(bids[msg.sender] == 0) {
            // This means the address has not bidded or have been out bidded
            if(msg.value < highestBid) {
                revert BidLowerThanHighestBid();
            }

            if (highestBidder != address(0)) {
                // The essence of this logic is this, if you are the current highest bidder, you cannot withdraw. but once you have been out bidded then you can withdraw (and this bid function does not support top up, if the user want bid again he would have to withdraw then bid again: the frontend would have to make sure of that so the bidder dont lose money)
                bids[highestBidder] += highestBid;
            }

            highestBid = msg.value;
            highestBidder = msg.sender;

            emit Bid(highestBidder, highestBid);
        }else {
            // This means the user has been out bidded and has balance of ether in the auction vault
            require(msg.value + bids[msg.sender] > highestBid, "Ether needs to ne higher that the highest bid");

            highestBid = msg.value + bids[msg.sender];
            highestBidder = msg.sender;

            emit Bid(highestBidder, highestBid);
        }
        


    }
    /// @dev a user can only withdraw is the user is not the highest bidder
    function withdraw() external payable {
        
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool sent, bytes memory data) = payable(msg.sender).call{value: bal}("");
        require(sent, "Could not withdraw");

        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "You need to start first!");
        require(block.timestamp >= endAt, "Auction is still ongoing!");
        require(!ended, "Auction already ended!");

        if (highestBidder != address(0)) {
            nft.transfer(highestBidder, nftId);
            (bool sent, bytes memory data) = seller.call{value: highestBid}("");
            require(sent, "Could not pay seller!");
        } else {
            nft.transfer(seller, nftId);
        }

        ended = true;
        emit End(highestBidder, highestBid);
    }
}