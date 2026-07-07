pragma solidity ^0.8.0;

import '../BaseRouter.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router.sol';
import {IUniswapV2Factory} from '../interfaces/IUniswapV2Factory.sol';
import {IUniswapV2Pair} from '../interfaces/IUniswapV2Pair.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract UniswapV2Router is BaseRouter {
    IUniswapV2Router02 public immutable baseSwapRouter;
    IUniswapV2Factory public immutable baseFactory;

    constructor(IUniswapV2Router02 _baseSwapRouter) BaseRouter() {
        baseSwapRouter = _baseSwapRouter;
        baseFactory = IUniswapV2Factory(baseSwapRouter.factory());
    }

    function _query(address tokenA, address tokenB, uint256 amountIn) internal view virtual override returns (uint256) {
        /// First locate pair
        address pair = baseFactory.getPair(tokenA, tokenB);

        // Pair doesn't exist
        if (pair == address(0)) return 0;

        IUniswapV2Pair uniswapPair = IUniswapV2Pair(pair);
        // Get reserves
        (uint112 r0, uint112 r1, ) = uniswapPair.getReserves();
        (uint112 reserve0, uint112 reserve1) = uniswapPair.token0() == tokenA ? (r0, r1) : (r1, r0);
        return baseSwapRouter.getAmountOut(amountIn, reserve0, reserve1);
    }

    function _swap(
        address tokenA,
        address tokenB,
        address to,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline
    ) internal virtual override {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        // Allow base router to spend amount
        IERC20(tokenA).approve(address(baseSwapRouter), amountIn);
        // Swap
        baseSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOut, path, to, deadline);
    }
}
