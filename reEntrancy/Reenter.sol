//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Reenter is ReentrancyGuard{

    mapping(address=>uint256) balances;
    // bool lock = false;

    function deposit() public payable {
        balances[msg.sender] += msg.value; 
    }

    function withdraw() public nonReentrant{
        // require(lock==false,"cannot re enter");
        require(balances[msg.sender]>0,"No amount in senders wallet balance");
        // lock = true;
        (bool sent,)=(msg.sender).call{value:balances[msg.sender]}("");
        require(sent,"transaction failed");
        balances[msg.sender] = 0;
        // lock = false;
    }
    
}
