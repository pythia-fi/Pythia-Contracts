// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PythiaLPSwap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public uniswapRouter;
    address public tokenAddress;

    constructor() Ownable (msg.sender){
        uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }

    function addLP() external payable nonReentrant {
        require(msg.value > 0, "Must send ETH");

        uint256 amountForSwap = msg.value / 2;
        uint256 amountForLP = amountForSwap;

        // Swap ETH for T_BP tokens
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = tokenAddress;

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountForSwap}(
            0, // Accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );

        // Add liquidity to Uniswap pool
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).approve(address(uniswapRouter), tokenBalance);

        uniswapRouter.addLiquidityETH{value: amountForLP}(
            tokenAddress,
            tokenBalance,
            0, // Minimum amount of tokens to be added as liquidity
            0, // Minimum amount of ETH to be added as liquidity
            msg.sender,
            block.timestamp
        );
        uint256 remainingEth = address(this).balance;
        uint256 remainingTokens = IERC20(tokenAddress).balanceOf(address(this));
        if (remainingTokens > 0) {
            IERC20(tokenAddress).transfer(msg.sender, remainingTokens);
        }

        if (remainingEth > 0) {
            (bool success, ) = payable(msg.sender).call{value: remainingEth}(
                ""
            );
            require(success, "remaining eth not sent");
        }
    }

    function setTokenAddress(address _addr) external onlyOwner {
        require(_addr != address(0), "zero address");
        tokenAddress = _addr;
    }

    receive() external payable {}
}
