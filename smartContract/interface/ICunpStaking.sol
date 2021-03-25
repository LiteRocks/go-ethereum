pragma solidity ^0.5.16;

interface IStaking {
    function addWhiteList(address account) external  returns(bool);
    function addUserStaking(address account ,uint256 amount )external returns(bool);

    function withdrawStaking(address account ,uint256 amount) external returns(bool);

    function claimReward(address account ) external returns(uint256);
    function getUserStaking(address account) external view returns(uint);
    function getUserRewards(address account) external view returns(uint);

    function getTotalStaking() external view returns (uint256);
    function getWhiteList() external view returns(address [] memory);
}