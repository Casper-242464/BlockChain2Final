export const TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
export const TIMELOCK_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
export const GOVERNOR_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

export const TOKEN_ABI = [
    "function balanceOf(address owner) view returns (uint256)",
    "function delegate(address delegatee) public",
    "function delegates(address account) view returns (address)",
    "function getVotes(address account) view returns (uint256)"
];

export const GOVERNOR_ABI = [
    "function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) returns (uint256)",
    "function castVote(uint256 proposalId, uint8 support) returns (uint256)",
    "function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) payable returns (uint256)",
    "function state(uint256 proposalId) view returns (uint8)",
    "function proposalThreshold() view returns (uint256)"
];