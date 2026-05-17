# Coverage Report (Person 2 — gTurboflex)

Generated with:

```bash
forge coverage --report summary --ir-minimum
```

Commit: local workspace after adding vault/oracle test suite.

## Per-contract (`src/`)

| Contract | Line % | Statement % | Branch % | Func % |
|----------|--------|-------------|----------|--------|
| **ChainlinkOracle.sol** | **100.00%** | **100.00%** | **100.00%** | **100.00%** |
| **ERC4626Vault.sol** | **100.00%** | **100.00%** | **100.00%** | **100.00%** |
| AMMPair.sol | 95.33% | 93.46% | 41.82% | 100.00% |
| AMMFactory.sol | 87.76% | 88.89% | 0.00% | 90.91% |
| AMMUpgradeHelpers.sol | 31.40% | 26.44% | 10.81% | 35.00% |
| DSAGovernor.sol | 80.95% | 78.95% | 100.00% | 80.00% |
| GovernanceToken.sol | 60.00% | 50.00% | 100.00% | 60.00% |

## Total (includes tests)

| Metric | Coverage |
|--------|----------|
| Lines | 71.66% |
| Statements | 70.09% |
| Branches | 24.09% |
| Functions | 71.54% |

## Test counts (Person 2 deliverables)

| Category | Count | Requirement |
|----------|-------|-------------|
| Unit (vault + oracle + AMM helpers) | 50+ | 50 |
| Fuzz | 13+ | 10 |
| Invariant suites | 4 invariants | 5 |
| Fork | 6 | 3 |
| **Total tests** | **131** | **80** |

## Notes for the team

- `ERC4626Vault` and `ChainlinkOracle` meet the **≥90% per-contract** target for Person 2 scope.
- Repository-wide **≥90% line coverage** still requires tests for `AMMUpgradeHelpers` upgrade paths and deeper governance coverage (Person 1 / Person 3).
- Run full suite: `forge test`
- Run Slither before submission: `slither .`
