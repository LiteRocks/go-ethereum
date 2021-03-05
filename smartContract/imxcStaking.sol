pragma solidity ^0.5.16;

interface mxcStaking {
    function addWhiteList(address account) external  returns(bool);
    function addNodeStaking()payable external returns(bool);

    function withdrawStaking(uint256 amount) external returns(bool);

    function claimReward() external returns(bool);
    function getNodeStaking(address account) external view returns(uint);

    function getNodeReward(address account) external view returns(uint);
    function owner() external view returns(address);
    function init(address account) external returns(bool);
}