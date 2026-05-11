// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title IERC20
/// @author anonymous
/// @notice Minimal ERC20 interface used by the AMM contracts.
interface IERC20 {
    /// @notice Returns the total token supply.
    /// @return The total number of minted tokens.
    function totalSupply() external view returns (uint256);

    /// @notice Returns an account's token balance.
    /// @param account The account to query.
    /// @return The token balance for the account.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers tokens to a recipient.
    /// @param to The recipient address.
    /// @param value The amount to transfer.
    /// @return True if the transfer succeeds.
    function transfer(address to, uint256 value) external returns (bool);

    /// @notice Returns the remaining approved allowance.
    /// @param owner The token owner.
    /// @param spender The approved spender.
    /// @return The remaining allowance amount.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Approves a spender to transfer tokens.
    /// @param spender The address allowed to spend tokens.
    /// @param value The maximum amount the spender may transfer.
    /// @return True if the approval succeeds.
    function approve(address spender, uint256 value) external returns (bool);

    /// @notice Transfers tokens from one account to another using allowance.
    /// @param from The account to debit.
    /// @param to The recipient account.
    /// @param value The amount to transfer.
    /// @return True if the transfer succeeds.
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
