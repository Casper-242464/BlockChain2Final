// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {
    Initializable,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable
} from "./AMMUpgradeHelpers.sol";
import {AMMPair} from "./AMMPair.sol";

/* solhint-disable gas-custom-errors gas-indexed-events */
/// @title AMM Factory
/// @author anonymous
/// @notice Factory contract for creating and managing AMM pairs.
contract AMMFactory is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Mapping from token pair to pair contract address.
    mapping(address => mapping(address => address)) public getPair;
    /// @notice All created pair addresses.
    address[] public allPairs;
    /// @notice Address that receives protocol fees.
    address public feeRecipient;

    /// @notice Hash of the AMMPair contract init code.
    bytes32 public constant PAIR_INIT_CODE_HASH = keccak256(type(AMMPair).creationCode);

    /// @notice Emitted when a pair is created using CREATE2.
    /// @param token0 The first token for the created pair.
    /// @param token1 The second token for the created pair.
    /// @param pair The created pair address.
    /// @param index The index in the allPairs array.
    event PairCreated(address indexed token0, address indexed token1, address indexed pair, uint256 index);
    /// @notice Emitted when a pair is created using CREATE.
    /// @param token0 The first token for the created pair.
    /// @param token1 The second token for the created pair.
    /// @param pair The created pair address.
    /// @param index The index in the allPairs array.
    event PairCreatedFallback(address indexed token0, address indexed token1, address indexed pair, uint256 index);
    /// @notice Emitted when the fee recipient is updated.
    /// @param oldRecipient The previous fee recipient.
    /// @param newRecipient The new fee recipient.
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the factory with an owner.
    /// @param owner_ The owner address.
    function initialize(address owner_) external initializer {
        require(owner_ != address(0), "AMMFactory: ZERO_ADDRESS");
        require(_msgSender() == owner_, "AMMFactory: UNAUTHORIZED");

        __Ownable2Step_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _transferOwnership(owner_);
        feeRecipient = owner_;
    }

    /// @notice Create a new pair using CREATE2.
    /// @param tokenA First token address.
    /// @param tokenB Second token address.
    /// @return pair The new pair address.
    function createPair(address tokenA, address tokenB) external nonReentrant returns (address pair) {
        return createPairCreate2(tokenA, tokenB);
    }

    /// @notice Create a pair using CREATE2 with sorted token ordering.
    /// @param tokenA First token address.
    /// @param tokenB Second token address.
    /// @return pair The new pair address.
    function createPairCreate2(address tokenA, address tokenB) public nonReentrant returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        require(token0 != token1, "AMMFactory: IDENTICAL_ADDRESSES");
        require(token0 != address(0), "AMMFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "AMMFactory: PAIR_EXISTS");

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new AMMPair{salt: salt}(token0, token1, address(this)));

        _registerPair(token0, token1, pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /// @notice Create a new pair using regular CREATE.
    /// @param tokenA First token address.
    /// @param tokenB Second token address.
    /// @return pair The new pair address.
    function createPairCreate(address tokenA, address tokenB) external nonReentrant returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        require(token0 != token1, "AMMFactory: IDENTICAL_ADDRESSES");
        require(token0 != address(0), "AMMFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "AMMFactory: PAIR_EXISTS");

        pair = address(new AMMPair(token0, token1, address(this)));

        _registerPair(token0, token1, pair);
        emit PairCreatedFallback(token0, token1, pair, allPairs.length);
    }

    /// @notice Predict the pair address for two tokens.
    /// @param tokenA First token address.
    /// @param tokenB Second token address.
    /// @return predicted The deterministic pair address.
    function pairFor(address tokenA, address tokenB) external view returns (address predicted) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes32 rawAddress = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(abi.encodePacked(type(AMMPair).creationCode, abi.encode(token0, token1, address(this))))
            )
        );
        predicted = address(uint160(uint256(rawAddress)));
    }

    /// @notice Update the fee recipient address.
    /// @param newRecipient The new fee recipient.
    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "AMMFactory: ZERO_ADDRESS");
        emit FeeRecipientUpdated(feeRecipient, newRecipient);
        feeRecipient = newRecipient;
    }

    /// @notice Return the number of pairs created by the factory.
    /// @return The number of pairs.
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    /// @notice Sort token addresses to ensure consistent ordering.
    /// @param tokenA First token address.
    /// @param tokenB Second token address.
    /// @return token0 The first token after sorting.
    /// @return token1 The second token after sorting.
    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "AMMFactory: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function _registerPair(address token0, address token1, address pair) internal {
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {
        return;
    }

    uint256[45] private __gap;
}
