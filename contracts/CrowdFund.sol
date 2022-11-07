// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice CrowdFund contract is used to raise funds for a campaign
 * @notice each campaig comes with a id, creator address, target funding, start and end time
 * @dev we use a struct called Campaign -> for every new fund raise, a new campaign is created
 * @dev implement launch, cancel, pledge, unpledge, claim and refund functionalities for crowd fund
 * @dev as next steps, I will create V2 of this contract where images/data associated with campaign will be saved in ipfs
 */
contract CrowdFund {
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);

    struct Campaign {
        // Creator of campaign
        address creator;
        // Amount of tokens to raise
        uint goal;
        // Total amount pledged
        uint pledged;
        // Timestamp of start of campaign
        uint32 startAt;
        // Timestamp of end of campaign
        uint32 endAt;
        // True if goal was reached and creator has claimed the tokens.
        bool claimed;
    }

    IERC20 public immutable token;
    // Total count of campaigns created.
    // It is also used to generate id for new campaigns.
    uint public count;
    // Mapping from id to Campaign
    mapping(uint => Campaign) public campaigns;
    // Mapping from campaign id => pledger => amount pledged
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }
    
    modifier validId(uint _id) {
        require(_id <= count, "invalid id");
        _;
    }
    

    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        // code
        require(_startAt >= block.timestamp, "Start time cannot be in the past");
        require(_startAt < _endAt, "End time cannot be before start time");
        require(_endAt <= block.timestamp + 90 days, "End date cannot exceed 90 days");
        
        count ++;
        
        Campaign memory newCampaign =  Campaign(msg.sender, _goal, 0, _startAt, _endAt, false);
        campaigns[count] = newCampaign;
        
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint _id) validId(_id) external  {
        // code
        Campaign storage campaign = campaigns[_id];
        require(campaign.startAt > block.timestamp, "campaign already started");
        require(campaign.creator == msg.sender, "sender not campaign creator");
        delete campaigns[_id];
        emit Cancel(_id);
        
    }

    function pledge(uint _id, uint _amount) validId(_id) external {
        // code
        Campaign storage campaign = campaigns[_id];
        
        require(block.timestamp >= campaign.startAt, "campaign has not yet started");
        require(block.timestamp < campaign.endAt, "campaign has not yet ended");
        // assume this contract has approval to spend tokens
        bool success = token.transferFrom(msg.sender, address(this), _amount );
        require(success, "token transfer failed");
        
        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        
        emit Pledge(_id, msg.sender, _amount);
        
    }

    function unpledge(uint _id, uint _amount) validId(_id) external {
        // code
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.endAt, "campaign has not yet ended");
        
        pledgedAmount[_id][msg.sender] -= _amount;
        campaign.pledged -= _amount;
        
        bool success = token.transfer(msg.sender, _amount);
        require(success, "transfe failed during unpledge");
        
        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external validId(_id) {
        // code
        Campaign storage campaign = campaigns[_id];

        require(campaign.creator == msg.sender, "sender not campaign creator");
        require(block.timestamp > campaign.endAt, "cannot claim a campaign that has not ended");
        require(campaign.pledged >= campaign.goal, "Total pledged must be greater than goal");
        require(!campaign.claimed, "campaign cannot be claimed");
        campaign.claimed = true;
        if(campaign.pledged > 0){
            bool success = token.transfer(campaign.creator, campaign.pledged);
            require(success, "transfer to creator failed under claim");
            emit Claim(_id);
        }
    }

    function refund(uint _id) external validId(_id) {
        // code
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "campaign currently active");
        require(campaign.pledged < campaign.goal, "cannot refund, pledged > goal");
        
        uint balance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        campaign.pledged = 0;
        
        bool success = token.transfer(msg.sender, balance);
        require(success, "pledged amount refund failed");
        emit Refund(_id, msg.sender, balance);
    }
}