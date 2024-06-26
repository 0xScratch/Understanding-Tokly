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

pragma solidity ^0.8.11;

import "./ToklyRegistry.sol";
import "./ToklyFees.sol";
import "../interfaces/IToklyContract.sol";

import '../utils/Pausable.sol';
import '../utils/Withdrawable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title Tokly Factory
 * @author Khiza DAO
 * @dev This contract is responsible for creating and managing contract implementations and proxies for the Tokly dapp.
 */
contract ToklyFactory is Ownable, Pausable, Withdrawable, ToklyFees {
    ToklyRegistry public immutable registry;

    string public constant toklyVersion = "v0.2.0";

    /// @dev Emitted when a proxy is deployed.
    event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);
    event ImplementationAdded(address implementation, bytes32 indexed contractType, uint256 version);
    event ImplementationApproved(address implementation, bool isApproved);

    /// @dev mapping of implementation address to deployment approval
    mapping(address => bool) public approval;

    /// @dev mapping of implementation address to implementation added version
    mapping(bytes32 => uint256) public currentVersion;

    /// @dev mapping of contract type to module version to implementation address
    mapping(bytes32 => mapping(uint256 => address)) public implementation;

    constructor(address _registry) {
        registry = ToklyRegistry(_registry);
    }

    /// @dev Deploys a proxy that points to the latest version of the given contract type.
    function deployProxy(bytes32 _type, bytes memory _data) external payable returns (address) {
        bytes32 salt = bytes32(registry.count(_msgSender()));
        return deployProxyDeterministic(_type, _data, salt);
    }

    /**
     *  @dev Deploys a proxy at a deterministic address by taking in `salt` as a parameter.
     *       Proxy points to the latest version of the given contract type.
     */
    function deployProxyDeterministic(
        bytes32 _type,
        bytes memory _data,
        bytes32 _salt
    ) public payable returns (address) {
        address _implementation = getLatestImplementation(_type);
        return deployProxyByImplementation(_implementation, _data, _salt);
    }

    /// @dev Deploys a proxy that points to the given implementation.
    function deployProxyByImplementation(
        address _implementation,
        bytes memory _data,
        bytes32 _salt
    ) public payable notPaused returns (address deployedProxy) {
        require(approval[_implementation], "implementation not approved");

        // Check fee
        bytes32 ctype = IToklyContract(_implementation).contractType();
        _checkFee(ctype);

        bytes32 salthash = keccak256(abi.encodePacked(_msgSender(), _salt));
        deployedProxy = Clones.cloneDeterministic(_implementation, salthash);

        emit ProxyDeployed(_implementation, deployedProxy, _msgSender());

        registry.add(_msgSender(), deployedProxy);

        if (_data.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCall(deployedProxy, _data);
        }
    }

    /// @dev Lets a contract admin set the address of a contract type x version.
    function addImplementation(address _implementation) notPaused onlyOwner external {
        IToklyContract module = IToklyContract(_implementation);

        bytes32 ctype = module.contractType();
        require(ctype.length > 0, "invalid module");

        uint8 version = module.contractVersion();
        uint8 currentVersionOfType = uint8(currentVersion[ctype]);
        require(version >= currentVersionOfType, "wrong module version");

        currentVersion[ctype] = version;
        implementation[ctype][version] = _implementation;
        approval[_implementation] = true;

        emit ImplementationAdded(_implementation, ctype, version);
    }

    /// @dev Lets a contract admin approve a specific contract for deployment.
    function approveImplementation(address _implementation, bool _toApprove) notPaused onlyOwner external {
        approval[_implementation] = _toApprove;

        emit ImplementationApproved(_implementation, _toApprove);
    }

    /// @dev Returns the implementation given a contract type and version.
    function getImplementation(bytes32 _type, uint256 _version) external view returns (address) {
        return implementation[_type][_version];
    }

    /// @dev Returns the latest implementation given a contract type.
    function getLatestImplementation(bytes32 _type) public view returns (address) {
        return implementation[_type][currentVersion[_type]];
    }

    /// @dev Returns the address of the next proxy to be deployed by an address based on the number of proxies they have deployed.
    function predictProxyDeterministicAddress(address _implementation, address _sender) public view returns (address) {
        bytes32 _salt = bytes32(registry.count(_sender));
        bytes32 salthash = keccak256(abi.encodePacked(_sender, _salt));
        return Clones.predictDeterministicAddress(_implementation, salthash);
    }

    /// @dev Returns the address of the next proxy to be deployed by an address based on the number of proxies they have deployed.
    function predictProxyTypeDeterministicAddress(bytes32 _type, address _sender) external view returns (address) {
        address _implementation = getLatestImplementation(_type);
        return predictProxyDeterministicAddress(_implementation, _sender);
    }
}