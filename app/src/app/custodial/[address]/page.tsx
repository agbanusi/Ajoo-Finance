"use client";

import React, { useState } from "react";
import { Button, Card, Modal, Form, InputNumber, message } from "antd";
import { CopyOutlined } from "@ant-design/icons";
import { useParams } from "next/navigation";

// Mock data for the custodial account
const mockCustodialAccount = {
  id: "0x03",
  name: "College Fund for Sarah",
  type: "Trust Fund",
  balance: 25000,
  beneficiary: "Sarah Johnson",
  createdAt: "2023-01-15",
  description:
    "This fund is set up to support Sarah's college education starting in 2025.",
};

const CustodialAccountPage: React.FC = () => {
  const params = useParams();
  const accountId = params.address;

  const [isDonateModalVisible, setIsDonateModalVisible] = useState(false);

  const handleDonate = (values: any) => {
    // TODO: Implement donation logic
    console.log("Donating to account:", accountId, values);
    setIsDonateModalVisible(false);
    message.success("Donation successful!");
  };

  const handleCopyLink = () => {
    const link = `${window.location.origin}/custodial/${accountId}`;
    navigator.clipboard.writeText(link);
    message.success("Link copied to clipboard!");
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">{mockCustodialAccount.name}</h1>
        <div>
          <Button
            onClick={handleCopyLink}
            icon={<CopyOutlined />}
            className="mr-2"
          >
            Copy Link
          </Button>
          <Button type="primary" onClick={() => setIsDonateModalVisible(true)}>
            Donate
          </Button>
        </div>
      </div>

      <Card className="mb-6">
        <p>
          <strong>Type:</strong> {mockCustodialAccount.type}
        </p>
        <p>
          <strong>Balance:</strong> ${mockCustodialAccount.balance}
        </p>
        <p>
          <strong>Beneficiary:</strong> {mockCustodialAccount.beneficiary}
        </p>
        <p>
          <strong>Created:</strong> {mockCustodialAccount.createdAt}
        </p>
        <p>
          <strong>Description:</strong> {mockCustodialAccount.description}
        </p>
      </Card>

      <Modal
        title="Donate to Custodial Account"
        visible={isDonateModalVisible}
        onCancel={() => setIsDonateModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleDonate} layout="vertical">
          <Form.Item
            name="amount"
            label="Donation Amount ($)"
            rules={[{ required: true }]}
          >
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Donate
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default CustodialAccountPage;
