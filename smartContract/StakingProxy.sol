pragma solidity ^0.5.16;


import './interface/IMxcStaking.sol';

contract StakingProxy {
    address public stakingContractAddress;
    address public owner;
    bool initilaized = false;

    /// @notice Emitted when staking
    event stakedEvent(address account, uint256 amount);

    /// @notice Emitted when initialized
    event initializedEvent(address account,address stakingAddress);

    /// @notice Emitted when addWhiteList
    event addedWhiteListEvent(address account);

    /// @notice Emitted when withdrawnStaking
    event withdrawnStakingEvent(address account,uint256 amount);

    /// @notice Emitted when claimedReward
    event claimedRewardEvent(address account,uint256 amount);

    /// @notice Emitted when owner changed
    event setOwnerEvent(address newOwner);

    /// @notice Emitted when staking contract changed
    event setStakingContractEvent(address newContract);


    function init(address account,address stakingAddr) external {
        require(!initilaized,'already initialized');
        owner = account;
        stakingContractAddress = stakingAddr;

        //approve 1 Billion mxc to staking contract
        initilaized = true;
        emit initializedEvent(account,stakingAddr);
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
        emit setOwnerEvent(newOwner);
    }

    function setStakingContract(address newAddress) external onlyOwner {
        stakingContractAddress = newAddress;
        emit setStakingContractEvent(newAddress);
    }


    function addNewStaker(address staker) external onlyOwner returns(bool) {
        IStaking staking = _getStakingContract();
        require( staking.addWhiteList(staker),'addNewStaker failed!');
        emit addedWhiteListEvent(staker);
        return true;
    }

    function stake() payable external returns(bool) {
        require( _getStakingContract().addUserStaking(msg.sender ,msg.value),'stake failed!');
        emit stakedEvent(msg.sender,msg.value);
        return true;

    }

    function withdraw(uint256 amount) external returns(bool) {
        require(_getStakingContract().withdrawStaking(msg.sender,amount),'withdraw failed');
        msg.sender.transfer(amount);
        emit withdrawnStakingEvent(msg.sender, amount);
        return true;
    }

    function claimRewards() external returns(bool) {
        uint256 rewards = _getStakingContract().claimReward(msg.sender);
        require( rewards> 0 ,'claim failed');
        msg.sender.transfer(rewards);
        emit claimedRewardEvent(msg.sender, rewards);
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

