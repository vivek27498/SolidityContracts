// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract Conditions{
    address admin;
    uint32 starttime;
    uint32 stoptime;
    mapping(address => bool) proposer;
    address[] proposers;

    mapping(address => bool) voter;
    address[] voters;

    mapping(address => bool) voted;


    modifier onlyAdmin{
        require(msg.sender==admin,"Only admin is authorised!");
        _;
    }
    modifier onlyproposers{
        require(proposer[msg.sender],"You are not authorised poposer");
        _;
    }

    modifier onlyVoters{
        require(voter[msg.sender],"You are not valid voter");
        _;
    }

    modifier onlyVotetime{
        require(uint32(block.timestamp)>starttime && uint32(block.timestamp)<stoptime,"invalid voting time");
        _;
    }
    uint32 counting; // timeafter which counting can start
    modifier countingTime{
        require(uint32(block.timestamp)>stoptime,"Voting in progress, counting can't be done");
        //require(counting<block.timestamp, "too early to start counting");
        _;
    }

}

contract EVoting is Conditions{
    /* 1. voting to be done by eligible voters
    2. who is authorized to put up a proposal
    3. a specific time window when votes can be cast
    4. when will the counting of votes be allowed?
    5. admin setup
    6. only one vote per voter
    7. no power to delete or modify the votes

    */

    constructor(uint32 _start, uint32 _stop) {
        admin = msg.sender;
        starttime = _start;
        stoptime = _stop;
    }

    bool public isOpen;
    uint256 requestId;
    mapping(uint256 => address) request;

    event Request(address indexed Voter, uint256 Requestid, uint256 time);

    function togglevoting() external onlyAdmin{
        isOpen = !isOpen;
    }

    function applyToVote() external{
        requestId++;
        request[requestId] = msg.sender;
        emit Request(msg.sender,requestId,block.timestamp);
    }

    function approveToVote(uint256 _requestId) external onlyAdmin{
        address v = request[_requestId];
        voter[v] = true;
        voters.push(v);
    }
    //unApprovetoVote -onlyAdmin, before voting starts
    //applyToPropose()
    //approveTopropose()

    struct Proposal{
        string description;
        address proposer;
        uint32 timestamp;
        uint256 voteCount;
    }
    uint8 proposalId;
    mapping(uint8 => Proposal) proposals;
    event AddProposal(string Description, address proposer, uint8 Id);

    function addProposal(string memory _description) external returns(uint8){
        proposalId++;
        proposals[proposalId] = Proposal(_description,msg.sender,uint32(block.timestamp),0);
        emit AddProposal(_description,msg.sender,proposalId);
        return proposalId;
    }

    //deleteproposal can also be added
    //viewProposal(id)
    //viewAll/propossls

    //struct Vote{
    //    uint8 proposalId;
    //    uint256 voteCount;
    //}
    mapping(uint8 => uint256) votesPolledFor;
    uint256 counter;
    event Voting(uint8 Id,uint256 Time);

    function vote(uint8 _id) external onlyVoters onlyVotetime{
        require(!voted[msg.sender],"Already voted");
        require(isOpen,"Voting closed due to some tech issue, try again later!");
        voted[msg.sender] = true;
        proposals[_id].voteCount++;
        votesPolledFor[_id]++;
        counter++;
        emit Voting(_id,block.timestamp);
    }

    function voteCounting()external view countingTime returns(uint256[] memory){
        uint256[] memory proposalCount = new uint256[](proposalId);
        uint256 index;
        for(uint8 i=1; i<=proposalId;i++){
            proposalCount[i-1] = votesPolledFor[i];
            index += votesPolledFor[i];
        }
        require(index == counter, "Error in counting");
        return proposalCount;
    }


    //addVoter() - onlyAdmin
    //addProposers - onlyAdmin
    //addProposal = onlyProposers
    //addVote - onlyvoters, onlyVoteTime
}