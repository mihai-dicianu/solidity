//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract Auction{

    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    mapping(address => uint) public bids;
    uint bidIncrement;
    uint public highestBindingBid;
    address payable public highestBidder;

    constructor() {
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier notOwner(){
        require(owner != msg.sender, "you are the owner");
        _;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "you are not the owner");
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    function min(uint a, uint b) pure internal returns (uint){
        if(a <= b){
            return a;
        }
        else{
            return b;
        }
    }

    function placeBid() public payable notOwner afterStart beforeEnd{
        require(auctionState == State.Running);
        require(msg.value > 100); 

        uint currentBid = bids[msg.sender] + msg.value;
        
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;
        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }
        else{
            if(highestBidder != payable(0x0)){
                highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            }
            else{
                highestBindingBid = currentBid;
            }
            highestBidder = payable(msg.sender);

        }
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }

    function finalizeAuction() public{
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] != 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled){
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }
        else{
            if(msg.sender == owner){
                recipient = owner;
                value = highestBindingBid;
            }
            else{
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[msg.sender] - highestBindingBid;
                }
                else{
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        recipient.transfer(value);

    }

}