// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint) public rewards;

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        // Code
        rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if(_account != address(0)){
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;            
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        // Code
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        // Code
        
        uint result = rewardPerTokenStored;
        result += totalSupply == 0 ? 0 : rewardRate * (lastTimeRewardApplicable() - updatedAt ) * 10**18/ totalSupply;
        return result;
    }

    function stake(uint _amount) external updateReward(msg.sender){
        // Code
        require(_amount > 0, "stake amount > 0");
        bool success = stakingToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "transfer of staking amount failed");
        
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        // Code
        require(_amount > 0, "amount > 0");
        require(_amount <= balanceOf[msg.sender], "invalid amount");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        bool success = stakingToken.transfer(msg.sender, _amount);
        require(success, "withdrawal of staking token failed");
        
    }

    function earned(address _account) public view returns (uint) {
        // Code
       return rewards[_account] + ((rewardPerToken() - userRewardPerTokenPaid[_account]) * balanceOf[_account]) / 10 ** 18;
    }

    function getReward() external updateReward(msg.sender) {
        // Code
        uint rewardAmt = rewards[msg.sender];
        rewards[msg.sender] = 0;
        bool success = rewardsToken.transfer(msg.sender, rewardAmt );
        require(success, "rewards transfer failed");        
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        // Code
        require(block.timestamp > finishAt, "previous reward period not expired");
        duration = _duration;
    }

    function notifyRewardAmount(uint _amount) external onlyOwner updateReward(address(0)) {
        // Code
        if(block.timestamp >= finishAt){
            rewardRate = duration == 0 ? 0 : _amount / duration;            
        }
        else{
            rewardRate = (_amount + rewardRate * (finishAt - block.timestamp))/ duration;
        }
        
        require(rewardRate > 0, "reward rate = 0");
        require(rewardsToken.balanceOf(address(this)) >= rewardRate * duration, "not enough rewards");

        updatedAt = block.timestamp;
        finishAt = block.timestamp + duration;
        
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
