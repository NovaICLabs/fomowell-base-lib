// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapRouterExtraVariables {
    function factory() external view returns (address);
    function WETH() external view returns (address);
}
