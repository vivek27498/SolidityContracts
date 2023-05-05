// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//DAO Contracts:
//--> Collects Investors money(ether) and allocates shares.
//--> Keep track of investors contributions with shares.
//--> Allow investors to transfer shares.
//--> Allow investment proposals to be created and voted
//--> Execute successful investment proposals (i.e send money)

contract DAO {

    struct Proposal {
        uint id;
        string name;
        uint amount;
        address payable recipient;
        uint votes;
        uint end;
        bool executed;
    }

    mapping(address => bool) public investors;
    mapping(address => uint) public shares;
    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => bool)) public votes;

    uint public totalShares;
    uint public availableFunds;
    uint public contributionEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public admin;

    constructor(
        uint contributionTime,
        uint _voteTime,
        uint _quorum 
    ) {
        require(_quorum > 0 && _quorum < 100, "Quorum must be between 1 - 100");
        contributionEnd = block.timestamp + contributionTime;
        voteTime = _voteTime;
        quorum = _quorum;
        admin = msg.sender;
    }


    function contribute() payable external {
        require(block.timestamp < contributionEnd, "Cannot contribute after contribution ends!");
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
    }

    function transferShare(uint amount, address to) external {
        require(shares[msg.sender] >= amount, "Not enough shares!");
        shares[msg.sender] -= amount;
        shares[to] += amount;
        investors[to] = true;
    }


    function redeemShare(uint amount) external {
        require(shares[msg.sender] >= amount, "Not Enough shares!");
        require(availableFunds >= amount, "Not enough available funds");
        shares[msg.sender] -= amount;
        availableFunds -= amount;
        payable(msg.sender).transfer(amount);
    }

    function createProposal(
        string memory name,
        uint amount,
        address payable recipient
    ) public onlyInvestors() {
        require(availableFunds >= amount, "Amount too high!");
        proposals[nextProposalId] = Proposal(
            nextProposalId,
            name,
            amount,
            recipient,
            0,
            block.timestamp + voteTime,
            false
        );
        availableFunds -= amount;
        nextProposalId++;
    }


    function vote(uint proposalId) external onlyInvestors() {


        Proposal storage proposal = proposals[proposalId];
        require(votes[msg.sender][proposalId] == false, "Investor can only vote once for a proposal");
        require(block.timestamp < proposal.end, "Can only vote until proposal end date!");
        votes[msg.sender][proposalId] = true;
        proposal.votes += shares[msg.sender];
    }

    function executeProposal(uint proposalId) external onlyAdmin() {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.end, "Cannot execute proposal before end date");
        require(proposal.executed == false, "Cannot execute proposal already executed!");
        require((proposal.votes / totalShares) * 100 >= quorum, "Cannot execute proposal with less votes");
        _transferEther(proposal.amount, proposal.recipient);
    }

    
    function _transferEther(uint amount, address payable to) internal {
        require(amount <= availableFunds, "Not enough available funds!");
        availableFunds -= amount;
        to.transfer(amount);
    }


    modifier onlyInvestors() {
        require(investors[msg.sender] == true, "Only Investors!");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin!");
        _;
    }


}