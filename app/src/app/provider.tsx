"use client";

import "@rainbow-me/rainbowkit/styles.css";
// import "../styles/globals.css";
// import "../styles/main.scss";
// import { ClientProvider } from "@xmtp/react-sdk";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider } from "wagmi";
import { RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { config } from "./wagmi";
import { ReactNode, useState } from "react";
import { AuthProvider } from "@/context/authContext";
import { XMTPProvider } from "@xmtp/react-sdk";

// const client = new QueryClient();

export function Providers({ children }: { children: ReactNode }) {
  const [queryClient] = useState(() => new QueryClient());
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <XMTPProvider>
          <AuthProvider>
            <RainbowKitProvider>{children}</RainbowKitProvider>
          </AuthProvider>
        </XMTPProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
