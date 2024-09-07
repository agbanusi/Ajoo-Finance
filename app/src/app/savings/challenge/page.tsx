"use client";

import React, { useState } from "react";
import { Table, Button, Modal, Form, Input, Select, DatePicker } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import { ethers } from "ethers";
import moment from "moment";
import { tokenList } from "@/app/utils/utils";

// Mock data for existing challenge savings
const mockChallengeSavings = [
  {
    id: 1,
    name: "Summer Vacation",
    token: "USDC",
    targetAmount: 5000,
    currentAmount: 3000,
    endDate: "2023-08-31",
    daysLeft: 60,
  },
  {
    id: 2,
    name: "New Laptop",
    token: "ETH",
    targetAmount: 25,
    currentAmount: 2.5,
    endDate: "2023-06-15",
    daysLeft: 10,
  },
];

// Mock token list

const ChallengeSavingsPage: React.FC = () => {
  const [isNewChallengeModalVisible, setIsNewChallengeModalVisible] =
    useState(false);
  const [isSaveModalVisible, setIsSaveModalVisible] = useState(false);
  const [isWithdrawModalVisible, setIsWithdrawModalVisible] = useState(false);
  const [selectedChallenge, setSelectedChallenge] = useState<any>(null);
  const [saveAmount, setSaveAmount] = useState<string>("");
  const [withdrawAmount, setWithdrawAmount] = useState<string>("");

  const columns = [
    // { title: "Name", dataIndex: "name", key: "name" },
    { title: "Token", dataIndex: "token", key: "token" },
    { title: "Target Amount", dataIndex: "targetAmount", key: "targetAmount" },
    {
      title: "Current Amount",
      dataIndex: "currentAmount",
      key: "currentAmount",
    },
    { title: "Days Left", dataIndex: "daysLeft", key: "daysLeft" },
    {
      title: "Action",
      key: "action",
      render: (text: string, record: any) => (
        <>
          <Button onClick={() => handleSaveClick(record)} className="mr-2">
            Save
          </Button>
          {record.currentAmount >= record.targetAmount && (
            <Button onClick={() => handleWithdrawClick(record)}>
              Withdraw
            </Button>
          )}
        </>
      ),
    },
  ];

  const handleSaveClick = (record: any) => {
    setSelectedChallenge(record);
    setIsSaveModalVisible(true);
  };

  const handleWithdrawClick = (record: any) => {
    setSelectedChallenge(record);
    setIsWithdrawModalVisible(true);
  };

  const handleNewChallengeSubmit = async (values: any) => {
    // TODO: Implement creating new challenge saving
    console.log("New challenge:", values);
    setIsNewChallengeModalVisible(false);
  };

  const handleSaveConfirm = async () => {
    // TODO: Implement blockchain transaction
    console.log("Saving to", selectedChallenge, "Amount:", saveAmount);
    setIsSaveModalVisible(false);
    setSaveAmount("");
  };

  const handleWithdrawConfirm = async () => {
    // TODO: Implement blockchain transaction
    console.log(
      "Withdrawing from",
      selectedChallenge,
      "Amount:",
      withdrawAmount
    );
    setIsWithdrawModalVisible(false);
    setWithdrawAmount("");
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Challenge Savings</h1>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsNewChallengeModalVisible(true)}
        >
          New Challenge Saving
        </Button>
      </div>

      <Table columns={columns} dataSource={mockChallengeSavings} />

      <Modal
        title="Save to Challenge"
        visible={isSaveModalVisible}
        onOk={handleSaveConfirm}
        onCancel={() => {
          setIsSaveModalVisible(false);
          setSaveAmount("");
        }}
        width={400}
        centered
        className="custom-modal"
      >
        <p>How much would you like to save to "{selectedChallenge?.name}"?</p>
        <Form layout="vertical">
          <Form.Item label="Amount">
            <Input
              type="number"
              value={saveAmount}
              onChange={(e) => setSaveAmount(e.target.value)}
              placeholder="Enter amount"
            />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="Withdraw from Challenge"
        visible={isWithdrawModalVisible}
        onOk={handleWithdrawConfirm}
        onCancel={() => {
          setIsWithdrawModalVisible(false);
          setWithdrawAmount("");
        }}
        width={400}
        centered
        className="custom-modal"
      >
        <p>
          How much would you like to withdraw from "{selectedChallenge?.name}"?
        </p>
        <Form layout="vertical">
          <Form.Item label="Amount">
            <Input
              type="number"
              value={withdrawAmount}
              onChange={(e) => setWithdrawAmount(e.target.value)}
              placeholder="Enter amount"
            />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="New Challenge Saving"
        visible={isNewChallengeModalVisible}
        onCancel={() => setIsNewChallengeModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleNewChallengeSubmit}>
          <Form.Item name="name" label="Name" rules={[{ required: true }]}>
            <Input />
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
            name="targetAmount"
            label="Target Amount"
            rules={[{ required: true }]}
          >
            <Input type="number" />
          </Form.Item>
          <Form.Item
            name="duration"
            label="Challenge Duration (days)"
            rules={[{ required: true }]}
          >
            <Input type="number" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Create
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default ChallengeSavingsPage;
