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

    function createPair(address tokenA, address tokenB) external nonReentrant returns (address pair) {
        return createPairCreate2(tokenA, tokenB);
    }

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

    function createPairCreate(address tokenA, address tokenB) external nonReentrant returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        require(token0 != token1, "AMMFactory: IDENTICAL_ADDRESSES");
        require(token0 != address(0), "AMMFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "AMMFactory: PAIR_EXISTS");

        pair = address(new AMMPair(token0, token1, address(this)));

        _registerPair(token0, token1, pair);
        emit PairCreatedFallback(token0, token1, pair, allPairs.length);
    }

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

    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "AMMFactory: ZERO_ADDRESS");
        emit FeeRecipientUpdated(feeRecipient, newRecipient);
        feeRecipient = newRecipient;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "AMMFactory: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function _registerPair(address token0, address token1, address pair) internal {
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[45] private __gap;
}
