pragma solidity ^0.8.0;

import '../BaseRouter.sol';
import '../interfaces/ISynthraV3SwapRouter.sol';
import '../interfaces/ISynthraV3Factory.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract SynthraV3Router is BaseRouter {
    using SafeERC20 for IERC20;

    ISynthraV3Factory public immutable factory;
    ISynthraV3SwapRouter public immutable swapRouter;

    constructor(address _factory, address _swapRouter) BaseRouter() {
        factory = ISynthraV3Factory(_factory);
        swapRouter = ISynthraV3SwapRouter(_swapRouter);
    }

    function _getBalance(address token, address _acc) private view returns (uint256 _balance) {
        (, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, _acc));
        _balance = abi.decode(data, (uint256));
    }

    function _getDecimals(address token) private view returns (uint8 _decimals) {
        (, bytes memory data) = token.staticcall(abi.encodeWithSelector(bytes4(keccak256(bytes('decimals()')))));
        _decimals = abi.decode(data, (uint8));
    }

    function _getBestRoute(
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) private view returns (uint24 tickSpacing, uint256 amountOut) {
        if (tokenA != tokenB && amountIn != 0) {
            uint24[] memory tickSpacings = new uint24[](3);
            tickSpacings[0] = 500;
            tickSpacings[1] = 3000;
            tickSpacings[2] = 10000;

            for (uint i = 0; i < tickSpacings.length; i++) {
                address pool = factory.getPool(tokenA, tokenB, tickSpacings[i]);
                if (pool == address(0)) continue;
                uint256 balanceA = _getBalance(tokenA, pool);
                uint256 balanceB = _getBalance(tokenB, pool);
                if (balanceA == 0 || balanceB == 0) continue;
                // Calculate price of token A in terms of B
                uint8 decimalsA = _getDecimals(tokenA);
                uint256 priceA = (balanceB * 10 ** decimalsA) / balanceA;
                uint256 aOut = (amountIn * priceA) / (10 ** decimalsA);
                if (aOut > amountOut) {
                    amountOut = aOut;
                    tickSpacing = tickSpacings[i];
                }
            }
        }
    }

    function _query(
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) internal view virtual override returns (uint256 amountOut) {
        (, amountOut) = _getBestRoute(tokenA, tokenB, amountIn);
    }

    function _swap(
        address tokenA,
        address tokenB,
        address to,
        uint256 amountIn,
        uint256 amountOut,
        uint256 deadline
    ) internal virtual override {
        (uint24 tickSpacing, ) = _getBestRoute(tokenA, tokenB, amountIn);
        // Params
        ISynthraV3SwapRouter.ExactInputSingleParams memory params = ISynthraV3SwapRouter.ExactInputSingleParams(
            tokenA,
            tokenB,
            tickSpacing,
            to,
            amountIn,
            amountOut,
            0
        );
        bytes memory callBytes = abi.encodeWithSelector(ISynthraV3SwapRouter.exactInputSingle.selector, params);
        // Allow base router to spend amount
        IERC20(tokenA).approve(address(swapRouter), amountIn);
        (bool success, ) = address(swapRouter).call(callBytes);
        require(success, 'Swap failed');
        require(block.timestamp < deadline, 'Deadline exceeded');
    }
}
