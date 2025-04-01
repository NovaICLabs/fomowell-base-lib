## Introduction
UXwap is a DEFI exchange based on bonding curve theory, it used a virtual initial liquidity
pool to avoid the initial liquidity pool problem. The bonding curve is a mathematical curve.

## Installation
The project use hardhat to compile and deploy the smart contract, you can install hardhat by npm:

```
$ npm install hardhat
```

Router and Factory are the UniswapV2Router02 and UniswapV2Factory contract address, 
you can get the address from the UniswapV2Router02 and UniswapV2Factory contract.

Periphery:

UXwapV1Router :
  Buy and Sell MemeToken, add to the Uniswap Pair.


Core:
UXwapV1Pair :
   Management MemeToken Liquidity Pool, Buy and Sell MemeToken, add to the Uniswap Pair.
UXwapV1Factory :
  Create MemeToken and BondingCurveToken pair, and add liquidity to the pair.
UXwapV1ERC20 :
  MemeToken and BondingCurveToken contract.


## Design

Factory
  Mint BCToken and MemeToken pair, and add liquidity to the pair.
  Fee Address: 0x
  Uniswap Factory Address: 0x
  Uniswap Router Address: 0x
  Liquidity Threshold: 1000000000000000000 

Router 
  Call All Swap function, and add liquidity to the pair.
  Call Mint New Token, Buy Token, Sell Token.
    Mint Token : Factory
    Buy Token : BondingCurve
    Sell Token : BondingCurve

BondingCurve
  Only For Router
  Buy & Sell BCToken, and calculate the price of the BCToken.
  
  Sync Data
  get Reserves Data



## Usage

There are 4 roles can use the contract:  
* Owner
  * Update the Fee Address
  * Update the Uniswap Factory & Router Address
  * Update the liquidity threshold and liquidity ratio

* Meme Founder
  * call Mint function to mint a new token
  * Mint with Buy function to mint a new token and buy it

* Meme Trader
  * call Buy function to buy a token
  * call Sell function to sell a token

* Contract
  * Mint a new Uniswap Pair
  * Add liquidity to the Uniswap Pair






