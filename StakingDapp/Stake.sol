pragma solidity ^0.6.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Stake is Ownable {
    
    
    IERC20 public tokenContract;
    
    using SafeMath for uint256;
    
    bool isContractOpen;
    uint256 deployTimestamp;
    
    struct User {
        address userAddress;
        uint256 referralBalance;
        bool    isPrivateInvestor;
    }
    
    struct UserStake {
        address userAddress;
        uint256 amount;
        uint256 startTimeStamp;
        uint256 lockTime; // 12 months or 24 months in seconds;
        uint8 lockChoice;
        uint256 redemptionAllowedAfter;
        uint256 lastRewardTimeStamp;
        uint256 interestClaimed;
        address refereeAddress;
        bool    stakeOpen;
    }
    
    mapping (uint8=>uint256) lockTimes;
    mapping (address=>User) usersList;
    mapping (uint256=>UserStake) stakesList;
    mapping (address => uint256[]) userStakes;
    mapping (uint8=>uint256) interestRates;
    mapping (address=>uint256) userTotalStakeBalance;

    
    uint256 stakeCount;
    
    uint256 public totalTokensStaked;
    
    uint256 thrityDaysInSeconds;
    uint256 threeYearsInSeconds;
    uint256 thresHoldToMaintain;
    uint256 minStakeAmount;
    uint256 maxStakeAmount;
    
    bool emergencyWithdrwalEnabled;
    
    event InvestorListUpdated(address investorAddress,bool updateType);
    event ReferralClaimed(address indexed userAddress,uint256 amount);
    event ReferralAwarded(address indexed userAddress,uint256 amount);
    event RewardsClaimed(address indexed userAddress,uint256 amount);
    event Unstaked(address indexed userAddress,uint256 stakeId,uint256 amount);
    event StakeRedeemed(address indexed userAddress,uint256 stakeId,uint256 amount);
    event ContractStatusChanged(bool status,address indexed updatedBy);
    constructor(address _tokenContractAddress) public{
        
        tokenContract = IERC20(_tokenContractAddress);
        
        lockTimes[0] = 3600; //need to replace with correct values later;
        lockTimes[1] = 7200;
        lockTimes[2] = 14400;
        
        interestRates[0] = 2;
        interestRates[1] = 3;
        interestRates[2] = 4;
        
        thrityDaysInSeconds =300;
        threeYearsInSeconds = 10000;
        thresHoldToMaintain = 4000000;
        minStakeAmount =0;
        maxStakeAmount = 4000000*(1 ether/1 wei);
        isContractOpen = true;
        deployTimestamp = now;
        
        emergencyWithdrwalEnabled = false;
        
    }
    
    
    function updateContractStatus(bool _contractStatus) public onlyOwner{
        isContractOpen = _contractStatus;
        emit ContractStatusChanged(_contractStatus,msg.sender);
    }
    
    
    function enableEmergencyWithdrawl() public onlyOwner {
        emergencyWithdrwalEnabled = true;
    }
    
    /**
     * @dev updates a particular address as investor or not
     * 
     * Emits an {InvestorListUpdated} event indicating the update.
     *
     * Requirements:
     *
     * - `sender` must be admin.
     */
    
    function updateInvestorStatus(address _investorAddress,bool updateType) public onlyOwner {
        
        if(usersList[_investorAddress].userAddress == address(0)){
            usersList[_investorAddress] = User(_investorAddress,0,true);
        }
        usersList[_investorAddress].isPrivateInvestor = updateType;
        
        emit InvestorListUpdated(_investorAddress,updateType);
    }
    
    
    /**
     * @dev Transfers the referral balance amount to user
     * 
     * Emits an {ReferralClaimed} event indicating the update.
     *
     * Requirements:
     *
     * - `sender` must have referralBalance of more than 0.
     */
    function claimReferral() public {
        
        require(usersList[msg.sender].referralBalance > 0,'No referral balance');
        require(transferFunds(msg.sender,usersList[msg.sender].referralBalance));
        
        usersList[msg.sender].referralBalance = 0;
        
        emit ReferralClaimed(msg.sender,usersList[msg.sender].referralBalance);
    }
    
    
    function createStake(uint256 amount,uint8 lockChoice,address refereeAddress) public returns(uint256 stakeId){
        
        require(isContractOpen,'Staking is closed,please contact support');
        require(amount>minStakeAmount);
        require(amount<maxStakeAmount);
        
        if(usersList[msg.sender].userAddress == address(0)){
            usersList[msg.sender] = User(msg.sender,0,false);
        }
        
        require(tokenContract.transferFrom(msg.sender,address(this),amount),'Token tranfer to contract not completed');
        stakesList[stakeCount++] = UserStake(msg.sender,amount,now,lockTimes[lockChoice],lockChoice,now+lockTimes[lockChoice],now,0,refereeAddress,true);
        userStakes[msg.sender].push(stakeCount-1);
        userTotalStakeBalance[msg.sender] = userTotalStakeBalance[msg.sender].add(amount);
        totalTokensStaked = totalTokensStaked.add(amount);
        
        if(msg.sender != refereeAddress){
            awardReferral(refereeAddress,(amount*10)/100);
        }
        return stakeCount-1;
    }
    
    function unStake(uint256 _stakeId) public returns (bool){
        
        require(stakesList[_stakeId].stakeOpen);
        require(!usersList[msg.sender].isPrivateInvestor);
        require(stakesList[_stakeId].userAddress == msg.sender);
        
        require(awardRewards(_stakeId));
        
        stakesList[_stakeId].stakeOpen = false;
        stakesList[_stakeId].lockTime = now;
        stakesList[_stakeId].redemptionAllowedAfter = stakesList[_stakeId].redemptionAllowedAfter.getMin(now +thrityDaysInSeconds);
        userTotalStakeBalance[msg.sender] = userTotalStakeBalance[msg.sender].sub(stakesList[_stakeId].amount);
        totalTokensStaked = totalTokensStaked.sub(stakesList[_stakeId].amount);
        emit Unstaked(stakesList[_stakeId].userAddress,_stakeId,stakesList[_stakeId].amount);
    }
    
    
    function redeem(uint256 _stakeId) public returns (bool){
        
        require(stakesList[_stakeId].userAddress == msg.sender);
    
        require(now>stakesList[_stakeId].redemptionAllowedAfter);
        
        if(stakesList[_stakeId].stakeOpen){
            require(awardRewards(_stakeId));
            userTotalStakeBalance[msg.sender] = userTotalStakeBalance[msg.sender].sub(stakesList[_stakeId].amount);
            totalTokensStaked = totalTokensStaked.sub(stakesList[_stakeId].amount);

        }
        
        stakesList[_stakeId].stakeOpen = false;
        
        require(transferFunds(stakesList[_stakeId].userAddress,stakesList[_stakeId].amount));
        
        emit StakeRedeemed(stakesList[_stakeId].userAddress,_stakeId,stakesList[_stakeId].amount);
    }
    
    function claimRewards(uint256 _stakeId) public returns (bool){
        require(stakesList[_stakeId].stakeOpen);
        require(stakesList[_stakeId].userAddress == msg.sender);
        require(now >stakesList[_stakeId].lastRewardTimeStamp+thrityDaysInSeconds);
        require(awardRewards(_stakeId));

    }
    
    
    function userDetails(address _userAddress) public view returns (uint256[] memory,uint256,bool,uint256){
        return(userStakes[_userAddress],usersList[_userAddress].referralBalance,usersList[_userAddress].isPrivateInvestor,userTotalStakeBalance[_userAddress]);   
    }
    
    function getStakeDetails(uint256 _stakeId) public view returns(address userAddress,uint256 amount,uint256 startTimeStamp,uint256 lockChoice,uint256 lockTime,uint256 redemptionAllowedAfter,uint256 lastRewardTimeStamp,uint256 interestClaimed,address refereeAddress,bool stakeOpen){
        UserStake memory temp = stakesList[_stakeId];
        
        return (temp.userAddress,temp.amount,temp.startTimeStamp,temp.lockChoice,temp.lockTime,temp.redemptionAllowedAfter,temp.lastRewardTimeStamp,temp.interestClaimed,temp.refereeAddress,temp.stakeOpen);
    }
    
    
    function getPendingInterestDetails(uint256 _stakeId) public view returns(uint256 amount){
        
        UserStake memory temp = stakesList[_stakeId];
        //require(temp.lastRewardTimeStamp<temp.redemptionAllowedAfter);
        uint256 monthDiff;
        if(now>stakesList[_stakeId].redemptionAllowedAfter){
            monthDiff = (now-stakesList[_stakeId].redemptionAllowedAfter)/thrityDaysInSeconds;   
        }
        uint256 interesMonths = (now-temp.lastRewardTimeStamp)/thrityDaysInSeconds-monthDiff;
        
        if(interesMonths>0){
            return (temp.amount*interesMonths*interestRates[temp.lockChoice])/100;
        }
        return 0;
        
    }
    
    
    function awardRewards(uint256 _stakeId) internal returns (bool){
        
        uint256 rewards = getPendingInterestDetails(_stakeId);
        if(rewards>0){
            stakesList[_stakeId].lastRewardTimeStamp = now;
            require(transferFunds(stakesList[_stakeId].userAddress,rewards));
            emit RewardsClaimed(stakesList[_stakeId].userAddress,rewards);
        }
        return true;
    }
    
    function awardReferral(address _refereeAddress,uint256 amount) internal returns (bool){
        
        if(_refereeAddress == address(this))
        return false;
        if(userTotalStakeBalance[_refereeAddress] <= 0)
        return false;
        
        usersList[_refereeAddress].referralBalance=usersList[_refereeAddress].referralBalance.add(amount);
        
        emit ReferralAwarded(_refereeAddress,amount);
        
    }
    function  transferFunds(address _transferTo,uint256 amount) internal returns (bool){
        
        require(tokenContract.balanceOf(address(this)) > amount,'Not enough balance in contract to make the transfer');
        require(tokenContract.transfer(_transferTo,amount));
        
        return true;
    }
    
    
    function redeemTokens(uint256 amount)public onlyOwner{
        
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(amount<=tokenBalance,"not enough balance");
        if(now>deployTimestamp+threeYearsInSeconds){
            require(tokenContract.transfer(msg.sender,amount));
        }else{
            require(amount<=(tokenBalance-thresHoldToMaintain),"not enough balance to maintian threshold");
            require(tokenContract.transfer(msg.sender,amount));

        }
    }
    
    
    function emergencyWithdraw(uint256 _stakeId) public {
        require(stakesList[_stakeId].userAddress == msg.sender);
        require(emergencyWithdrwalEnabled,"Emergency withdraw not enabled");
        require(stakesList[_stakeId].stakeOpen,"Stake status should be open");
        
        stakesList[_stakeId].stakeOpen = false;
        
        require(transferFunds(stakesList[_stakeId].userAddress,stakesList[_stakeId].amount));
        
        emit StakeRedeemed(stakesList[_stakeId].userAddress,_stakeId,stakesList[_stakeId].amount);
    }
    
    
    function withdrawAdditionalFunds(uint256 amount) public onlyOwner {
        
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(amount< tokenBalance.sub(totalTokensStaked));
        require(transferFunds(owner(),amount));
        
    }
    
    
    
    
    
}
