import { WagmiProvider, createConfig, http } from "wagmi";
import { ConnectKitProvider, ConnectKitButton } from "connectkit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Governance } from "./Governance";
import { CreateProposal } from "./Proposals";
import { ProposalList } from "./ProposalList";
import { Toaster } from "react-hot-toast";
import { injected } from "wagmi/connectors";

const queryClient = new QueryClient();

const anvilChain = {
  id: 31337,
  name: "Foundry",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["http://127.0.0.1:8545"] },
    public: { http: ["http://127.0.0.1:8545"] },
  },
};

const config = createConfig({
  chains: [anvilChain],
  multiInjectedProviderDiscovery: false,
  connectors: [injected()],
  transports: {
    [anvilChain.id]: http("http://127.0.0.1:8545"),
  },
});

function App() {
  return (
    <WagmiProvider config={config}>
      <Toaster position="top-right" />
      <QueryClientProvider client={queryClient}>
        <ConnectKitProvider theme="dark" options={{ disableENS: true, avoidExplicitEnabling: true }}>
          <div style={{ padding: "20px", fontFamily: "sans-serif", backgroundColor: "#121212", minHeight: "100vh", color: "white" }}>
            <header style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h1>DSA Governance</h1>
              <ConnectKitButton />
            </header>

            <main style={{ maxWidth: "600px", margin: "40px auto" }}>
              <Governance />
              <CreateProposal />
              <ProposalList />
            </main>
          </div>
        </ConnectKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
