// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract UXwapBondingCurveToken is ERC20, Ownable {
    address public blockedPairAddress;

//    metadata json stored in ipfs
    string private contractURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 _initialTokenSupply
)
    ERC20(name, symbol)
    Ownable(_msgSender())
    {
        console.log("UXwapBondingCurveToken Msg Sender is %s",_msgSender());
        console.log("total supply is %s", _initialTokenSupply);
        contractURI = uri;
        _mint(_msgSender(), _initialTokenSupply);
        console.log("ERC20 Token Contract Created.");
        contractURI = "https://gateway.pinata.cloud/ipfs/QmZQ6";
    }

//    function _update(address from, address to, uint256 value) internal override {
//        require(from != blockedPairAddress, "UXwapBCToken: cannot add liquidity now");
//        require(to != blockedPairAddress, "UXwapBCToken: cannot add liquidity now");
//        super._update(from, to, value);
//    }

    function setBlockedPairAddress(address pairAddress) public onlyOwner returns (address) {
        address oldPairAddress = blockedPairAddress;
        blockedPairAddress = pairAddress;
        return oldPairAddress;
    }

    function setContractURI(string memory uri) external onlyOwner {
        contractURI = uri;
    }

    function getContractURI() external view returns (string memory) {
        return contractURI;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

}
