import { useAccount, useReadContract, useWriteContract } from "wagmi";
import { formatEther } from "viem";
import { TOKEN_ADDRESS, TOKEN_ABI } from "./contracts";

export function Governance() {
    const { address, isConnected, chainId } = useAccount();
    const { writeContract, data: hash, isPending } = useWriteContract();

    const { data: balance } = useReadContract({
        address: TOKEN_ADDRESS,
        abi: TOKEN_ABI,
        functionName: "balanceOf",
        args: [address],
    });

    const { data: votes } = useReadContract({
        address: TOKEN_ADDRESS,
        abi: TOKEN_ABI,
        functionName: "getVotes",
        args: [address],
    });

    const { data: delegatee } = useReadContract({
        address: TOKEN_ADDRESS,
        abi: TOKEN_ABI,
        functionName: "delegates",
        args: [address],
    });

    const { data: totalSupply } = useReadContract({
        address: TOKEN_ADDRESS,
        abi: TOKEN_ABI,
        functionName: "totalSupply",
    });

    const handleDelegate = () => {
        writeContract({
            address: TOKEN_ADDRESS,
            abi: TOKEN_ABI,
            functionName: "delegate",
            args: [address],
        });
    };

    if (!isConnected) return <div style={{ color: "orange" }}>Wallet not connected!</div>;

    return (
        <div style={{ padding: "20px", border: "1px solid #333", borderRadius: "12px", background: "#1a1a1a", color: "white" }}>
            <h2>DAO Profile</h2>
            <div style={{ display: "flex", gap: "10px", marginBottom: "20px", flexWrap: "wrap" }}>
                <div style={{ flex: "1 1 40%", background: "#222", padding: "15px", borderRadius: "8px" }}>
                    <div style={{ color: "#888", fontSize: "0.8em" }}>Balance</div>
                    <div style={{ fontSize: "1.4em", fontWeight: "bold" }}>{balance ? formatEther(balance) : "0"} DSA</div>
                </div>
                <div style={{ flex: "1 1 40%", background: "#222", padding: "15px", borderRadius: "8px" }}>
                    <div style={{ color: "#888", fontSize: "0.8em" }}>Voting Power</div>
                    <div style={{ fontSize: "1.4em", fontWeight: "bold", color: "#4ade80" }}>{votes ? formatEther(votes) : "0"}</div>
                </div>
                <div style={{ flex: "1 1 100%", background: "#222", padding: "15px", borderRadius: "8px" }}>
                    <div style={{ color: "#888", fontSize: "0.8em" }}>Delegated To</div>
                    <div style={{ fontSize: "0.9em", fontFamily: "monospace", marginTop: "5px" }}>
                        {delegatee && delegatee !== "0x0000000000000000000000000000000000000000" ? delegatee : "Not Delegated"}
                    </div>
                </div>
                <div style={{ flex: "1 1 100%", background: "#222", padding: "15px", borderRadius: "8px", border: "1px solid #4ade8033" }}>
                    <div style={{ color: "#888", fontSize: "0.8em" }}>Protocol State: Total DSA Supply</div>
                    <div style={{ fontSize: "1.1em", fontWeight: "bold", marginTop: "5px", color: "#4ade80" }}>
                        {totalSupply ? formatEther(totalSupply) : "0"} DSA
                    </div>
                </div>
            </div>

            <button
                onClick={handleDelegate}
                disabled={isPending}
                style={{ width: "100%", padding: "12px", backgroundColor: "#007bff", color: "white", border: "none", borderRadius: "8px", cursor: "pointer" }}
            >
                {isPending ? "Confirming..." : "Delegate to Self (Activate Voting)"}
            </button>
            {hash && <p style={{ color: "green", fontSize: "0.8em" }}>Tx Sent! Voting power will update in a few seconds.</p>}
        </div>
    );
}
