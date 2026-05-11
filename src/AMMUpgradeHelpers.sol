// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/* solhint-disable one-contract-per-file use-natspec func-name-mixedcase no-empty-blocks reason-string gas-small-strings gas-custom-errors avoid-low-level-calls no-inline-assembly gas-calldata-parameters immutable-vars-naming */

/// @title Initializable
/// @author OpenZeppelin
/// @notice Contract for initializing upgradeable contracts.
abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: already initialized");
        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    modifier onlyInitializing() {
        require(_initializing, "Initializable: not initializing");
        _;
    }

    function _disableInitializers() internal {
        require(!_initializing, "Initializable: contract is initializing");
        _initialized = true;
    }
}

/// @title ContextUpgradeable
/// @author OpenZeppelin
/// @notice Provides information about the current execution context.
abstract contract ContextUpgradeable is Initializable {
    /// @notice Initializes the context.
    function __Context_init() internal onlyInitializing {
        return;
    }

    /// @notice Initializes the context without chaining.
    function __Context_init_unchained() internal onlyInitializing {
        return;
    }

    /// @notice Returns the message sender.
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /// @notice Returns the message data.
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library AddressUpgradeable {
    /// @notice Checks if an account is a contract.
    /// @param account The address to check.
    /// @return True if the account is a contract.
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /// @notice Performs a delegate call with default error message.
    /// @param target The target contract.
    /// @param data The call data.
    /// @return The return data.
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /// @notice Performs a delegate call with custom error message.
    /// @param target The target contract.
    /// @param data The call data.
    /// @param errorMessage The error message on failure.
    /// @return The return data.
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /// @notice Verifies the result of a call.
    /// @param success Whether the call succeeded.
    /// @param returndata The return data.
    /// @param errorMessage The error message on failure.
    /// @return The return data if successful.
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage)
        internal
        pure
        returns (bytes memory)
    {
        if (success) {
            return returndata;
        }
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/// @title StorageSlotUpgradeable
/// @author OpenZeppelin
/// @notice Library for reading and writing to arbitrary storage slots.
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    /// @notice Gets an address slot.
    /// @param slot The slot.
    /// @return r The address slot.
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /// @notice Gets a boolean slot.
    /// @param slot The slot.
    /// @return r The boolean slot.
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

abstract contract ERC1967UpgradeUpgradeable is Initializable {
    bytes32 internal constant _ROLLBACK_SLOT = bytes32(uint256(keccak256("eip1967.proxy.rollback")) - 1);
    bytes32 internal constant _IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    /// @notice Emitted when the implementation is upgraded.
    /// @param implementation The new implementation address.
    event Upgraded(address indexed implementation);

    /// @notice Initializes the ERC1967 upgrade.
    function __ERC1967Upgrade_init() internal onlyInitializing {
        return;
    }

    /// @notice Gets the current implementation address.
    /// @return The implementation address.
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /// @notice Sets the implementation address.
    /// @param newImplementation The new implementation address.
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /// @notice Upgrades to a new implementation.
    /// @param newImplementation The new implementation address.
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /// @notice Upgrades to a new implementation and calls it securely.
    /// @param newImplementation The new implementation address.
    /// @param data The call data.
    /// @param forceCall Whether to force the call.
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();
        _setImplementation(newImplementation);
        if (forceCall && data.length > 0) {
            _functionDelegateCall(newImplementation, data);
        }

        if (!StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value = true;
            _functionDelegateCall(newImplementation, abi.encodeWithSignature("upgradeTo(address)", oldImplementation));
            StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value = false;
            require(_getImplementation() == oldImplementation, "ERC1967: upgrade breaks further upgrades");
            _upgradeTo(newImplementation);
        }
    }

    /// @notice Performs a delegate call for upgrading.
    /// @param target The target address.
    /// @param data The call data.
    /// @return The return data.
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        return AddressUpgradeable.functionDelegateCall(target, data, "ERC1967: delegate call failed");
    }
}

interface IERC1822ProxiableUpgradeable {
    /// @notice Returns the UUID of the proxiable contract.
    /// @return The UUID.
    function proxiableUUID() external view returns (bytes32);
}

/// @title UUPSUpgradeable
/// @author OpenZeppelin
/// @notice Contract for upgradeable contracts using UUPS pattern.
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    address private immutable __self = address(this);

    modifier onlyProxy() {
        require(address(this) != __self, "UUPSUpgradeable: must be called through delegatecall");
        require(_getImplementation() == __self, "UUPSUpgradeable: must be called through active proxy");
        _;
    }

    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /// @notice Initializes the UUPS upgradeable contract.
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init();
    }

    /// @notice Upgrades the contract to a new implementation.
    /// @param newImplementation The new implementation address.
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /// @notice Upgrades the contract and calls a function.
    /// @param newImplementation The new implementation address.
    /// @param data The call data.
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /// @notice Returns the UUID for UUPS.
    /// @return The UUID.
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    /// @notice Emitted when ownership is transferred.
    /// @param previousOwner The previous owner.
    /// @param newOwner The new owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Initializes the ownable contract.
    function __Ownable_init() internal onlyInitializing {
        __Context_init();
        __Ownable_init_unchained();
    }

    /// @notice Initializes the ownable contract without chaining.
    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /// @notice Returns the current owner.
    /// @return The owner address.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /// @notice Renounces ownership.
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /// @notice Transfers ownership to a new owner.
    /// @param newOwner The new owner address.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /// @notice Transfers ownership internally.
    /// @param newOwner The new owner address.
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    address private _pendingOwner;

    /// @notice Emitted when ownership transfer is started.
    /// @param previousOwner The current owner.
    /// @param newOwner The pending owner.
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /// @notice Initializes the 2-step ownable contract.
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    /// @notice Returns the pending owner.
    /// @return The pending owner address.
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /// @notice Starts ownership transfer.
    /// @param newOwner The new owner address.
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable2Step: new owner is the zero address");
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /// @notice Accepts ownership transfer.
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(sender == _pendingOwner, "Ownable2Step: caller is not the pending owner");
        _pendingOwner = address(0);
        _transferOwnership(sender);
    }

    uint256[49] private __gap;
}

/// @title ReentrancyGuardUpgradeable
/// @author OpenZeppelin
/// @notice Contract to prevent reentrancy attacks.
abstract contract ReentrancyGuardUpgradeable is Initializable {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /// @notice Initializes the reentrancy guard.
    function __ReentrancyGuard_init() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    uint256[49] private __gap;
}

/// @title ReentrancyGuard
/// @author OpenZeppelin
/// @notice Contract to prevent reentrancy attacks.
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
