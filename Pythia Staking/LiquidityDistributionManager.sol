// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILiquidityDistributionManager.sol";
import "./IToken.sol";

contract LiquidityDistributorManager is ILiquidityDistributionManager, Ownable {
    using SafeERC20 for IERC20;

    IToken public immutable rewardToken;
    address[] pools;
    mapping(address => uint256) private rewardPerSeconds;

    event RewardsPerSecondSet(uint256 rewardsPerSecond);
    event RewardsDistributed(address _from, uint256 _amount);

    constructor(address _rewardToken) Ownable(msg.sender) {
        require(_rewardToken != address(0), "reward token must be set");
        rewardToken = IToken(_rewardToken);
    }

    function addPool(address _pool, uint256 _rps) external onlyOwner {
        pools.push(_pool);
        rewardPerSeconds[_pool] = _rps;
        rewardToken.approve(address(_pool), type(uint256).max);
    }

    function updateRPS(address _pool, uint256 _newRps) external onlyOwner {
        rewardPerSeconds[_pool] = _newRps;
    }

    function removePool(uint256 _index) external onlyOwner {
        require(_index < pools.length, "Index out of bounds");

        address _pool = pools[_index];
        rewardToken.approve(address(_pool), 0);
        pools[_index] = pools[pools.length - 1];
        pools.pop();
        rewardPerSeconds[_pool] = 0;
    }

    function distributor(
        uint256 _duration
    ) external override returns (uint256) {
        address to;
        uint256 rewardPerSecond;

        // staking pool
        if(msg.sender == address(pools[0])) {
            to = pools[0];
            rewardPerSecond = rewardPerSeconds[address(pools[0])];
        } else if (msg.sender == address(pools[1])){
            to = pools[1];
            rewardPerSecond = rewardPerSeconds[address(pools[1])];
        } else {
            revert("Invalid msg.sender");
        }

        uint256 totalRewardAmount = rewardPerSecond * _duration;

        // return if accrued rewards == 0
        if (totalRewardAmount == 0) {
            return 0;
        }
        (bool success, bytes memory data) = address(rewardToken).call(
            abi.encodeWithSignature("issueRewards(address,uint256)", to, totalRewardAmount)
        );
        if(!success) {
            totalRewardAmount = 0;
        }

        emit RewardsDistributed(msg.sender, totalRewardAmount);
        return totalRewardAmount;
    }

    function getPools(uint256 _a) external view returns(address) {
        return pools[_a];
    }
}
