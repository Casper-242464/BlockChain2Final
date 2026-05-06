// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/interfaces/IERC20.sol";
import "./AMMUpgradeHelpers.sol";

contract AMMPair is ReentrancyGuard {
    address public immutable token0;
    address public immutable token1;
    address public immutable factory;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private reserve0;
    uint256 private reserve1;

    string public constant name = "DeFi Super-App LP Token";
    string public constant symbol = "DSL";
    uint8 public constant decimals = 18;
    uint256 public constant MINIMUM_LIQUIDITY = 1_000;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, address indexed to, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor(address _token0, address _token1, address _factory) {
        require(_token0 != _token1, "AMMPair: IDENTICAL_ADDRESSES");
        require(_token0 != address(0) && _token1 != address(0), "AMMPair: ZERO_ADDRESS");
        token0 = _token0;
        token1 = _token1;
        factory = _factory;
    }
}