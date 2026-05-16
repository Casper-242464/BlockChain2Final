import { useState } from "react";
import { useWriteContract } from "wagmi";
import { GOVERNOR_ADDRESS, GOVERNOR_ABI } from "./contracts";
import toast from "react-hot-toast";

export function CreateProposal() {
    const [desc, setDesc] = useState("");
    const { writeContract, isPending, data: hash } = useWriteContract();

    const handlePropose = () => {
        writeContract({
            address: GOVERNOR_ADDRESS,
            abi: GOVERNOR_ABI,
            functionName: "propose",
            args: [[GOVERNOR_ADDRESS], [0n], ["0x"], desc],
        }, {
            onSuccess: () => {
                toast.success("Proposal created successfully");
            },
            onError: () => {
                toast.error("Failed to create proposal");
            }
        });
    };

    return (
        <div style={{ marginTop: "20px", padding: "20px", background: "#1a1a1a", borderRadius: "12px", border: "1px solid #333", color: "white" }}>
            <h3>Create Proposal</h3>
            <input
                placeholder="Proposal description..."
                value={desc}
                onChange={e => setDesc(e.target.value)}
                style={{ width: "100%", padding: "10px", background: "#222", border: "1px solid #444", borderRadius: "6px", boxSizing: "border-box", color: "white", marginBottom: "10px" }}
            />
            <button onClick={handlePropose} disabled={isPending} style={{ width: "100%", padding: "10px", background: "#28a745", border: "none", borderRadius: "6px", color: "white", cursor: "pointer" }}>
                {isPending ? "Submitting..." : "Submit Proposal"}
            </button>
            {hash && <div style={{ color: "#4ade80", marginTop: "10px" }}>Success! Proposal created.</div>}
        </div>
    );
}
