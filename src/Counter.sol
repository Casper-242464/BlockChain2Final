// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/// @title Counter
/// @author anonymous
/// @notice Simple counter contract for storing and updating a numeric value.
contract Counter {
    /// @notice Stored counter value.
    uint256 public number;

    /// @notice Set the counter value.
    /// @param newNumber The new value to store.
    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    /// @notice Increment the counter by one.
    function increment() public {
        ++number;
    }
}
