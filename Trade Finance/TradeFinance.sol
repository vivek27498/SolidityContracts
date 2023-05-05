//SPDX-License-Identifier:MIT
pragma solidity <=0.8.17;
import "./erc20.sol";

contract Trading{

    enum tradingState{
        idle, deposited, funded, transit, completed
    }

    struct tradeParams{
        tradingState state;
        uint256 transAmount;
        address importer;
        address treasury;
        address exporter;
        address logistics;
    }

    mapping (uint256 => tradeParams) tradeTable;
    address platformOwner;
    TradeToken token;


    event StateChange(uint256 tradeId, tradingState state);

    constructor (address payable tokenAddress) public{
        platformOwner = msg.sender;
        token = TradeToken(tokenAddress);
    }

    modifier onlyBy(address _account){
        require(msg.sender == _account);
        _;
    }

    function getTradeState(uint256 tradeId) public view returns(tradingState){
        return tradeTable[tradeId].state;
    }

    function getTradeAmount(uint256 tradeId) public view returns(uint256){
        return tradeTable[tradeId].transAmount;
    }

    function initTrade(uint256 tradeId, uint256 transAmount, address _exporter) public{
        require(tradeTable[tradeId].state == tradingState(idle));
        require(token.transferFrom(msg.sender, address(this), tradeTable[tradeId].transAmount / 10));
        tradeTable[tradeId] = tradeParams(
            tradingState.deposited,
            transAmount, msg.sender, address(0), _exporter, address(0)
        );

        return;

    }

    function fundTrade(uint256 tradeId, address logistics) public{
        require(tradeTable[tradeId].state == tradingState(deposited));
        require(token.transferFrom(msg.sender, address(this), tradeTable[tradeId].transAmount - tradeTable[tradeId].transAmount / 10));
        tradeTable[tradeId].treasury = msg.sender;
        tradeTable[tradeId].logistics = logistics;
        tradeTable[tradeId].state = tradingState.funded;
    }

    function confirmReceipt(uint256 tradeId) public{
        require(tradeTable[tradeId].state == tradingState.funded);
        require(tradeTable[tradeId].logistics == msg.sender);
        require(token.transfer(tradeTable[tradeId].exporter, tradeTable[tradeId].transAmount));
        tradeTable[tradeId].state = tradingState.transit;
        emit StateChange(tradeId, tradeTable[tradeId].state);
    }

    function finalPayment(uint256 tradeId) public{
        require(tradeTable[tradeId].state == tradingState.transit);
        require(token.transferFrom(msg.sender, tradeTable[tradeId].treasury, tradeTable[tradeId].transAmount));
        tradeTable[tradeId].state = tradingState.completed;
        emit StateChange(tradeId, tradeTable[tradeId].state);
    }


}