import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatEther } from "viem";
import { TOKEN_ADDRESS, TOKEN_ABI, GOVERNOR_ADDRESS, GOVERNOR_ABI } from "./contracts";

export function Governance() {
    const { address } = useAccount();
    const { writeContract, data: hash } = useWriteContract();

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

    const handleDelegate = () => {
        writeContract({
            address: TOKEN_ADDRESS,
            abi: TOKEN_ABI,
            functionName: "delegate",
            args: [address],
        });
    };

    return (
        <div style={{ marginTop: "20px", padding: "20px", border: "1px solid #ccc", borderRadius: "12px" }}>
            <h2>My Governance Profile</h2>
            <p><b>Address:</b> {address}</p>
            <p><b>Token Balance:</b> {balance ? formatEther(balance) : "0"} DSA</p>
            <p><b>Voting Power:</b> {votes ? formatEther(votes) : "0"} Votes</p>

            <button
                onClick={handleDelegate}
                style={{ padding: "10px 20px", backgroundColor: "#007bff", color: "white", border: "none", borderRadius: "8px", cursor: "pointer" }}
            >
                Delegate to Self (Activate Voting)
            </button>

            {hash && <p style={{ color: "green" }}>Transaction sent! Hash: {hash.slice(0, 10)}...</p>}
        </div>
    );
}