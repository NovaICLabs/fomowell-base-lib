// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BondingCurveLibrary {
    function calculateK(uint256 initialEthSupply, uint256 initialTokenSupply) internal pure returns (uint256) {
        return initialEthSupply * initialTokenSupply;
    }

    function safeDivide(uint256 dividend, uint256 divisor) internal pure returns (uint256) {
        require(divisor > 0, "Divisor cannot be zero");
        uint256 quotient = 0;
        uint256 tempDividend = dividend;
        uint256 tempDivisor = divisor;

        while (tempDividend >= tempDivisor) {
            uint256 temp = tempDivisor;
            uint256 multiple = 1;

            while (tempDividend >= (temp << 1)) {
                temp <<= 1;
                multiple <<= 1;
            }

            tempDividend -= temp;
            quotient += multiple;
        }

        return quotient;
    }
}