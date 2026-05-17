import { parseAbi } from "viem";

export const TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
export const TIMELOCK_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
export const GOVERNOR_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

export const TOKEN_ABI = parseAbi([
    "function balanceOf(address owner) view returns (uint256)",
    "function delegate(address delegatee)",
    "function getVotes(address account) view returns (uint256)",
    "function transfer(address to, uint256 amount) returns (bool)",
    "function delegates(address account) view returns (address)",
    "function totalSupply() view returns (uint256)"
]);

export const GOVERNOR_ABI = parseAbi([
    "function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) returns (uint256)",
    "function castVote(uint256 proposalId, uint8 support) returns (uint256)",
    "function state(uint256 proposalId) view returns (uint8)",
    "function hasVoted(uint256 proposalId, address account) view returns (bool)",
    "function queue(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) returns (uint256)",
    "function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) returns (uint256)"
]);

export const PROPOSAL_STATES = [
    "Pending",   // 0
    "Active",    // 1
    "Canceled",  // 2
    "Defeated",  // 3
    "Succeeded", // 4
    "Queued",    // 5
    "Expired",   // 6
    "Executed"   // 7
];