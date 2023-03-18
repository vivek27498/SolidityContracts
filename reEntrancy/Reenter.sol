//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

contract Reenter{

    mapping(address=>uint256) balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value; 
    }

    function withdraw() public{

        require(balances[msg.sender]>0,"No amount in senders wallet balance");
        (bool sent,)=(msg.sender).call{value:balances[msg.sender]}("");
        require(sent,"transaction failed");
        balances[msg.sender] = 0;
    }
    
}