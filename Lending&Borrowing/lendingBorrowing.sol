// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract LendingBorrowingProtocol {
    address public owner;
    mapping (address => uint) public balances;
    mapping (address => uint) public stakedBalances;
    mapping (address => mapping (address => uint)) public allowances;
    uint public totalStaked;
    IERC20 public token;
    uint public collateralFactor = 130; // 30% more collateral required
    uint public rewardRate = 100; // 10% annual reward rate

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    function deposit(uint amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;
        totalStaked += amount;
    }

    function withdraw(uint amount) external {
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        uint reward = calculateReward(msg.sender);
        stakedBalances[msg.sender] -= amount;
        totalStaked -= amount;
        token.transfer(msg.sender, amount);
        token.transfer(msg.sender, reward);
    }

    function stake(uint amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Staking failed");
        stakedBalances[msg.sender] += amount;
        totalStaked += amount;
    }

    function unstake(uint amount) external {
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        uint reward = calculateReward(msg.sender);
        stakedBalances[msg.sender] -= amount;
        totalStaked -= amount;
        token.transfer(msg.sender, amount);
        token.transfer(msg.sender, reward);
    }

    function borrow(uint amount, address collateral) external {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(collateral != address(0), "Invalid collateral address");
        uint collateralAmount = (amount * collateralFactor) / 100;
        require(IERC20(collateral).balanceOf(msg.sender) >= collateralAmount, "Insufficient collateral");
        IERC20(collateral).transferFrom(msg.sender, address(this), collateralAmount);
        balances[msg.sender] += amount;
        token.transfer(msg.sender, amount);
    }

    function repay(uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient borrowed amount");
        balances[msg.sender] -= amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function calculateReward(address account) public view returns (uint) {
        uint reward = ((stakedBalances[account] * rewardRate) / 10000) * (block.timestamp - block.timestamp) / 1 days;
        return reward;
    }

    function setRewardRate(uint rate) external {
        require(msg.sender == owner, "Not authorized");
        rewardRate = rate;
    }

    function setCollateralFactor(uint factor) external {
        require(msg.sender == owner, "Not authorized");
        collateralFactor = factor;
    }

    function setToken(address _token) external {
        require(msg.sender == owner, "Not authorized");
    token = IERC20(_token);
}

function approve(address spender, uint amount) external {
    require(spender != address(0), "Invalid spender address");
    allowances[msg.sender][spender] = amount;
    token.approve(spender, amount);
}

function transfer(address recipient, uint amount) external {
    require(recipient != address(0), "Invalid recipient address");
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;
    balances[recipient] += amount;
}

function transferFrom(address sender, address recipient, uint amount) external {
    require(recipient != address(0), "Invalid recipient address");
    require(balances[sender] >= amount, "Insufficient balance");
    require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");
    allowances[sender][msg.sender] -= amount;
    balances[sender] -= amount;
    balances[recipient] += amount;
}