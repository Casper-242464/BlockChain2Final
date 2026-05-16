import { WagmiProvider, createConfig, http } from "wagmi";
import { mainnet, foundry } from "wagmi/chains";
import { ConnectKitProvider, ConnectKitButton, getDefaultConfig } from "connectkit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Governance } from "./Governance";

const queryClient = new QueryClient();

const config = createConfig(
  getDefaultConfig({
    chains: [foundry],
    transports: {
      [foundry.id]: http("http://127.0.0.1:8545"),
    },
    walletConnectProjectId: "753a47d7e9b630e9d683d3f97d1f8566",
    appName: "DSA Governance DAO",
  }),
);

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <ConnectKitProvider>
          <div style={{ padding: "20px", fontFamily: "sans-serif" }}>
            <header style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h1>DSA Governance</h1>
              <ConnectKitButton />
            </header>

            <main style={{ marginTop: "40px" }}>
              <div className="card">
                <h2>Welcome to the DAO</h2>
                <p>Connect your wallet to participate in governance.</p>
              </div>
              <Governance />
            </main>
          </div>
        </ConnectKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
