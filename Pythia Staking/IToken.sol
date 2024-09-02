// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IToken {
    function issueRewards(address stakingCA, uint256 rewardsAmount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}