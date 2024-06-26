// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Tokly Fees
 * @author Khiza DAO
 * @dev This contract is responsible for storing and managing the fees for the Tokly dapp.
 */
contract ToklyFees is Ownable {
    mapping(bytes32 => uint) public fees;

    /// @dev Returns the fee for a given contract type.
    function getFeeFor(bytes32 _type) public view returns (uint) {
        return fees[_type];
    }

    /// @dev Returns the fee for a given contract type.
    function setFeeFor(bytes32 _type, uint _fee) onlyOwner public {
        fees[_type] = _fee;
    }

    function _checkFee(bytes32 _type) internal {
        require(msg.value >= getFeeFor(_type), "ToklyFees: Insufficient value");
    }

    // Not being used for now
    // modifier requiresFee(bytes32 _type) {
    //     _checkFee(_type);
    //     _;
    // }
}