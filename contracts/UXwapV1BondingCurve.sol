// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./UXwapBondingCurveToken.sol";
import "./libraries/BondingCurveLibrary.sol";
import "./interfaces/IUXwapV1BondingCurve.sol";

contract UXwapV1BondingCurve is IUXwapV1BondingCurve, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public router;
    address public uniswapRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public uniswapFactoryAddress = 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6;
    address public WETHAddress = 0x4200000000000000000000000000000000000006;

    uint256 public constant TOTAL_SUPPLY = 10 * 10 ** 9 * 10 ** 18;
    uint256 public constant AVAILABLE_SUPPLY = 8 * 10 ** 9 * 10 ** 18;

    string public name;
    uint256 public initialEthSupply;
    uint256 public initialTokenSupply;
    uint256 public k;
    uint256 public availableEthSupply;
    uint256 public availableTokenSupply;
    uint256 public minEthThreshold;
    uint256 public minTokenThreshold;
    uint256 public ethFundThreshold;
    UXwapBondingCurveToken public token;
    address public uniswapPairAddress;
    bool public isPaused;


//    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
//    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves



    event FundThresholdReached(uint256 fundPool);
    event MintPairOnUniswap(address indexed token);
    event AddLiquidityOnUniswap(address indexed pairAddress, address indexed tokenAddress, uint256 ethAmount, uint256 tokenAmount);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event TokenWithdrawn(address indexed token, address indexed to, uint256 amount);
    event EmergencyWithdrawn(address indexed admin, address indexed to, uint256 amount);

    modifier onlyRouter() {
        require(_msgSender() == router, "UXwap: Only router can call this function.");
        _;
    }

    constructor(
        address _router,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uri,
        uint256 _initialEthSupply,
        uint256 _initialTokenSupply,
        uint256 _minEthThreshold,
        uint256 _minTokenThreshold,
        uint256 _ethFundThreshold
    ) Ownable(_msgSender()) {
        require(_router != address(0), "Invalid router address.");
        console.log("bondingcurve constructor msgSender:",_msgSender());
        router = _router;
        initialEthSupply = _initialEthSupply;
        initialTokenSupply = _initialTokenSupply;
        k = BondingCurveLibrary.calculateK(_initialEthSupply, _initialTokenSupply);
        availableEthSupply = _initialEthSupply;
        availableTokenSupply = _initialTokenSupply;
        minEthThreshold = _minEthThreshold;
        minTokenThreshold = _minTokenThreshold;
        token = new UXwapBondingCurveToken(_tokenName, _tokenSymbol,_uri, _initialTokenSupply);
        ethFundThreshold = _ethFundThreshold;

        emit MintToken(_tokenName, _tokenSymbol, _initialTokenSupply, address(token), owner());

        _update();
//        emit Sync(address(token),
//        _getERC20TokenBalance(address(token)),
//        address(this).balance, availableTokenSupply, availableEthSupply);
    }

    function buyTokenWithReceiver(address to) public payable override returns (uint256 amountOut) {
        require(!isPaused, "Bonding curve phase ended");
        require(msg.value > 0, "Must send EMC to buy token.");
        console.log("buyTokenWithReceiver msgSender:",_msgSender());
        uint256 x_after = availableEthSupply + msg.value;
        uint256 y_after = BondingCurveLibrary.safeDivide(k, x_after);
        uint256 bc_received = availableTokenSupply - y_after;
        require(token.transfer(_msgSender(), bc_received), "Transfer failed.");

        availableEthSupply += msg.value;
        availableTokenSupply -= bc_received;
        require(availableEthSupply <= ethFundThreshold, "Max EMC amount reached");
        emit TokenBought(to, msg.value, bc_received);
        _update();
//        emit Sync(address(token),
//            _getERC20TokenBalance(address(token)),
//            address(this).balance, availableTokenSupply, availableEthSupply);

        if (availableEthSupply >= ethFundThreshold) {
            _createTokenPair();
            emit FundThresholdReached(availableEthSupply);
        }
        amountOut = bc_received;
    }

    function sellTokenWithSenderAndReceiver(address seller, uint256 sellTokenAmount) public payable override returns (uint256 amountOut) {
        console.log("sell Token in bonding curve.");
        require(!isPaused, "Bonding curve phase ended");
        require(sellTokenAmount > 0, "Must send token to sell.");
        require(token.approve(address(this), sellTokenAmount), "Approved failed.");
        console.log("sellTokenWithSenderAndReceiver msgSender:",_msgSender());
        uint256 balanceBondingCurveToken = IERC20(token).balanceOf(address(_msgSender()));
        console.log("balanceBondingCurveToken:",balanceBondingCurveToken);
        // require(token.transferFrom(address(_msgSender()), address(this), sellTokenAmount), "Transfer failed.");
        // require(balanceBondingCurveToken >= minTokenThreshold, "Not enough Token B");
        // require((sellTokenAmount + availableTokenSupply) <= initialTokenSupply, "Value token amount exceeds total supply.");

        uint256 y_new = availableTokenSupply + sellTokenAmount;
        uint256 x = availableEthSupply - BondingCurveLibrary.safeDivide(k, y_new);

        require(this.getEtherBalance() >= x, "Insufficient funds");
        console.log("send eth:");
        (bool sentEthResult,) = payable(_msgSender()).call{value: x}("");
        console.log("sentEthResult:",sentEthResult);
        require(sentEthResult, "EMC transfer failed.");

        availableTokenSupply += sellTokenAmount;
        availableEthSupply -= x;

        emit TokenSold(seller, sellTokenAmount, x);
        _update();
//        emit Sync(address(token),
//            _getERC20TokenBalance(address(token)),
//            address(this).balance, availableTokenSupply, availableEthSupply);

        amountOut = x;
    }

    function _createTokenPair() internal {
        console.log("_createTokenPair");
        isPaused = true;
        IERC20(token).approve(uniswapRouterAddress, IERC20(token).balanceOf(address(token)));
        IUniswapV2Router01(uniswapRouterAddress).addLiquidityETH{value: address(this).balance}(
            address(this), IERC20(token).balanceOf(address(this)), 0, 0, address(0), block.timestamp
        );
        console.log("_createTokenPair in uniswap success! ");
        
        emit MintPairOnUniswap(address(token));
    }

    function withdrawEther(uint256 amount, address payable to) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
        emit EtherWithdrawn(to, amount);
    }

    function _getERC20TokenBalance(address tokenAddress) internal view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getBcTokenAddress() external view returns (address){
        return address(token);
    }

    function getAvailableTokenSupply() external view returns (uint256) {
        return availableTokenSupply;
    }

    function getAvailableEthSupply() external view returns (uint256) {
        return availableEthSupply;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update() private {
//        require(balance0 <= -1) && balance1 <= -1, 'UXwapV1: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        // uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
//        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
//            // * never overflows, and + overflow is desired
//            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
//            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
//        }
//        reserve0 = uint112(balance0);
//        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(availableEthSupply, availableTokenSupply);
    }

    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = availableEthSupply;
        _reserve1 = availableTokenSupply;
        _blockTimestampLast = blockTimestampLast;
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }
}
