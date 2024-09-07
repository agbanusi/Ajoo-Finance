import React, { useState } from "react";
import { Table, Button, Modal, Form, Input, Select } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import { ethers } from "ethers";

// Mock data for existing target savings
const mockTargetSavings = [
  {
    id: 1,
    name: "New Car",
    token: "USDC",
    targetAmount: 10000,
    currentAmount: 2500,
  },
  {
    id: 2,
    name: "Vacation",
    token: "ETH",
    targetAmount: 5,
    currentAmount: 1.5,
  },
];

// Mock token list
const tokenList = ["USDC", "ETH", "DAI", "USDT"];

const TargetSavingsPage: React.FC = () => {
  const [isNewSavingModalVisible, setIsNewSavingModalVisible] = useState(false);
  const [isSaveModalVisible, setIsSaveModalVisible] = useState(false);
  const [selectedSaving, setSelectedSaving] = useState<any>(null);

  const columns = [
    { title: "Name", dataIndex: "name", key: "name" },
    { title: "Token", dataIndex: "token", key: "token" },
    { title: "Target Amount", dataIndex: "targetAmount", key: "targetAmount" },
    {
      title: "Current Amount",
      dataIndex: "currentAmount",
      key: "currentAmount",
    },
    {
      title: "Action",
      key: "action",
      render: (text: string, record: any) => (
        <Button onClick={() => handleSaveClick(record)}>Save</Button>
      ),
    },
  ];

  const handleSaveClick = (record: any) => {
    setSelectedSaving(record);
    setIsSaveModalVisible(true);
  };

  const handleSaveConfirm = async () => {
    // TODO: Implement blockchain transaction
    console.log("Saving to", selectedSaving);
    setIsSaveModalVisible(false);
  };

  const handleNewSavingSubmit = async (values: any) => {
    // TODO: Implement creating new target saving
    console.log("New saving:", values);
    setIsNewSavingModalVisible(false);
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Target Savings</h1>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsNewSavingModalVisible(true)}
        >
          New Target Saving
        </Button>
      </div>

      <Table columns={columns} dataSource={mockTargetSavings} />

      <Modal
        title="Save to Target"
        visible={isSaveModalVisible}
        onOk={handleSaveConfirm}
        onCancel={() => setIsSaveModalVisible(false)}
      >
        <p>Are you sure you want to save to "{selectedSaving?.name}"?</p>
      </Modal>

      <Modal
        title="New Target Saving"
        visible={isNewSavingModalVisible}
        onCancel={() => setIsNewSavingModalVisible(false)}
        footer={null}
      >
        <Form onFinish={handleNewSavingSubmit}>
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

export default TargetSavingsPage;
