pragma solidity ^0.5.16;
// import "openzeppelin-solidity/contracts/math/Math.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./Math.sol";
import "./SafeMath.sol";
import "./interface/ICunpStaking.sol";

contract cunpStaking is IStaking {

    using SafeMath for uint256;

    mapping(address=>uint256) nodeStaking;

    mapping(address=>uint256) nodeRewards;
    address [] whitelist;
    address [] nodes;

    address public proxyAddress = 0x1000000000000000000000000000000000000001;
    uint256 public distributedRewards = 0;
    uint256 public totalStaking = 0;
    uint256 public scale = 1000000;
    bool public isInitialized = false;


    modifier onlyStakingProxy {
        _onlyStakingProxy();
        _;
    }

    function _onlyStakingProxy() internal view {
        require(msg.sender == proxyAddress, string(abi.encodePacked("Only the proxy contract may perform this action:",proxyAddress)));
    }

    function addWhiteList(address account) external onlyStakingProxy returns(bool) {
        if(!isInWhiteList(account)){
            whitelist.push(account);
        }

        return true;
    }

    function addUserStaking(address account,uint256 amount ) external returns(bool){
        require(isInWhiteList(account),"not in whitelist");
        //trigger distribute rewards
        uint256 balance = address(proxyAddress).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards).sub(amount);
        distributeRewards(newRewards);

        if (isNodeRegistered(account)) {
            nodeStaking[account] = nodeStaking[account].add(amount);
        }else{
            nodeStaking[account] = amount;
            nodes.push(account);

        }
        totalStaking = totalStaking.add(amount);
        return true;
    }

    function withdrawStaking(address account, uint256 amount) external returns(bool){
        uint256 balance = address(proxyAddress).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        distributeRewards(newRewards);

        require(amount <= nodeStaking[account],"not enough staking balance");
        totalStaking = totalStaking.sub(amount);
        nodeStaking[account] = nodeStaking[account].sub(amount);
        if(nodeStaking[account] == 0){
            for (uint8 i = 0 ;i<nodes.length;i++){
                if(nodes[i] == account){
                    delete nodes[i];
                    break;
                }
            }
        }
        return true;
    }

    function claimReward(address account) external returns(uint256) {

        require(isInWhiteList(account),"not in white list");
        uint256 balance = address(proxyAddress).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        distributeRewards(newRewards);

        uint256 value = nodeRewards[account];
        if (value > 0) {
            distributedRewards = distributedRewards.sub(value);
            nodeRewards[account] = 0;
        }

        return value;
    }

    function isNodeRegistered(address nodeAddress) internal view returns(bool) {
        for (uint8 i = 0 ;i<nodes.length;i++){
            if(nodes[i] == nodeAddress){
                return true;
            }
        }
        return false;
    }

    function getUserStaking(address account) public view returns(uint256) {
        return nodeStaking[account];
    }

    function getUserRewards(address account) public view returns(uint256) {
        if(totalStaking == 0 ){
            return nodeRewards[account];
        }

        uint256 balance = address(proxyAddress).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        uint256 ratio = scale.mul(nodeStaking[account]).div(totalStaking);
        uint256 reward = newRewards.mul(ratio).div(scale);

        return nodeRewards[account].add(reward);
    }
    function getTotalStaking() public view returns (uint256){
        return totalStaking;
    }
    function getWhiteList() public view returns(address [] memory){
        return whitelist;
    }

    function distributeRewards(uint256 newRewards) internal returns(bool){
        if (newRewards > 0 && totalStaking > 0) {
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