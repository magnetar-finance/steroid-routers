pragma solidity ^0.8.0;

interface IZeroDex {
    function getPrice(address tokenIn, address tokenOut) external view returns (uint256 price);
    function getPairId(address tokenA, address tokenB) external view returns (bytes32);
    function poolExists(bytes32 pairId) external view returns (bool);
    function swapFee() external view returns (uint256);
    function getPoolPriceInfo(
        bytes32 pairId
    ) external view returns (uint256 price, uint256 reserve0, uint256 reserve1, uint256 totalLP);
    function pools(
        bytes32 pairId
    )
        external
        view
        returns (
            address token0,
            address token1,
            uint256 reserve0,
            uint256 reserve1,
            uint256 totalLP,
            uint256 volume24h,
            uint256 totalVolume,
            uint256 lastVolumeReset
        );
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable returns (uint256);
}
