pragma solidity ^0.5.16;
// import "openzeppelin-solidity/contracts/math/Math.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";



import "./Math.sol";
import "./SafeMath.sol";
import "./interface/IMxcStaking.sol";
//this version use index model to support large stakers
contract mxcStakingV2 is IStaking {

    using SafeMath for uint256;

    mapping(address=>uint256) userStaking;

    mapping(address=>uint256) userRewards;
    address [] whitelist;

    address public proxyAddress = 0x1000000000000000000000000000000000000001;
    uint256 public distributedRewards = 0;
    uint256 public totalStaking = 0;
    uint256 public scale = 1000000;
    bool public isInitialized = false;

    struct Double {
        uint mantissa;
    }
    uint constant doubleScale = 1e36;
    uint256 public constant globalInitialIndex = 1e36;
    Double globalIndex = Double({mantissa:globalInitialIndex}) ;

    mapping(address=>Double) userIndex;

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

    function addUserStaking(address account,uint256 amount ) external onlyStakingProxy returns(bool){
        require(isInWhiteList(account),"not in whitelist");
        //trigger distribute rewards
        uint256 balance = address(proxyAddress).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards).sub(amount);
        updateGlobalIndex(newRewards);
        distributedUserRewards(account);
        userStaking[account] = userStaking[account].add(amount);

        totalStaking = totalStaking.add(amount);
        return true;
    }

    function withdrawStaking(address account, uint256 amount) external onlyStakingProxy returns(bool){
        uint256 balance = address(proxyAddress).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        updateGlobalIndex(newRewards);
        distributedUserRewards(account);

        require(amount <= userStaking[account],"not enough staking balance");
        totalStaking = totalStaking.sub(amount);
        userStaking[account] = userStaking[account].sub(amount);

        return true;
    }

    function claimReward(address account) external onlyStakingProxy returns(uint256) {

        require(isInWhiteList(account),"not in white list");
        uint256 balance = address(proxyAddress).balance;
        uint256 newRewards = balance.sub(totalStaking).sub(distributedRewards);
        updateGlobalIndex(newRewards);
        distributedUserRewards(account);

        uint256 value = userRewards[account];
        if (value > 0) {
            distributedRewards = distributedRewards.sub(value);
            userRewards[account] = 0;
        }

        return value;
    }

    function getUserStaking(address account) public view returns(uint256) {
        return userStaking[account];
    }

    function getUserRewards(address account) public view returns(uint256) {

        uint256 balance = address(proxyAddress).balance;
        uint256 rewardAccued = balance.sub(totalStaking).sub(distributedRewards);

        if (rewardAccued > 0 ) {
            Double memory ratio = totalStaking > 0 ? fraction(rewardAccued,totalStaking):Double({mantissa:0});
            Double memory newIndex = add_(globalIndex, ratio);
            Double memory uIndex = userIndex[account];

            if (uIndex.mantissa == 0 && newIndex.mantissa > 0) {
                uIndex.mantissa = globalInitialIndex;
            }

            Double memory deltaIndex = sub_(newIndex,uIndex);
            uint256 supplierDelta = mul_(userStaking[account],deltaIndex);
            return supplierDelta.add(userRewards[account] );
        }

        return userRewards[account];
    }
    function getTotalStaking() public view returns (uint256){
        return totalStaking;
    }
    function getWhiteList() public view returns(address [] memory){
        return whitelist;
    }

    function isInWhiteList(address account) internal view returns(bool){
        for (uint8 i = 0; i<whitelist.length ;i++) {
            if (whitelist[i] == account){
                return true;
            }
        }
        return false;
    }

    function updateGlobalIndex(uint256 rewardAccued) internal {

        if (rewardAccued > 0 ) {
            Double memory ratio = totalStaking > 0 ? fraction(rewardAccued,totalStaking):Double({mantissa:0});
            globalIndex = add_(globalIndex, ratio);
        }
    }

    function distributedUserRewards(address account) internal {

        Double memory uIndex = userIndex[account];

        userIndex[account] = globalIndex;

        if (uIndex.mantissa == 0 && globalIndex.mantissa > 0) {
            uIndex.mantissa = globalInitialIndex;
        }

        Double memory deltaIndex = sub_(globalIndex,uIndex);
        uint256 supplierDelta = mul_(userStaking[account],deltaIndex);
        userRewards[account] = supplierDelta.add(userRewards[account] );
        distributedRewards = distributedRewards + supplierDelta;
    }



    /*========Double============*/
    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }
    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }
    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }
    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }


}