# Gas Optimization Report — AMM Mathematical Core

**Subject:** Comparative Analysis of Yul Assembly vs. Solidity Square Root  
**Target Component:** `AMMPair.sol` / `MathUtils`  

## 1. Introduction
In Automated Market Makers, the `sqrt` function is a critical path for calculating initial liquidity minting and ensuring the $x \cdot y = k$ invariant. Standard Solidity implementations incur overhead due to implicit safety checks (Panic checks) introduced in version 0.8.x. This report details the gas savings achieved by implementing the Babylonean Method in Yul assembly.

## 2. Methodology
Benchmarks were conducted using `forge snapshot` within the local Foundry environment.
* **Solidity Version:** 0.8.24
* **Optimizer:** Enabled (200 runs)
* **Input Value ($y$):** $10^{18}$

## 3. Implementation Comparison

### 3.1 Solidity Implementation (Baseline)
The high-level Solidity implementation includes checks for division by zero and overflows which are redundant for this iterative algorithm.

### 3.2 Yul Implementation (Optimized)
The Yul implementation bypasses the Solidity stack management and safety wrappers, executing raw opcodes for the division and addition loops.

## 4. Benchmarks & Results

The following data was extracted from the project's `.gas-snapshot`:

| Test Case | Gas Usage | Status |
| :--- | :--- | :--- |
| `test_Gas_Solidity_Sqrt()` | 8,833 | Baseline |
| `test_Gas_Yul_Sqrt()` | 2,529 | Optimized |

### Key Metrics:
* **Absolute Savings:** 6,304 Gas per call.
* **Efficiency Increase:** ~71.3% reduction in execution cost.

## 5. Technical Analysis
The significant 71% improvement is attributed to three factors:
1. **Bypassing 0.8.x Overflow Checks:** Solidity 0.8+ adds `Panic` check opcodes to every addition and division. In our controlled loop, these are unnecessary.
2. **Stack Optimization:** Yul allows us to keep variables in specific stack positions, reducing the number of `DUP` and `SWAP` opcodes required.
3. **Conditional Logic:** The Yul version uses a more efficient loop structure that terminates immediately once the convergence criteria is met, without the overhead of high-level Solidity function epilogues.

## 6. Project Integration
Based on these results, the `sqrt` function in `src/AMMPair.sol` has been updated to use the Yul implementation.

```solidity
function sqrt(uint256 y) internal pure returns (uint256 z) {
    assembly {
        z := 1
        if gt(y, 3) {
            z := y
            let x := add(div(y, 2), 1)
            for { } lt(x, z) { } {
                z := x
                x := div(add(div(y, x), x), 2)
            }
        }
        if iszero(y) { z := 0 }
    }
}
```

## 7. Conclusion
Implementing core mathematical primitives in Yul provides substantial gas savings (over 70% in the case of `sqrt`). For a high-frequency DeFi protocol like an AMM, these cumulative savings directly translate to lower slippage and better execution prices for end users.