// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMagnetarPool {
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);
    function stable() external view returns (bool);
}
