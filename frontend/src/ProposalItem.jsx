import { useReadContract, useWriteContract, useAccount } from "wagmi";
import { GOVERNOR_ADDRESS, GOVERNOR_ABI, PROPOSAL_STATES } from "./contracts";
import toast from "react-hot-toast";

export function ProposalItem({ proposalId, description }) {
    const { address } = useAccount();

    const { data: state } = useReadContract({
        address: GOVERNOR_ADDRESS,
        abi: GOVERNOR_ABI,
        functionName: "state",
        args: [BigInt(proposalId)],
        query: { refetchInterval: 5000 }
    });

    const { data: hasVoted } = useReadContract({
        address: GOVERNOR_ADDRESS,
        abi: GOVERNOR_ABI,
        functionName: "hasVoted",
        args: [BigInt(proposalId), address],
        query: { refetchInterval: 5000 }
    });

    const { writeContract } = useWriteContract();

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
        if (typeof state !== 'number') return "Loading...";
        return PROPOSAL_STATES[state] || "Unknown";
    }

    return (
        <div style={{ background: "#1a1a1a", padding: "20px", borderRadius: "12px", border: "1px solid #333", marginBottom: "15px", color: "white" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontSize: "0.8em", color: "#888" }}>ID: {proposalId.toString().slice(0, 10)}...</span>
                <span style={{
                    padding: "4px 8px", borderRadius: "4px", fontSize: "0.8em", fontWeight: "bold",
                    backgroundColor: getStatusColor() + "33", color: getStatusColor(), border: `1px solid ${getStatusColor()}`
                }}>
                    {getStatusText()}
                </span>
            </div>

            <h4 style={{ margin: "15px 0" }}>{description || "No description"}</h4>

            {state === 1 && !hasVoted && (
                <div style={{ display: "flex", gap: "10px", marginTop: "15px" }}>
                    <button
                        style={{ flex: 1, padding: "8px", borderRadius: "6px", background: "#28a745", color: "white", border: "none", cursor: "pointer" }}
                        onClick={() => handleVote(1)}
                    >
                        For
                    </button>
                    <button
                        style={{ flex: 1, padding: "8px", borderRadius: "6px", background: "#dc3545", color: "white", border: "none", cursor: "pointer" }}
                        onClick={() => handleVote(0)}
                    >
                        Against
                    </button>
                </div>
            )}

            {state === 1 && hasVoted && (
                <div style={{ marginTop: "15px", padding: "10px", background: "#222", borderRadius: "8px", color: "#888", textAlign: "center", fontSize: "0.9em", border: "1px solid #333" }}>
                    ✅ You have already voted on this proposal.
                </div>
            )}
        </div>
    );
}