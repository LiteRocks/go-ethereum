pragma solidity ^0.5.16;


import './interface/ICunpStaking.sol';

contract StakingProxy {
    address public stakingContractAddress;
    address public owner;
    bool initilaized = false;

    /// @notice Emitted when staking
    event StakedEvent(address account, uint256 amount);

    /// @notice Emitted when initialized
    event InitializedEvent(address account,address stakingAddress);

    /// @notice Emitted when addWhiteList
    event AddedWhiteListEvent(address account);

    /// @notice Emitted when withdrawnStaking
    event WithdrawnStakingEvent(address account,uint256 amount);

    /// @notice Emitted when claimedReward
    event ClaimedRewardEvent(address account,uint256 amount);

    /// @notice Emitted when owner changed
    event SetOwnerEvent(address newOwner);

    /// @notice Emitted when staking contract changed
    event SetStakingContractEvent(address newContract);


    function init(address account,address stakingAddr) external {
        require(!initilaized,'already initialized');
        owner = account;
        stakingContractAddress = stakingAddr;

        initilaized = true;
        emit InitializedEvent(account,stakingAddr);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, string(abi.encodePacked("Only the contract owner may perform this action:",owner)));
    }

    //===============owner operations

    function setOwner(address newOwner) external onlyOwner{
        owner = newOwner;
        emit SetOwnerEvent(newOwner);
    }

    function setStakingContract(address newAddress) external onlyOwner {
        stakingContractAddress = newAddress;
        emit SetStakingContractEvent(newAddress);
    }


    function addNewStaker(address staker) external onlyOwner returns(bool) {
        IStaking staking = _getStakingContract();
        require( staking.addWhiteList(staker),'addNewStaker failed!');
        emit AddedWhiteListEvent(staker);
        return true;
    }

    function stake() payable external returns(bool) {
        require( _getStakingContract().addUserStaking(msg.sender ,msg.value),'stake failed!');
        emit StakedEvent(msg.sender,msg.value);
        return true;

    }

    function withdraw(uint256 amount) external returns(bool) {
        require(_getStakingContract().withdrawStaking(msg.sender,amount),'withdraw failed');
        msg.sender.transfer(amount);
        emit WithdrawnStakingEvent(msg.sender, amount);
        return true;
    }

    function claimRewards() external returns(bool) {
        uint256 rewards = _getStakingContract().claimReward(msg.sender);
        require( rewards> 0 ,'claim failed');
        msg.sender.transfer(rewards);
        emit ClaimedRewardEvent(msg.sender, rewards);
        return true;
    }


    //======================= views
    function getUserStaking(address account) public view returns(uint256){
        return _getStakingContract().getUserStaking(account);
    }

    function getUserRewards(address account) public view returns(uint256){
        return _getStakingContract().getUserRewards(account);
    }

    function totalStaking()public view returns(uint256){
        return _getStakingContract().getTotalStaking();
    }

    function getStakingUsers() public view returns( address [] memory){
        return _getStakingContract().getWhiteList();
    }

    function _getStakingContract() internal view returns(IStaking) {
        return IStaking(stakingContractAddress);
    }

}

