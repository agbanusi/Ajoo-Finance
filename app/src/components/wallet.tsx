import React from "react";
import { Modal, Button } from "antd";
import { useAuth } from "@/context/authContext";

const LoginModal: React.FC = () => {
  const { isLoginModalVisible, hideLoginModal, login } = useAuth();

  const handleLogin = async (provider: "web3auth" | "rainbowkit" | "kinto") => {
    try {
      await login(provider);
      hideLoginModal();
    } catch (error) {
      console.error("Login failed:", error);
    }
  };

  return (
    <Modal
      title="Login to Your Wallet"
      visible={isLoginModalVisible}
      onCancel={hideLoginModal}
      footer={null}
    >
      <div className="space-y-4">
        <Button block onClick={() => handleLogin("web3auth")}>
          Login with Web3Auth
        </Button>
        <Button block onClick={() => handleLogin("rainbowkit")}>
          Login with RainbowKit
        </Button>
        <Button block onClick={() => handleLogin("kinto")}>
          Login with Kinto
        </Button>
      </div>
    </Modal>
  );
};

export default LoginModal;
