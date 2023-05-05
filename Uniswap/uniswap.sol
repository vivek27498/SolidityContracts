// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

interface IERC20 {
    function totalSupply() external view returns (uint256) ;    
    function balanceOf(address _owner) external view returns (uint256 balance);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract ERC20 is IERC20{

    string nameToken ;
    string symbolToken ;
    uint8 decimal ;
    uint256 tSupply ;

    constructor (string memory _name, string memory _symbol,
                    uint8 _decimal) {
        nameToken = _name;
        symbolToken = _symbol;
        decimal = _decimal;
        //_mint(msg.sender,_tSupply);
        // tSupply = _tSupply;
        // balances[msg.sender] = _tSupply;
    }
    function name() public view returns (string memory){
        return nameToken;
    }

    function symbol() public view returns (string memory) {
        return symbolToken;
    }

    function decimals() public view returns (uint8){
        return decimal;
    }

    function totalSupply() public view returns (uint256) {
        return tSupply;
    }
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance){
        // balance = balances[_owner];
        return balances[_owner];
    }
    //event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>= _value, "Error ::: Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender,_to,_value);

        return true;
    }
    // Run by spender
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>= _value, "Error ::: Insufficient balance");
        require(allowed[_from][msg.sender]>= _value, "Error : Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from,_to,_value);
        return true;
    }
    mapping (address => mapping(address => uint256)) allowed;
    // owner - msg.sender
    //event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseAllowance(address _spender, uint256 _value) public {
        allowed[msg.sender][_spender] += _value;
    }

    function decreaseAllowance(address _spender, uint256 _value) public {
        require(allowed[msg.sender][_spender]>=_value, "Error : Insufficient allownce to decrease");
        allowed[msg.sender][_spender] -= _value;
    }

    // Increase or Decrease total supply.

    function _mint(address _to, uint256 _qty) public {
        balances[_to]+= _qty;
        tSupply += _qty;
        emit Transfer(address(0),_to,_qty);
    }

    function _burn(uint256 _qty) public {
        require(balances[msg.sender]>=_qty,"Error: Not enough token to burn" );
        balances[msg.sender] -= _qty;
        tSupply -= _qty;
        emit Transfer(msg.sender, address(0),_qty);
    }

    /*One manager can give approval to multiple executives. 
    A particular exective can have approval from multiple managers.
    */
}

contract MUToken is ERC20 {

    constructor() ERC20("MUToken","MU",0){
        _mint(msg.sender,1000);
                    }

    // some code here

}
contract Exchange is ERC20{
    IERC20 token;

    constructor(IERC20 _token) ERC20("LPToken_MU","LPMU",0){
        token = _token;
    }

    function addLiquidity(uint256 _tokenAmount) public payable{
        if(getReserve()==0){
            token.transferFrom(msg.sender,address(this),_tokenAmount);
            uint256 liquidity = address(this).balance;
            _mint(msg.sender,liquidity);
        }else{
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = msg.value *tokenReserve/ethReserve;
            require(_tokenAmount >= tokenAmount, "Insufficient amount of tokens");
            token.transferFrom(msg.sender,address(this),tokenAmount);
            uint256 liquidity = msg.value * totalSupply()/ethReserve;
            _mint(msg.sender,liquidity);
        }
    }

    function getReserve() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getPrice(uint256 inputReserve, uint256 outputReserve) public pure returns(uint256){
        return inputReserve*1000/outputReserve;
    }
    /*
    input reserve = x
    input amount = ^x
    output reserve = y
    output amount = ^y
    xy = k
    (x+^x)(y-^y) = k
    xy - x^y +y^x - ^x^y = xy
    - ^y
    ^y = y^x/(x+^x)


    */

    function getAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) internal pure returns(uint256){
        uint256 inputAmountWithFee = inputAmount *99;
        uint256 numerator = outputReserve*inputAmountWithFee;
        uint256 denominator = (inputReserve*100)+inputAmountWithFee;
        return numerator/denominator;
        //return (outputReserve*inputAmount)/(inputAmount+inputReserve);
    }                                                                            

    function getTokenAmount(uint256 _ethSold) public view returns(uint256){
        uint256 tokenReserve = getReserve();
        return getAmount(_ethSold, address(this).balance,tokenReserve);
    }

    function getEtherAmount(uint256 _tokenSold) public view returns(uint256){
        uint256 tokenReserve = getReserve();
        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    //sandwich attack => before my transaction someone does transaction to increase price and after my transaction
    // is completed another transaction takes place which sells the token at high price gaining some profit

    function ethtoTokenSwap(uint256 _minToken) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokenBought = getAmount(msg.value,address(this).balance-msg.value, tokenReserve);

        require(tokenBought >= _minToken, "Insufficient token amount!!!");
        token.transfer(msg.sender,tokenBought);
    }

    function tokebToEthSwap(uint256 _tokenSold,uint256 _mineth) public{
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve,address(this).balance);
        require(ethBought >=_mineth, "Too few ethers");

        token.transferFrom(msg.sender,address(this),_tokenSold);
        payable(msg.sender).transfer(ethBought);
    }

    function removeLiquidity(uint256 _amount) public returns(uint256,uint256){
        uint256 ethAmount = address(this).balance * _amount /totalSupply();
        uint256 tokenAmount = getReserve()*_amount / totalSupply();

        _burn(_amount);
        payable(msg.sender).transfer(ethAmount);
        token.transfer(msg.sender, tokenAmount);
        return (ethAmount,tokenAmount);
    }

}

contract Factory{
    mapping(address =>address) tokenToExchange;

    function createExchange(address _tokenAddress) public returns(address){
        require(_tokenAddress != address(0), "Address not valid!");
        require(tokenToExchange[_tokenAddress] == address(0),"Exchange already exists");

        Exchange exchange = new Exchange(IERC20(_tokenAddress));
        tokenToExchange[_tokenAddress] = address(exchange);

        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view returns(address){
        return tokenToExchange[_tokenAddress];
    }
}