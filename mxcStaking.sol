pragma solidity ^0.5.16;
import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract mxcStaking {
    using SafeMath for uint256;

    mapping(address=>uint256) nodeStaking;

    mapping(address=>uint256) nodeRewards;

    address [] nodes;

    address owner = 0x26356Cb66F8fd62c03F569EC3691B6F00173EB02;
    uint256 distributedRewards = 0;
    uint256 totalStaking = 0;
    uint256 scale = 10000;

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    function addNodeStaking() payable external onlyOwner returns(bool){
        //trigger distribute rewards
        uint256 balance = address(this).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards).sub(msg.value);
        distributeRewards(newRewards);

        if (isNodeRegistered(msg.sender)) {
            nodeStaking[msg.sender] = nodeStaking[msg.sender].add(msg.value);
        }else{
            nodeStaking[msg.sender] = msg.value;
        }
        totalStaking = totalStaking.add(msg.value);
        nodes.push(msg.sender);

        return true;
    }

    function withdrawStaking(uint256 amount) external returns(bool){
        uint256 balance = address(this).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        distributeRewards(newRewards);

        require(amount >= nodeStaking[msg.sender],"not enough staking");
        msg.sender.transfer(amount);
        totalStaking = totalStaking.sub(amount);
        nodeStaking[msg.sender] = nodeStaking[msg.sender].sub(msg.sender);
        if(nodeStaking[msg.sender] == 0){
            for (uint8 i = 0 ;i<nodes.length;i++){
                if(nodes[i] == nodeAddress){
                    delete node[i];
                    break;
                }
            }
        }
        return true;
    }

    function isNodeRegistered(address nodeAddress) internal returns(bool) {
        for (uint8 i = 0 ;i<nodes.length;i++){
            if(nodes[i] == nodeAddress){
                return true;
            }
        }
        return false;
    }

    function getIndexOfNodes(address nodeAddress) internal returns(uint){

        return
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
        }
        return true;
    }
}