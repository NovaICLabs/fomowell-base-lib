// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUXwapV1Router {

    event TokenCreated(address indexed token, address indexed erc20TokenAddress, string name, string symbol,string uri,string description,string telegramLink,string twitterLink,string website,address owner);
    event TokenBought(address indexed buyer, address indexed bondingCurve, uint256 ethAmount, uint256 tokenAmount);
    event TokenSold(address indexed seller, address indexed bondingCurve, uint256 tokenAmount, uint256 ethAmount);

    function createToken(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uri,
        string memory _description,
        string memory _telegramLink,
        string memory _twitterLink,
        string memory _website
    ) external payable returns (address tokenAddress, address erc20TokenAddress);

    function buyToken(address tokenAddress, uint256 deadline) external payable returns (uint256 amountOut);
    function sellToken(address tokenAddress, uint256 amountIn) external returns (uint256 amountOut);

}
