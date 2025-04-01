// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUXwapV1Factory} from "./interfaces/IUXwapV1Factory.sol";
import {IUXwapV1BondingCurve} from "./interfaces/IUXwapV1BondingCurve.sol";
import {UXwapV1BondingCurve} from "./UXwapV1BondingCurve.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import "hardhat/console.sol";
import {CommonBase} from "./libraries/CommonBase.sol";

contract UXwapV1Factory is IUXwapV1Factory, Ownable, CommonBase
{
    uint256 public constant CREATE_FEE = 2 * 10 ** 15;
    uint256 public constant FEE_PERCENTAGE = 100; // 100 means 1 percent

    address public feeTo;
    address public feeToSetter;

    address public router;
    address public routerToSetter;

    address[] public bondingCurves;

    mapping(address => address) public getToken;
    mapping(address => address) public getBcToken;

    TimelockController public timelock;

    event BondingCurveDeployed(address bondingCurveAddress);


    constructor(
        address _feeToSetter,
        address _routerToSetter,
        uint256 minDelay, // Timelock delay in seconds
        address[] memory proposers,
        address[] memory executors
    ) {
        feeToSetter = _feeToSetter;
        routerToSetter = _routerToSetter;
//        transferOwnership(msg.sender); // set the initial owner
        timelock = new TimelockController(minDelay, proposers, executors, _msgSender());
        transferOwnership(address(timelock)); // Transfer ownership to TimelockController
    }

    function getCreateFee() external pure returns (uint256){
        return CREATE_FEE;
    }

    function getFeePercentage() external pure returns (uint256){
        return FEE_PERCENTAGE;
    }

    function feeToAddress() external view returns (address) {
        return feeTo;
    }

    function getTokenAddress(address token) external view returns (address) {
        return getToken[token];
    }

    function getBcTokenAddress(address token) external view returns (address){
        return getBcToken[token];
    }

    function createBondingCurve(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uri,
        uint256 _initialEthSupply,
        uint256 _initialTokenSupply,
        uint256 _minEthThreshold,
        uint256 _minTokenThreshold,
        uint256 _ethFundThreshold
    ) external payable override returns (address token, address erc20Token) {
        console.log("Create Bonding Curve Invoke in Factory.");
        require(getToken[token] == address(0), "UXwapV1Factory: token already exists");

        bytes memory bytecode = abi.encodePacked(
            type(UXwapV1BondingCurve).creationCode,
            abi.encode(
                router,
                _tokenName,
                _tokenSymbol,
                _uri,
                _initialEthSupply,
                _initialTokenSupply,
                _minEthThreshold,
                _minTokenThreshold,
                _ethFundThreshold
            )
        );

        bytes32 salt = keccak256(abi.encodePacked(_tokenName, _tokenSymbol, block.timestamp));
        assembly {
            token := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(token)) {
                revert(0, 0)
            }
        }
        getToken[token] = token;
        erc20Token = IUXwapV1BondingCurve(token).getBcTokenAddress();
        getBcToken[token] = erc20Token;
        bondingCurves.push(token);

        emit ContractDeployed(token);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UXwapV1Factory: not feeToSetter");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UXwapV1Factory: not feeToSetter");
        feeToSetter = _feeToSetter;
    }

    function setRouter(address _router) external override {
        require(msg.sender == routerToSetter, "UXwapV1Factory: not routerToSetter");
        router = _router;
    }

    function setRouterToSetter(address _routerToSetter) external override {
        require(msg.sender == routerToSetter, "UXwapV1Factory: not routerToSetter");
        routerToSetter = _routerToSetter;
    }
}