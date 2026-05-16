import { useReadContract, useWriteContract, useWriteContract } from "wagmi";
import { GOVERNOR_ADDRESS, GOVERNOR_ABI, PROPOSAL_STATES } from "./contracts";
import toast from "react-hot-toast";

export function ProposalItem({ proposalId, description }) {
    const { data: state } = useReadContract({
        address: GOVERNOR_ADDRESS,
        abi: GOVERNOR_ABI,
        functionName: "state",
        args: [BigInt(proposalId)],
        query: { refetchInterval: 5000 }
    });

    const { writeContract } = useWriteContract;

    const handleVote = (support) => {
        writeContract({
            address: GOVERNOR_ADDRESS,
            abi: GOVERNOR_ABI,
            functionName: "castVote",
            args: [BigInt(proposalId), support],
        }, {
            onSuccess: () => {
                toast.success("Vote cast successfully");
            },
            onError: () => {
                toast.error("Failed to cast vote");
            }
        });
    }

    const getStatusColor = () => {
        switch (state) {
            case 1: return "#4ade80";
            case 2: return "#f59e0b";
            case 3: return "#f59e0b";
            case 4: return "#4ade80";
            case 5: return "#6366f1";
            case 6: return "#f59e0b";
            case 7: return "#f59e0b";
            default: return "#9ca3af";
        }
    }

    const getStatusText = () => {
        if (typeof state !== 'number') return "Unknown";
        return PROPOSAL_STATES[state] || "Unknown";
    }
}