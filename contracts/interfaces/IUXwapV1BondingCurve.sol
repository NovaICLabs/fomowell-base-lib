// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";

interface IUXwapV1BondingCurve {

    event MintToken(string name, string symbol,uint256 supply, address tokenAddress, address owner);

    event TokensReceived(address indexed from, uint256 amount, address indexed tokenAddress);
    event EtherReceived(address indexed from, uint256 amount);

    event TokenBought(address indexed buyer, uint256 fromAmount, uint256 toAmount);
    event TokenSold(address indexed seller, uint256 fromAmount, uint256 toAmount);
//    event Sync(address indexed tokenAddress, uint256 tokenBalance, uint256 ethBalance, uint256 availableTokenSupply, uint256 availableEthSupply);
    event Sync(uint256 reserve0, uint256 reserve1);

    function buyTokenWithReceiver(address to) external payable returns (uint256 amountOut);
    function sellTokenWithSenderAndReceiver(address seller, uint256 sellTokenAmount) external payable returns (uint256 amountOut);

//    function calculateEthToToken(uint256 valueToken) external view returns (uint256 amountOut);
//    function calculateTokenToEth(uint256 valueToken) external view returns (uint256 amountOut);
//    function addLiquidityToUniswap(address tokenA) internal returns (address pair);

    function getBcTokenAddress() external returns (address);

    function getAvailableTokenSupply() external view returns (uint256);

    function getAvailableEthSupply() external view returns (uint256);

    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast);

}
