// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract DSATimelock is TimelockController {
    /// @notice Default minimum delay for the timelock (2 days)
    uint256 public constant DEFAULT_MIN_DELAY = 2 days;

    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
