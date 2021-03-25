pragma solidity ^0.5.16;

interface cunpStaking {
    function init(address account,address stakingAddr) external ;
    function setOwner(address newOwner) external;
    function setStakingContract(address newAddress) external;
    function addNewStaker(address staker) external returns(bool);
    function stake() payable external returns(bool) ;
    function withdraw(uint256 amount) external returns(bool);
    function claimRewards() external returns(bool);

    function getUserStaking(address account) external view returns(uint256) ;
    function getUserRewards(address account) external view returns(uint256);
    function totalStaking() external view returns(uint256);
    function getStakingUsers() external view returns( address [] memory);
}