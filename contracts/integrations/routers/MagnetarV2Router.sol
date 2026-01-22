pragma solidity ^0.8.0;

import '../BaseRouter.sol';
import '../interfaces/IMagnetarV2Router.sol';
import '../interfaces/IMagnetarV2Factory.sol';
import '../interfaces/IMagnetarPool.sol';

contract MagnetarV2Router is BaseRouter {
    using SafeERC20 for IERC20;

    IMagnetarV2Router public immutable baseRouter;
    IMagnetarV2Factory public immutable baseFactory;

    constructor(IMagnetarV2Router _baseRouter) BaseRouter() {
        baseRouter = _baseRouter;
        baseFactory = IMagnetarV2Factory(_baseRouter.defaultFactory());
    }

    function _getBestDirectRoute(
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) private view returns (IMagnetarV2Router.Route memory _route, uint256 amountOut) {
        if (tokenA != tokenB && amountIn != 0) {
            address pool = baseFactory.getPool(tokenA, tokenB, true);
            uint256 aOut;

            _route.factory = address(baseFactory);

            if (pool != address(0)) {
                _route.from = tokenA;
                _route.to = tokenB;
                _route.stable = true;

                aOut = IMagnetarPool(pool).getAmountOut(amountIn, tokenA);
                amountOut = aOut;
            }

            pool = baseFactory.getPool(tokenA, tokenB, false);

            if (pool != address(0)) {
                aOut = IMagnetarPool(pool).getAmountOut(amountIn, tokenA);
                if (aOut > amountOut) {
                    amountOut = aOut;

                    _route.from = tokenA;
                    _route.to = tokenB;
                    _route.stable = false;
                }
            }
        }
    }

    function _query(
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) internal view virtual override returns (uint256 amountOut) {
        (, amountOut) = _getBestDirectRoute(tokenA, tokenB, amountIn);
    }

    function _swap(
        address tokenA,
        address tokenB,
        address to,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline
    ) internal virtual override {
        (IMagnetarV2Router.Route memory route, ) = _getBestDirectRoute(tokenA, tokenB, amountIn);
        IMagnetarV2Router.Route[] memory routes = new IMagnetarV2Router.Route[](1);
        routes[0] = route;
        // Allow base router to spend amount
        IERC20(tokenA).approve(address(baseRouter), amountIn);
        // Swap
        baseRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOut, routes, to, deadline);
    }
}
