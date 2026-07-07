pragma solidity ^0.8.0;

interface IDrunkenCatsFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    // address that protocol swap fees are sent to (the FeeCollector). address(0) => protocol fee off.
    function feeCollector() external view returns (address);
    // governance address allowed to change fee settings.
    function feeToSetter() external view returns (address);
    // protocol fee, in basis points of the swap input (e.g. 9 = 0.09% of input).
    // total swap fee is fixed at 0.30%; protocolFeeBps is the portion routed to the FeeCollector.
    function protocolFeeBps() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeCollector(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFeeBps(uint256) external;
}
