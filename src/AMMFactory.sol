// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./AMMUpgradeHelpers.sol";
import "./AMMPair.sol";

contract AMMFactory is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    address public feeRecipient;

    bytes32 public constant PAIR_INIT_CODE_HASH = keccak256(type(AMMPair).creationCode);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 index);
    event PairCreatedFallback(address indexed token0, address indexed token1, address pair, uint256 index);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    function initialize(address owner_) external initializer {
        if (owner_ == address(0)) {
            owner_ = _msgSender();
        }
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        if (owner_ != _msgSender()) {
            transferOwnership(owner_);
        }

        feeRecipient = owner_;
    }
}