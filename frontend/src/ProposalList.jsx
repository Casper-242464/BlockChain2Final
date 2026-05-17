import { useEffect, useState } from "react";
import { usePublicClient, useWatchContractEvent } from "wagmi";
import { GOVERNOR_ADDRESS, GOVERNOR_ABI } from "./contracts";
import { parseAbiItem } from "viem";
import { ProposalItem } from "./ProposalItem";

const SUBGRAPH_URL = "https://api.studio.thegraph.com/query/960/voting-dapp/v0.0.1";

export function ProposalList() {
    const [proposals, setProposals] = useState([]);
    const [loading, setLoading] = useState(true);
    const publicClient = usePublicClient();

    const fetchLogs = async () => {
        if (!publicClient) return;
        try {
            const logs = await publicClient.getLogs({
                address: GOVERNOR_ADDRESS,
                event: parseAbiItem('event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 voteStart, uint256 voteEnd, string description)'),
                fromBlock: 0n
            });
            setProposals(logs.map(l => ({
                id: l.args.proposalId.toString(),
                desc: l.args.description,
                targets: l.args.targets,
                values: l.args.values,
                calldatas: l.args.calldatas
            })).reverse());
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { fetchLogs(); }, [publicClient]);

    useWatchContractEvent({
        address: GOVERNOR_ADDRESS,
        abi: GOVERNOR_ABI,
        eventName: 'ProposalCreated',
        onLogs: fetchLogs
    });

    useEffect(() => {
        fetch(SUBGRAPH_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ query: `{ proposalCreateds(first: 5) { proposalId description } }` })
        }).catch(err => console.error("Subgraph error:", err));
    }, []);

    return (
        <div style={{ marginTop: "10px", color: "white" }}>
            <h3 style={{ marginTop: 0, marginBottom: "10px", paddingBottom: "10px" }}>Active Proposals</h3>
            {loading && <p>Loading...</p>}
            {proposals.length === 0 && !loading && <p>No proposals found.</p>}

            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(300px, 1fr))", gap: "20px" }}>
                {proposals.map(p => (
                    <ProposalItem key={p.id} proposalId={p.id} description={p.desc} targets={p.targets} values={p.values} calldatas={p.calldatas} />
                ))}
            </div>
        </div>
    );
}