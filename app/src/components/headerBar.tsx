"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import Flex from "antd/es/flex";
// import Layout from "antd/es/layout";
import { Header } from "antd/es/layout/layout";
import Link from "next/link";
import Image from "next/image";
import { useAuth } from "@/context/authContext";
import { Button } from "antd";

interface Props {}

const navLinks = [
  { name: "savings", link: "/savings" },
  { name: "investments", link: "/investments" },
  { name: "circle savings", link: "/savings/circle" },
  { name: "group savings", link: "/savings/group" },
  { name: "micro lending", link: "/lending" },
  { name: "micro insurance", link: "/insurance" },
  { name: "charity", link: "/custodial" },
];

export const HeaderBar: React.FC<Props> = () => {
  // const { address, xmtpClient, login } = useAuth();
  const { isAuthenticated, address, showLoginModal, logout } = useAuth();
  return (
    <header className="flex items-center justify-between px-8 py-4 bg-gray-900 text-white">
      <div className="flex items-center space-x-4">
        <Image
          src="/ajoo.png"
          alt="Ajoo Finance Logo"
          width={40}
          height={40}
          className="rounded-full"
        />
        <h1 className="text-2xl font-bold text-pink-500">Ajoo Finance</h1>
      </div>
      <nav className="flex space-x-6">
        {navLinks.map((nav) => (
          <Link
            key={nav.name}
            href={nav.link}
            className="px-3 py-2 rounded-md text-sm font-medium text-gray-300 hover:bg-gray-700 hover:text-white transition duration-150 ease-in-out"
          >
            {nav.name}
          </Link>
        ))}
      </nav>
      <div className="flex items-center space-x-4">
        {/* <Button type="primary" onClick={() => login()}>
          Login
        </Button> */}
        {/* <ConnectButton /> */}
        {isAuthenticated ? (
          <>
            <span className="mr-4">{address}</span>
            <Button type="primary" onClick={logout}>
              Logout
            </Button>
          </>
        ) : (
          <Button type="primary" onClick={showLoginModal}>
            Login
          </Button>
        )}
      </div>
    </header>
  );
};
