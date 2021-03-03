pragma solidity ^0.5.16;
// import "openzeppelin-solidity/contracts/math/Math.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./Math.sol";
import "./SafeMath.sol";

contract mxcStaking {

    /// @notice Emitted when staking
    event staked(address account, uint256 amount);

    /// @notice Emitted when initialized
    event initialized(address account);

    /// @notice Emitted when addWhiteList
    event addedWhiteList(address account);

    /// @notice Emitted when withdrawnStaking
    event withdrawnStaking(address account,uint256 amount);

    /// @notice Emitted when claimedReward
    event claimedReward(address account,uint256 amount);



    using SafeMath for uint256;

    mapping(address=>uint256) nodeStaking;

    mapping(address=>uint256) nodeRewards;
    address [] whitelist;
    address [] nodes;

    address public owner ;
    uint256 public distributedRewards = 0;
    uint256 public totalStaking = 0;
    uint256 public scale = 10000;
    bool public isInitialized = false;

    function init(address account) external returns(bool){
        if (isInitialized) {
            return true;
        }
        isInitialized = true;

        //NOTE:values not initialized automatically in genesis block.
        //NOTE:values not initialized automatically in genesis block.
        owner = account;
        scale = 10000;
        emit initialized(account);

        return true;
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, string(abi.encodePacked("Only the contract owner may perform this action:",owner)));
    }

    function addWhiteList(address account) external onlyOwner returns(bool) {
        if(!isInWhiteList(account)){
            whitelist.push(account);
        }
        emit addedWhiteList(account);

        return true;
    }

    function addNodeStaking() payable external returns(bool){
        require(isInWhiteList(msg.sender),"not in whitelist");
        //trigger distribute rewards
        uint256 balance = address(this).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards).sub(msg.value);
        distributeRewards(newRewards);

        if (isNodeRegistered(msg.sender)) {
            nodeStaking[msg.sender] = nodeStaking[msg.sender].add(msg.value);
        }else{
            nodeStaking[msg.sender] = msg.value;
            nodes.push(msg.sender);

        }
        totalStaking = totalStaking.add(msg.value);
        emit staked(msg.sender, msg.value);
        return true;
    }

    function withdrawStaking(uint256 amount) external returns(bool){
        uint256 balance = address(this).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        distributeRewards(newRewards);

        require(amount <= nodeStaking[msg.sender],"not enough staking balance");
        msg.sender.transfer(amount);
        totalStaking = totalStaking.sub(amount);
        nodeStaking[msg.sender] = nodeStaking[msg.sender].sub(amount);
        if(nodeStaking[msg.sender] == 0){
            for (uint8 i = 0 ;i<nodes.length;i++){
                if(nodes[i] == msg.sender){
                    delete nodes[i];
                    break;
                }
            }
        }
        emit withdrawnStaking(msg.sender, amount);
        return true;
    }

    function claimReward() external returns(bool) {

        require(isInWhiteList(msg.sender),"not in white list");
        uint256 balance = address(this).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        if(!distributeRewards(newRewards)){
            return true;
        }

        uint256 value = nodeRewards[msg.sender];
        if (value > 0) {
            msg.sender.transfer(value);
            distributedRewards = distributedRewards.sub(value);
            nodeRewards[msg.sender] = 0;
        }
        emit claimedReward(msg.sender, value);

        return true;
    }

    function isNodeRegistered(address nodeAddress) internal view returns(bool) {
        for (uint8 i = 0 ;i<nodes.length;i++){
            if(nodes[i] == nodeAddress){
                return true;
            }
        }
        return false;
    }

    function getNodeStaking(address account) public view returns(uint256) {
        return nodeStaking[account];
    }

    function getNodeReward(address account) public view returns(uint256) {
        if(totalStaking == 0){
            return 0;
        }

        uint256 balance = address(this).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        uint256 ratio = scale.mul(nodeStaking[account]).div(totalStaking);
        uint256 reward = newRewards.mul(ratio).div(scale);

        return nodeRewards[account].add(reward);
    }


    function distributeRewards(uint256 newRewards) internal returns(bool){
        if (newRewards > 0) {
            for (uint8 i = 0 ;i<nodes.length;i++){
                address nodeAddress = nodes[i];
                uint256 ratio = scale.mul(nodeStaking[nodeAddress]).div(totalStaking);
                uint256 reward = newRewards.mul(ratio).div(scale);
                nodeRewards[nodeAddress] = nodeRewards[nodeAddress].add(reward);
                distributedRewards = distributedRewards.add(reward);
            }
            return true;
        }
        return false;

    }

    function isInWhiteList(address account) internal view returns(bool){
        for (uint8 i = 0; i<whitelist.length ;i++) {
            if (whitelist[i] == account){
                return true;
            }
        }
        return false;
    }
}