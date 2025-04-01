// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "./interfaces/IUXwapV1Factory.sol";
import "./interfaces/IUXwapV1Router.sol";
import "./UXwapV1BondingCurve.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";
import {CommonBase} from "./libraries/CommonBase.sol";

contract UXwapV1Router is IUXwapV1Router, Ownable, ReentrancyGuard, CommonBase {
    address public factory;

    mapping(address => uint256) private balances;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "UXwapV1Router: EXPIRED");
        _;
    }

    constructor (address _factory) {
        console.log("UXwapV1Router router init.");
        require(_factory != address(0), "UXwapV1Router: Invalid factory address.");
        factory = _factory;
    }
    
    function get() public view returns (address) {  
        return factory;  
    }  

    function createToken(string memory _tokenName, string memory _tokenSymbol,string memory _uri, string memory _description,string memory _telegramLink,string memory _twitterLink,string memory _website)
    external payable nonReentrant returns (address tokenAddress, address erc20TokenAddress) {
        console.log("Create Token in Router.");
        console.log(factory);
        uint256 CreateFee = IUXwapV1Factory(factory).getCreateFee();
        console.log("Create Fee: %s", CreateFee);
        console.log("create token msgSender:",_msgSender());
        require(msg.value > 0, "Must send ETH to create token.");
        require(msg.value > CreateFee, "Should use 0.002 EMC to create token.");
        require(bytes(_tokenName).length > 0, "Token name must not be empty.");
        require(bytes(_tokenSymbol).length > 0, "Token symbol must not be empty.");

        uint256 _initialEthSupply = 2 * 10 ** 18; // 2 ETH
        uint256 _initialTokenSupply = 1 * 10 ** 27; // 1,000,000,000 tokens
        uint256 _minEthThreshold = 1 * 10 ** 10;
        uint256 _minTokenThreshold = 1 * 10 ** 15;
        uint256 _ethFundThreshold = 4 * 10 ** 18;

        balances[_msgSender()] += msg.value;
        balances[_msgSender()] -= CreateFee;

        (bool sent,) = address(IUXwapV1Factory(factory).feeTo()).call{value: CreateFee}("");

        require(sent, "Failed to pay 0.002 Ether");

        (bool success, bytes memory returnData) = factory.call(
            abi.encodeWithSelector(0x05375770,
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

        require(success, "Token creation failed.");
//        (uint256 number, bool flag, address addr) = abi.decode(data, (uint256, bool, address));
        (tokenAddress, erc20TokenAddress) = abi.decode(returnData, (address, address));

        emit TokenCreated(tokenAddress, erc20TokenAddress, _tokenName, _tokenSymbol, _uri,_description,_telegramLink,_twitterLink,_website, msg.sender);

        require(balances[_msgSender()] > 0, "Must send ETH to create token.");
    
        uint256 buyAmount = balances[_msgSender()];
        balances[_msgSender()] = 0; // 更新状态以防止重入
        console.log(balances[_msgSender()]);
        console.log(msg.value);
//        if (afterReduceBalance > 0) {
//            TransferHelper.safeTransferETH(msg.sender, afterReduceBalance);
//            balances[_msgSender()] -= afterReduceBalance;
        _buyToken(tokenAddress, buyAmount);
    }

    function _buyToken(address tokenAddress, uint256 buyEthAmount) internal returns (uint256 amountOut) {

        require(msg.value > 0, "Must send ETH to buy token.");
        require(tokenAddress != address(0), "Invalid token address.");
        require(IUXwapV1Factory(factory).getTokenAddress(tokenAddress) != address(0), "Buy Token address not exist.");
        require(IUXwapV1Factory(factory).getBcTokenAddress(tokenAddress) != address(0), "Buy Bc Token address not exist.");

        // 计算手续费
        uint256 buyFee = (buyEthAmount * IUXwapV1Factory(factory).getFeePercentage()) / 10000;
        uint256 ethForPurchase = buyEthAmount - buyFee;

        (bool sent,) = address(IUXwapV1Factory(factory).feeTo()).call{value: buyFee}("");

        require(sent, "Failed to pay fee");

        require(ethForPurchase > 0, "ETH for purchase must be greater than 0.");

        (bool success, bytes memory returnData) = tokenAddress.call{value: ethForPurchase}(
            abi.encodeWithSelector(0xdb28c763, msg.sender) //buyTokenWithReceiver(address)
//            abi.encodeWithSelector(0xa4821719) //buyToken()
        );
        // transfer to buyer
        require(success, "Buy token in router failed");
        amountOut = abi.decode(returnData, (uint256));
        require(UXwapBondingCurveToken(IUXwapV1Factory(factory).getBcTokenAddress(tokenAddress))
        .transfer(_msgSender(), amountOut), "Transfer failed.");
        emit TokenBought(msg.sender, tokenAddress, ethForPurchase, amountOut);
    }

    function buyToken(
        address tokenAddress,
        uint256 deadline
    ) external payable nonReentrant override ensure(deadline) returns (uint256 amountOut) {
        console.log("buyToken msgSender:",_msgSender());
        require(msg.value > 0, "Must send EMC to buy token.");
        require(tokenAddress != address(0), "Invalid token address.");
        require(IUXwapV1Factory(factory).getTokenAddress(tokenAddress) != address(0), "Buy Token address not exist.");
        require(IUXwapV1Factory(factory).getBcTokenAddress(tokenAddress) != address(0), "Buy Bc Token address not exist.");

        amountOut = _buyToken(tokenAddress, msg.value);
    }

    function sellToken(
        address tokenAddress,
        uint256 amountIn
    ) external nonReentrant override returns (uint256 amountOut) {
        console.log("sellToken msgSender:",_msgSender());
        require(amountIn > 0, "Must sell a positive amount of tokens.");
        require(tokenAddress != address(0), "Invalid token address.");
        require(IUXwapV1Factory(factory).getTokenAddress(tokenAddress) != address(0), "Sell Token address not exist.");
        require(IUXwapV1Factory(factory).getBcTokenAddress(tokenAddress) != address(0), "Sell Bc Token address not exist.");

        address bcTokenAddress = IUXwapV1Factory(factory).getBcTokenAddress(tokenAddress);

        TransferHelper.safeTransferFrom(bcTokenAddress, msg.sender, address(this), amountIn);

        uint256 amountInAfterFee = amountIn;

        TransferHelper.safeApprove(bcTokenAddress, tokenAddress, amountInAfterFee);
        // current eth balance of this contract
        console.log(">>> Router Address EMC Balance = %s", address(this).balance);

        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(0x89ec347f, msg.sender, amountInAfterFee)
        );
        require(success, "Router Token sale failed.");

        amountOut = abi.decode(returnData, (uint256));


        emit TokenSold(msg.sender, tokenAddress, amountIn, amountOut);

        console.log("Router Address Balance Of = %s", UXwapBondingCurveToken(bcTokenAddress).balanceOf(address(this)));
        // current eth balance of this contract
        console.log("<<< Router Address Eth Balance = %s", address(this).balance);

        uint256 sellFee = amountOut * 100 / 10000;

        console.log("Sell Fee = %s", sellFee);
        console.log("Amount Out = %s", amountOut);

        // transfer eth to seller
        TransferHelper.safeTransferETH(msg.sender, amountOut - sellFee);
        // transfer eth to feeTo
        TransferHelper.safeTransferETH(IUXwapV1Factory(factory).feeTo(), sellFee);
    }

    fallback() external payable {
        console.log("UXwap Router Fallback.");
        // todo process transfer of eth to bonding curve
        console.log("Fallback");
        require(msg.value > 0, "Must send EMC to create token.");
    }

    function receiveTokens(address tokenAddress, uint256 amount) external {
        console.log("UXwap Router Receive Tokens.");
        IERC20 token = IERC20(tokenAddress);

        // 确保合约接收代币的代码在代币合约中
        require(token.transfer(address(this), amount), "Transfer failed");

//        emit TokenReceived(msg.sender, amount, tokenAddress);
    }
}