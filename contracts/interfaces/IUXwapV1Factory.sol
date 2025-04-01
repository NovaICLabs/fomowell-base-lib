// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUXwapV1Factory {

    event CreateToken(string name, string symbol, uint256 supply, address tokenAddress, address owner);
    event ContractDeployed(address indexed token);

    function feeTo() external view returns (address);
    function feeToAddress() external view returns (address);
    function getCreateFee() external view returns (uint256);
    function getFeePercentage() external view returns (uint256);

    function getTokenAddress(address token) external view returns (address);
    function getBcTokenAddress(address token) external view returns (address);


    function createBondingCurve(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uri,
        uint256 _initialValueTokenSupply,
        uint256 _initialBondingCurveTokenSupply,
        uint256 _thresholdValueToken,
        uint256 _thresholdBondingCurveToken,
        uint256 _feePercentage
    ) external payable returns (address token, address erc20Token);

//    function createToken(
//        address _router,
//        string memory _tokenName,
//        string memory _tokenSymbol,
//        uint256 _initialValueTokenSupply,
//        uint256 _initialBondingCurveTokenSupply,
//        uint256 _thresholdValueToken,
//        uint256 _thresholdBondingCurveToken,
//        uint256 _feePercentage
//    ) external payable returns (address token);

    function setFeeTo(address _feeTo) external;
    function setFeeToSetter(address _feeToSetter) external;

    function setRouter(address _router) external;
    function setRouterToSetter(address _routerToSetter) external;

}
