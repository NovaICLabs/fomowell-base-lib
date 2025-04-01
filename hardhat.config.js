require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-defender');
require("hardhat-contract-sizer");


task("accounts", "Prints the list of accounts", async (_, { ethers }) => {
    const accounts = await ethers.getSigners();

    for (const account of accounts) {
        console.log("Hardhat Address: ", await account.getAddress());
    }
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
      viaIR: true,
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    ignitions: {
      module: './ignition/modules/UXwapV1Factory.js',
    },
    defender: {
      apiKey: '',
      apiSecret: '',
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: true,
    strict: true,
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    base: {
      name: "base",
      url: 'https://mainnet.base.org',
      chainId: 8453,
      explorer: "https://sepolia.basescan.org/",
      accounts: [""],
      ignition: {
        maxFeePerGasLimit: 50_000_000_000n, // 50 gwei
        maxPriorityFeePerGas: 2_000_000n, // 2 gwei
      },
    },
    base_sepolia: {
      name: "base-sepolia",
      url: "https://sepolia.base.org",
      chainId: 84532,
      explorer: "https://base-sepolia.blockscout.com",
      accounts: [""],
      ignition: {
        maxFeePerGasLimit: 50_000_000_000n, // 50 gwei
        maxPriorityFeePerGas: 2_000_000n, // 2 gwei
      },
    },
  },
  dependencyCompiler: {
    paths: [
      "@openzeppelin/contracts/token/ERC20/ERC20.sol",
      "@openzeppelin/contracts/token/ERC20/IERC20.sol",
      "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol",
      "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol",
      "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol",
      "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol",
      "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol",
      "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol",
      "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol",
      "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol",
      "@openzeppelin/contracts/token/ERC721/ERC721.sol",
      "@openzeppelin/contracts/token/ERC721/IERC721.sol",
      "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol",
      "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol",
      "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol",
      "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol",
      "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol",
      "@openzeppelin/contracts/token/ERC777/ERC777.sol",
      "@openzeppelin/contracts/token/ERC777/IERC777.sol",
      "@openzeppelin/contracts/token/ERC777/extensions/IERC777Recipient.sol",
      "@openzeppelin/contracts/token/ERC777/extensions/IERC777Sender.sol",
      "@openzeppelin/contracts/token/ERC777/extensions/ERC777Burnable.sol",
      "@openzeppelin/contracts/token/ERC777/extensions/ERC777Pausable.sol",
      "@openzeppelin/contracts/access/AccessControl.sol",
      "@openzeppelin/contracts/access/IAccessControl.sol",
      "@openzeppelin/contracts/access/Ownable.sol",
      "@openzeppelin/contracts/access/Context.sol",
      'solmate/src/tokens/WETH.sol',
    ],
  }
};
