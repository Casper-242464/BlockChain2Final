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

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "AMMPair: TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");
        allowance[from][msg.sender] = allowed - value;
        _transfer(from, to, value);
        return true;
    }

    function getReserves() public view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    function addLiquidity(uint256 amount0, uint256 amount1, address to) external nonReentrant returns (uint256 liquidity) {
        require(amount0 > 0 && amount1 > 0, "AMMPair: INSUFFICIENT_AMOUNT");

        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0Added = balance0 - reserve0;
        uint256 amount1Added = balance1 - reserve1;

        if (totalSupply == 0) {
            uint256 root = sqrt(amount0Added * amount1Added);
            liquidity = root - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            uint256 liquidity0 = (amount0Added * totalSupply) / reserve0;
            uint256 liquidity1 = (amount1Added * totalSupply) / reserve1;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        }

        require(liquidity > 0, "AMMPair: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);
        _update(balance0, balance1);

        emit Mint(msg.sender, amount0Added, amount1Added);
    }

    function removeLiquidity(uint256 liquidity, address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(liquidity > 0, "AMMPair: INSUFFICIENT_LIQUIDITY_BURNED");

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        amount0 = (liquidity * balance0) / totalSupply;
        amount1 = (liquidity * balance1) / totalSupply;

        require(amount0 > 0 && amount1 > 0, "AMMPair: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(msg.sender, liquidity);

        IERC20(token0).transfer(to, amount0);
        IERC20(token1).transfer(to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1);
        emit Burn(msg.sender, to, amount0, amount1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "AMMPair: INSUFFICIENT_OUTPUT_AMOUNT");
        require(to != address(0), "AMMPair: INVALID_TO");

        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "AMMPair: INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) {
            IERC20(token0).transfer(to, amount0Out);
        }
        if (amount1Out > 0) {
            IERC20(token1).transfer(to, amount1Out);
        }

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "AMMPair: INSUFFICIENT_INPUT_AMOUNT");

        require(balance0 * balance1 >= _reserve0 * _reserve1, "AMMPair: K");
        _update(balance0, balance1);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

}