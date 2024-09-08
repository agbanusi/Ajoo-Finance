import React, { createContext, useContext, useState, useEffect } from "react";
import { Web3Auth } from "@web3auth/modal";
import { CHAIN_NAMESPACES } from "@web3auth/base";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { createKintoSDK } from "kinto-web-sdk";
import { ethers } from "ethers";
import { useClient } from "@xmtp/react-sdk";

type WalletProvider = "web3auth" | "rainbowkit" | "kinto" | null;

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
  xmtpClient: any;
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
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);
const clientId =
  "BPi5PB_UiIZ-cPz1GtV5i1I2iOSOHuimiXBI0e-Oe_u6X3oVAbCiAZOTEBtTXw4tsluTITPqA8zMsfxIKMjiqNQ"; // get from https://dashboard.web3auth.io
const appAddress = "";

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [walletProvider, setWalletProvider] = useState<WalletProvider>(null);
  const [address, setAddress] = useState<string | null>(null);
  const [provider, setProvider] = useState<any>(null);
  const [isLoginModalVisible, setIsLoginModalVisible] = useState(false);

  const { openConnectModal } = useConnectModal();
  const [web3auth, setWeb3auth] = useState<Web3Auth | null>(null);
  const [kintoWallet, setKintoWallet] = useState<any | null>(null);
  const { client: xmtpClient, initialize: initializeXmtp } = useClient();

  const showLoginModal = () => setIsLoginModalVisible(true);
  const hideLoginModal = () => setIsLoginModalVisible(false);

  useEffect(() => {
    const initWeb3Auth = async () => {
      const web3auth = new Web3Auth({
        clientId: clientId,
        chainConfig: {
          chainNamespace: CHAIN_NAMESPACES.EIP155,
          chainId: "0x1", // Ethereum mainnet
          rpcTarget: process.env.NEXT_PUBLIC_RPC as string,
        },
        privateKeyProvider: provider,
      });
      await web3auth.initModal();
      setWeb3auth(web3auth);
    };

    const initKintoWallet = async () => {
      const kintoSDK = createKintoSDK(appAddress);
      // const kinto = new KintoWallet();
      // await kinto.init();
      setKintoWallet(kintoSDK);
    };

    initWeb3Auth();
    initKintoWallet();
  }, []);

  const login = async (selectedProvider: WalletProvider) => {
    try {
      let web3Provider;

      switch (selectedProvider) {
        case "web3auth":
          if (web3auth) {
            web3Provider = await web3auth.connect();
          }
          break;
        case "rainbowkit":
          if (openConnectModal) {
            openConnectModal();
            return;
          }
          break;
        case "kinto":
          if (kintoWallet) {
            await kintoWallet
              .connect()
              .then(() => {})
              .catch(() => {
                kintoWallet
                  .createNewWallet()
                  .then(() => {
                    console.log("New wallet created successfully");
                  })
                  .catch((error: any) => {
                    console.error("Failed to create new wallet:", error);
                  });
              });
            web3Provider = kintoWallet.provider;
          }
          break;
        default:
          throw new Error("Invalid wallet provider");
      }

      if (web3Provider) {
        const ethersProvider = new ethers.providers.Web3Provider(web3Provider);
        const signer = ethersProvider.getSigner();
        const userAddress = await signer.getAddress();

        setIsAuthenticated(true);
        setWalletProvider(selectedProvider);
        setAddress(userAddress);
        setProvider(ethersProvider);

        // Initialize XMTP client
        await initializeXmtp({ signer });
      }
    } catch (error) {
      console.error("Login failed:", error);
    }
  };

  const logout = async () => {
    try {
      switch (walletProvider) {
        case "web3auth":
          if (web3auth) {
            await web3auth.logout();
          }
          break;
        case "rainbowkit":
          // RainbowKit doesn't have a built-in logout function
          break;
        case "kinto":
          if (kintoWallet) {
            await kintoWallet.disconnect();
          }
          break;
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
      from: params.from,
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
        xmtpClient,
        login,
        logout,
        sendTransaction,
        getData,
        getBalance,
        isLoginModalVisible,
        showLoginModal,
        hideLoginModal,
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
