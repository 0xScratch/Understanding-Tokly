// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract IToklyContract is Initializable {
    function contractType() public virtual returns (bytes32);
    function contractVersion() public virtual returns (uint8);
    // function initialize() public virtual; // and must have the `initializer` modifier
}