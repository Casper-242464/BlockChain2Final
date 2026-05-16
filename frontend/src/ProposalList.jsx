import { useEffect, useState } from "react";

const SUBGRAPH_URL = "https://api.studio.thegraph.com/query/960/voting-dapp/v0.0.1";

export function ProposalList() {
    const [proposals, setProposals] = useState([]);
    const [loading, setLoading] = useState(true);

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
                </div>
            ))}
        </div>
    );
}