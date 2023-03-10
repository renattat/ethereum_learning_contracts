// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{
    mapping(address => uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint public minimumContribution;
    uint public deadline; // timestamp
    uint public goal;
    uint public raisedAmount;
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping (address => bool) voters;
    }
    mapping (uint => Request) public requests;
    uint public numRequests;

    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline; // _deadline is in sec
        minimumContribution = 100 wei;
        admin = msg.sender;
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);


    function contribute() public payable{
        require(block.timestamp < deadline, "Deadline has passed!");
        require(msg.value >= minimumContribution, "Minimum Contribution not met!");
        
        if(contributors[msg.sender] == 0) { // check if the address sends first time ether to the contracts
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;

        emit ContributeEvent(msg.sender, msg.value);

    }

    receive() payable external{
        contribute();
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount<goal);
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        contributors[msg.sender] = 0;
        recipient.transfer(value);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function createRquest(string memory _description, address payable _recipient, uint _value) public onlyAdmin{
        Request storage newRequest = requests[numRequests];
        // if you don't specify data location or if you specified to memory
        // You will get an error. Becouse a struct contains a nested mapping 
        // and must be declared in storage.
        numRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;

        emit CreateRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "You must be a contributor to vote");
        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.voters[msg.sender] == false, "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyAdmin{ 
        require (raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors / 2); // 50% voted for this request

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}
