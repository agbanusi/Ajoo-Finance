"use client";

import React, { useState } from "react";
import { Button, Card, Modal, Form, Input, Select } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import Link from "next/link";
import { tokenList } from "@/app/utils/utils";
import {
  createConsentMessage,
  createConsentProofPayload,
} from "@xmtp/consent-proof-signature";
import { useAuth } from "@/context/authContext";
import { createCircleSavingsInterface } from "@/app/utils/circleSavings";

// Mock data for existing circles
const mockCircles = [
  {
    id: "0x8b198aC597268a0693356970DbA3Ed2828c59208",
    name: "0x8b198aC597268a0693356970DbA3Ed2828c59208",
    members: 5,
    goal: 10000,
    currentAmount: 50000,
    token: "USDT",
  },
  {
    id: "0x8b198aC597268a0693356970DbA3Ed2828c59208",
    name: "0x8b198aC597268a0693356970DbA3Ed2828c59208",
    members: 8,
    goal: 5000,
    currentAmount: 40000,
    token: "USDC",
  },
];

// Mock data for user's created circle
const userCreatedCircle = {
  id: "0x05",
  name: "0x05",
  members: 4,
  goal: 2000,
  currentAmount: 16000,
  token: "DAI",
};

const CircleSavingsPage: React.FC = () => {
  const { provider, address } = useAuth();
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);

  const handleCreateCircle = (values: any) => {
    // TODO: Implement circle creation logic
    console.log("Creating circle:", values);
    setIsCreateModalVisible(false);
  };

  const handleRequestJoin = async (mockGroupDetails: any) => {
    console.log("Requesting to join group:");

    const timestamp = Date.now();
    const message = createConsentMessage(mockGroupDetails.owner, timestamp);
    const signature = await provider.signMessage({
      account: address,
      message,
    });
    const payloadBytes = createConsentProofPayload(signature, timestamp);
    const base64Payload = Buffer.from(payloadBytes).toString("base64");
    //send to backend
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Circle Savings</h1>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsCreateModalVisible(true)}
        >
          Create Circle
        </Button>
      </div>

      <h2 className="text-xl font-semibold mb-4">Your Circles</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        <Link href={`/savings/circle/${userCreatedCircle.id}`}>
          <Card
            title={userCreatedCircle.name}
            extra={<span className="text-green-500">Created by you</span>}
            hoverable
          >
            <p>Members: {userCreatedCircle.members}</p>
            <p>Contribution Amount: ${userCreatedCircle.goal}</p>
            <p>Current Amount: ${userCreatedCircle.currentAmount}</p>
            <p>Token Contributed: {userCreatedCircle.token}</p>
          </Card>
        </Link>
      </div>

      <h2 className="text-xl font-semibold mb-4">Available Circles</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {mockCircles.map((circle) => (
          <Card key={circle.id} title={circle.name}>
            <p>Members: {circle.members}</p>
            <p>Contribution Amount: ${circle.goal}</p>
            <p>Total Saved Amount: ${circle.currentAmount}</p>
            <p>Token Contributed: {circle.token}</p>
            <Button
              type="primary"
              className="mt-4"
              onClick={() => handleRequestJoin(circle)}
            >
              Request to Join
            </Button>
          </Card>
        ))}
      </div>

      <Modal
        title="Create New Circle"
        visible={isCreateModalVisible}
        onCancel={() => setIsCreateModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleCreateCircle} layout="vertical">
          <Form.Item
            name="amount"
            label="Periodic Contribution Amount"
            rules={[{ required: true }]}
          >
            <Input type="number" prefix="$" />
          </Form.Item>
          <Form.Item name="token" label="Token" rules={[{ required: true }]}>
            <Select>
              {tokenList.map((token) => (
                <Select.Option key={token} value={token}>
                  {token}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>
          <Form.Item
            name="duration"
            label="Duration Period (months)"
            rules={[{ required: true }]}
          >
            <Input type="number" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Create Circle
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default CircleSavingsPage;
