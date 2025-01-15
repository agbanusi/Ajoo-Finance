"use client";

import React, { createContext, useContext, useState, useEffect } from "react";
import { Web3Auth } from "@web3auth/modal";
import { CHAIN_NAMESPACES } from "@web3auth/base";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { ethers } from "ethers";
import { EthereumPrivateKeyProvider } from "@web3auth/ethereum-provider";
import { useDisconnect } from "wagmi";
import { useEthersSigner } from "../utils/ethers";

type WalletProvider = "web3auth" | "rainbowkit" | null;

interface TransactionParams {
  to: string;
  from?: string;
  value?: string;
  data?: string;
  gasLimit?: string;
  gasPrice?: string;
}

interface AuthContextType {
  isAuthenticated: boolean;
  walletProvider: WalletProvider;
  address: string | null;
  provider: any;
  login: (provider: WalletProvider) => Promise<void>;
  logout: () => Promise<void>;
  sendTransaction: (
    params: TransactionParams
  ) => Promise<ethers.providers.TransactionReceipt>;
  getData: (params: {
    to: string;
    from?: string;
    data: string;
  }) => Promise<string>;
  getBalance: () => Promise<string>;
  isLoginModalVisible: boolean;
  showLoginModal: () => void;
  hideLoginModal: () => void;
  setOpenConnectModal: React.Dispatch<any>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);
const clientId = "YOUR_CLIENT_ID"; // Replace with your actual client ID

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { disconnect } = useDisconnect();
  const ethersSigner = useEthersSigner();
  const { openConnectModal: openMainConnectModal } = useConnectModal();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [walletProvider, setWalletProvider] = useState<WalletProvider>(null);
  const [address, setAddress] = useState<string | null>(null);
  const [provider, setProvider] =
    useState<ethers.providers.Web3Provider | null>(null);
  const [isLoginModalVisible, setIsLoginModalVisible] = useState(false);
  const [web3auth, setWeb3auth] = useState<Web3Auth | null>(null);

  const showLoginModal = () => setIsLoginModalVisible(true);
  const hideLoginModal = () => setIsLoginModalVisible(false);

  const chainConfig = {
    chainNamespace: CHAIN_NAMESPACES.EIP155,
    chainId: "0xafa", // Ethereum mainnet
    rpcTarget: "https://rpc-quicknode-holesky.morphl2.io",
    displayName: "Morph Holesky",
    ticker: "ETH",
    tickerName: "Ethereum",
    logo: "https://cryptologos.cc/logos/ethereum-eth-logo.png",
  };

  useEffect(() => {
    const initWeb3Auth = async () => {
      const privateKeyProvider = new EthereumPrivateKeyProvider({
        config: { chainConfig },
      });
      const web3authInstance = new Web3Auth({
        clientId: clientId,
        chainConfig: chainConfig,
        privateKeyProvider: privateKeyProvider,
      });
      await web3authInstance.initModal();
      setWeb3auth(web3authInstance);
    };

    initWeb3Auth();
  }, []);

  useEffect(() => {
    (async function () {
      const userAddress = await ethersSigner?.getAddress();
      if (!ethersSigner || !userAddress) {
        return logout();
      }

      setIsAuthenticated(true);
      setWalletProvider("rainbowkit");
      setAddress(userAddress as string);
      setProvider(ethersSigner?.provider as any);
    })();
  }, [ethersSigner]);

  const login = async (selectedProvider: WalletProvider) => {
    try {
      if (selectedProvider === "web3auth" && web3auth) {
        let web3Provider = await web3auth.connect();
        const ethersProvider = new ethers.providers.Web3Provider(
          web3Provider as any
        );
        const signer = ethersProvider.getSigner();
        const userAddress = await signer.getAddress();

        setIsAuthenticated(true);
        setWalletProvider(selectedProvider);
        setAddress(userAddress);
        setProvider(ethersProvider);
      } else if (selectedProvider === "rainbowkit") {
        disconnect();
        openMainConnectModal?.();
        const userAddress = await ethersSigner?.getAddress();

        setIsAuthenticated(true);
        setWalletProvider(selectedProvider);
        setAddress(userAddress as string);
        setProvider(ethersSigner?.provider as any);
      } else {
        throw new Error("Invalid wallet provider");
      }
    } catch (error) {
      console.error("Login failed:", error);
    }
  };

  const logout = async () => {
    try {
      if (walletProvider === "web3auth" && web3auth) {
        await web3auth.logout();
      } else {
        disconnect();
      }
      setIsAuthenticated(false);
      setWalletProvider(null);
      setAddress(null);
      setProvider(null);
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  const sendTransaction = async (
    params: TransactionParams
  ): Promise<ethers.providers.TransactionReceipt> => {
    if (!provider) throw new Error("No provider available");

    const signer = provider.getSigner();
    const tx = await signer.sendTransaction({
      to: params.to,
      from: params.from || (address as string),
      value: params.value ? ethers.utils.parseEther(params.value) : undefined,
      data: params.data,
      gasLimit: params.gasLimit,
      gasPrice: params.gasPrice,
    });

    return await tx.wait();
  };

  const getData = async (params: {
    to: string;
    from?: string;
    data: string;
  }): Promise<string> => {
    if (!provider) throw new Error("No provider available");

    const result = await provider.call({
      to: params.to,
      from: params.from,
      data: params.data,
    });

    return result;
  };

  const getBalance = async () => {
    if (!provider || !address)
      throw new Error("No provider or address available");

    const balance = await provider.getBalance(address);
    return ethers.utils.formatEther(balance);
  };

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        walletProvider,
        address,
        provider,
        login,
        logout,
        sendTransaction,
        getData,
        getBalance,
        isLoginModalVisible,
        showLoginModal,
        hideLoginModal,
        setOpenConnectModal: () => {}, // Placeholder for setOpenConnectModal
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
