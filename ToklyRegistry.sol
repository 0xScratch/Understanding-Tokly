// SPDX-License-Identifier: Apache-2.0

/*
 ________         __        __           
/        |       /  |      /  |          
$$$$$$$$/______  $$ |   __ $$ | __    __ 
   $$ | /      \ $$ |  /  |$$ |/  |  /  |
   $$ |/$$$$$$  |$$ |_/$$/ $$ |$$ |  $$ |
   $$ |$$ |  $$ |$$   $$<  $$ |$$ |  $$ |
   $$ |$$ \__$$ |$$$$$$  \ $$ |$$ \__$$ |
   $$ |$$    $$/ $$ | $$  |$$ |$$    $$ |
   $$/  $$$$$$/  $$/   $$/ $$/  $$$$$$$ |
                               /  \__$$ |
                               $$    $$/ 
                                $$$$$$/  
*/

// [TODO]: Credit ThirdWeb

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Tokly Registry
 * @author Khiza DAO
 * @dev This contract is responsible for storing contract addresses that were deployed by the Tokly dapp.
 */
contract ToklyRegistry is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    address public operator;

    /// @dev wallet address => [contract addresses]
    mapping(address => EnumerableSet.AddressSet) private deployments;
    /// @dev mapping of proxy address to deployer address
    mapping(address => address) public deployer;

    event Added(address indexed deployer, address indexed deployment);
    event Deleted(address indexed deployer, address indexed deployment);

    constructor(address _operator) Ownable(_operator) {
        operator = _operator;
    }

    function setOperator(address _operator) onlyOwner external {
        operator = _operator;
    }

    function add(address _deployer, address _deployment) onlyOperator external {
        require(_deployment.code.length > 0, 'Deployment is not a contract.');
        bool added = deployments[_deployer].add(_deployment);
        require(added, "failed to add");

        deployer[_deployment] = _deployer;

        emit Added(_deployer, _deployment);
    }

    function remove(address _deployer, address _deployment) onlyOperator external {
        bool removed = deployments[_deployer].remove(_deployment);
        require(removed, "failed to remove");

        deployer[_deployment] = address(0);

        emit Deleted(_deployer, _deployment);
    }

    function getAll(address _deployer) external view returns (address[] memory) {
        return deployments[_deployer].values();
    }

    function count(address _deployer) external view returns (uint256) {
        return deployments[_deployer].length();
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "ToklyRegistry: caller is not the operator");
        _;
    }
}