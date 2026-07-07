pragma solidity ^0.8.0;

import '../BaseRouter.sol';
import {IZeroDex} from '../interfaces/IZeroDex.sol';
import {IWETH} from '../../interfaces/IWETH.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract ZeroDexRouter is BaseRouter {
    using SafeERC20 for IERC20;

    IZeroDex public immutable zeroDex;
    IWETH public immutable weth;

    constructor(IZeroDex _zeroDex, IWETH _weth) BaseRouter() {
        zeroDex = _zeroDex;
        weth = _weth;
    }

    function _query(address tokenA, address tokenB, uint256 amountIn) internal view virtual override returns (uint256) {
        // ZeroDex can deal with ETH tokens natively, so we convert them to address(0)
        if (tokenA == address(weth)) tokenA = address(0);
        if (tokenB == address(weth)) tokenB = address(0);

        /// First locate pair
        bytes32 pairId = zeroDex.getPairId(tokenA, tokenB);

        // Pair doesn't exist
        if (!zeroDex.poolExists(pairId)) return 0;

        // Get pool price info
        (, uint256 reserve0, uint256 reserve1, ) = zeroDex.getPoolPriceInfo(pairId);
        // Get pool info
        (address token0, , , , , , , ) = zeroDex.pools(pairId);

        // This is how ZeroDex calculates the amount out
        uint256 reserveIn = tokenA == token0 ? reserve0 : reserve1;
        uint256 reserveOut = tokenB == token0 ? reserve1 : reserve0;

        uint256 fee = (amountIn * zeroDex.swapFee()) / 10000;
        uint256 amountInAfterFee = amountIn - fee;

        return (amountInAfterFee * reserveOut) / (reserveIn + amountInAfterFee);
    }

    function _swap(
        address tokenA,
        address tokenB,
        address to,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline
    ) internal virtual override {
        // ZeroDex can deal with ETH tokens internally, so we convert WETH to address(0)
        if (tokenA == address(weth)) {
            weth.withdraw(amountIn); // Withdraw ETH from WETH contract
            tokenA = address(0);
        }
        if (tokenB == address(weth)) tokenB = address(0);

        // Track token balance before swap. ZeroDex sends output to this contract, so we need to track it before the swap
        uint256 tokenOutBalanceBefore = tokenB == address(0)
            ? weth.balanceOf(address(this)) // ETH tokens are always deposited as WETH
            : IERC20(tokenB).balanceOf(address(this));

        // Allow base router to spend amount
        if (tokenA != address(0)) IERC20(tokenA).approve(address(zeroDex), amountIn);

        // Ether value
        uint256 etherValue = tokenA == address(0) ? amountIn : 0;
        // Swap
        zeroDex.swap{value: etherValue}(tokenA, tokenB, amountIn, amountOut);
        // Get token balance after swap
        uint256 tokenOutBalanceAfter = tokenB == address(0)
            ? weth.balanceOf(address(this)) // ETH tokens are always deposited as WETH
            : IERC20(tokenB).balanceOf(address(this));

        // Convert tokenB back to WETH if necessary
        if (tokenB == address(0)) tokenB = address(weth);

        // Transfer output to recipient
        IERC20(tokenB).safeTransfer(to, tokenOutBalanceAfter - tokenOutBalanceBefore);
        require(tokenOutBalanceAfter - tokenOutBalanceBefore >= amountOut, 'Swap amount too small');
        require(deadline >= block.timestamp, 'Deadline exceeded');
    }

    receive() external payable {
        // Deposit ETH into WETH contract if not from WETH (to avoid infinite loop)
        if (msg.sender != address(weth)) {
            weth.deposit{value: msg.value}(); // Deposit ETH into WETH contract
        }
    }
}
