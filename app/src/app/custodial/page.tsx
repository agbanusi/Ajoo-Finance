"use client";

import React, { useState } from "react";
import { Button, Card, Modal, Form, Input, InputNumber, message } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import Link from "next/link";
import Image from "next/image";

// Mock data for existing custodial accounts
const mockCustodialAccounts = [
  {
    id: "0x01",
    name: "College Fund for Sarah",
    type: "Trust Fund",
    balance: 25000,
    beneficiary: "Sarah Johnson",
    createdAt: "2023-01-15",
  },
  {
    id: "0x03",
    name: "Local Animal Shelter Support",
    type: "Charity",
    balance: 15000,
    beneficiary: "Happy Paws Shelter",
    createdAt: "2023-03-22",
  },
];

const CustodialPage: React.FC = () => {
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);

  const handleCreateAccount = (values: any) => {
    // TODO: Implement account creation logic
    console.log("Creating custodial account:", values);
    setIsCreateModalVisible(false);
    message.success("Custodial account created successfully!");
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Custodial Accounts</h1>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsCreateModalVisible(true)}
        >
          Create Custodial Account
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {mockCustodialAccounts.map((account) => (
          <Link href={`/custodial/${account.id}`} key={account.id}>
            <Card
              hoverable
              cover={
                <Image
                  src={"/savings.jpeg"}
                  alt={account.name}
                  width={400}
                  height={200}
                />
              }
            >
              <Card.Meta
                title={account.name}
                description={
                  <div>
                    <p>Type: {account.type}</p>
                    <p>Balance: ${account.balance}</p>
                    <p>Beneficiary: {account.beneficiary}</p>
                    <p>Created: {account.createdAt}</p>
                  </div>
                }
              />
            </Card>
          </Link>
        ))}
      </div>

      <Modal
        title="Create New Custodial Account"
        visible={isCreateModalVisible}
        onCancel={() => setIsCreateModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleCreateAccount} layout="vertical">
          <Form.Item
            name="name"
            label="Account Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="type"
            label="Account Type"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="beneficiary"
            label="Beneficiary"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="initialDeposit"
            label="Initial Deposit ($)"
            rules={[{ required: true }]}
          >
            <InputNumber min={0} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Create Account
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default CustodialPage;
