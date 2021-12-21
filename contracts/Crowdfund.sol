//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;

contract CrowdFund{

    mapping(address => uint) public contributors;
    address public admin;
    enum State {Started, Canceled}
    uint public noOfContributors;
    uint public minContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests; 
    uint noOfRequests;

    modifier adminOnly(){
        require(msg.sender == admin, "You must be the admin!");
        _;
    }

    constructor (uint _goal, uint _deadline){
        goal = _goal;
        deadline = block.timestamp + _deadline;
        admin = msg.sender;
        minContribution = 100 wei;
    }

    modifier running (){
        require(block.timestamp <= deadline, "Deadline has passed!");
        _;
    }

    modifier notSuccessful(){
        require(block.timestamp >= deadline && raisedAmount < goal, "Crowdfunding is not successful");
        _;
    }

    function contribute() public payable running{
        require(msg.value > minContribution, "Minimum contribution not met");

        if(contributors[msg.sender] != 0){
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    receive() payable external running{
        contribute();        
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getRefund() public notSuccessful{
        require(contributors[msg.sender] > 0);
        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    function createRequest(string memory _description, uint _value, address payable _recipient) public adminOnly{
        Request storage currentRequest = requests[noOfRequests];
        noOfRequests++;
        currentRequest.description = _description;
        currentRequest.value = _value;
        currentRequest.recipient = _recipient;
        currentRequest.completed = false;
        currentRequest.noOfVoters = 0;
    }

    modifier onlyContributors(){
        require(contributors[msg.sender] != 0, "You must be a contributor!");
        _;
    }

    function voteRequest(uint noOfRequest) public onlyContributors{
        Request storage currentRequest = requests[noOfRequest];
        if(currentRequest.voters[msg.sender] == true){

        }
        else{
            currentRequest.noOfVoters++;
            currentRequest.voters[msg.sender] = true;
        }
        
    }

    function request(uint noOfRequest) public adminOnly{
        Request storage currentRequest = requests[noOfRequest];

        if(currentRequest.noOfVoters > noOfContributors/2){
            currentRequest.completed = true;
            payable(currentRequest.recipient).transfer(currentRequest.value);
        }
    }



}