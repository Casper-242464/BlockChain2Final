import { useEffect, useState } from "react";
import { useWriteContract, useReadContract } from "wagmi";
import { GOVERNOR_ADDRESS, GOVERNOR_ABI } from "./contracts";

const SUBGRAPH_URL = "https://api.studio.thegraph.com/query/960/voting-dapp/v0.0.1";

export function ProposalList() {
    const [proposals, setProposals] = useState([]);
    const [loading, setLoading] = useState(true);
    const { writeContract } = useWriteContract();

    const QUERY = `
    {
        proposalCreateds(first: 5, orderBy: blockNumber, orderDirection: desc) {
        id
        proposalId
        description
        proposer
        }
    }
    `;

    useEffect(() => {
        fetch(SUBGRAPH_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ query: QUERY })
        })
            .then(res => res.json())
            .then(result => {
                setProposals(result.data?.proposalCreateds || []);
                setLoading(false);
            })
            .catch(err => console.error("Subgraph error:", err));
    }, []);

    const handleVote = (proposalId, support) => {
        writeContract({
            address: GOVERNOR_ADDRESS,
            abi: GOVERNOR_ABI,
            functionName: "castVote",
            args: [proposalId, support]
        });
    };

    return (
        <div style={{ marginTop: "20px", color: "white" }}>
            <h3>Active Proposals (from Subgraph)</h3>
            {loading && <p>Loading from The Graph...</p>}
            {proposals.length === 0 && !loading && <p>No proposals found.</p>}
            {proposals.map(p => (
                <div key={p.id} style={{ background: "#222", padding: "15px", borderRadius: "8px", marginBottom: "10px", border: "1px solid #333" }}>
                    <div style={{ fontSize: "0.8em", color: "#888" }}>ID: {p.proposalId}</div>
                    <div style={{ fontWeight: "bold", margin: "5px 0" }}>{p.description || "No description"}</div>
                    <div style={{ fontSize: "0.7em", color: "#555" }}>By: {p.proposer}</div>
                    <div style={{ marginTop: "10px" }}>
                        <button
                            onClick={() => handleVote(p.proposalId, 1)}
                            style={{ background: "#28a745", color: "white", border: "none", padding: "5px 10px", marginRight: "5px", borderRadius: "4px" }}
                        >
                            For
                        </button>
                        <button
                            onClick={() => handleVote(p.proposalId, 0)}
                            style={{ background: "#dc3545", color: "white", border: "none", padding: "5px 10px", borderRadius: "4px" }}
                        >
                            Against
                        </button>
                    </div>
                </div>
            ))}
        </div>
    );
}