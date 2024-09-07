"use client";

import React, { useState } from "react";
import { Button, Card, Modal, Form, Input, Select, InputNumber } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import { tokenList } from "../utils/utils";

// Mock data for strategy managers
const mockStrategyManagers = [
  {
    id: 1,
    name: "Balanced Growth",
    symbol: "BG",
    aave: 40,
    uniswap: 30,
    morpho: 30,
  },
  {
    id: 2,
    name: "High Yield",
    symbol: "HY",
    aave: 20,
    uniswap: 50,
    morpho: 30,
  },
];

// Mock data for savings investments
const mockSavingsInvestments = [
  {
    id: 1,
    name: "Retirement Fund",
    strategyManager: "Balanced Growth",
    investmentPercentage: 70,
    token: "USDC",
  },
  {
    id: 2,
    name: "Short-term Savings",
    strategyManager: "High Yield",
    investmentPercentage: 50,
    token: "ETH",
  },
];

const InvestmentPage: React.FC = () => {
  const [isCreateStrategyModalVisible, setIsCreateStrategyModalVisible] =
    useState(false);
  const [isCreateInvestmentModalVisible, setIsCreateInvestmentModalVisible] =
    useState(false);

  const handleCreateStrategy = (values: any) => {
    // TODO: Implement strategy creation logic
    console.log("Creating strategy:", values);
    setIsCreateStrategyModalVisible(false);
  };

  const handleCreateInvestment = (values: any) => {
    // TODO: Implement investment creation logic
    console.log("Creating investment:", values);
    setIsCreateInvestmentModalVisible(false);
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Investment Savings</h1>
        <div>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => setIsCreateStrategyModalVisible(true)}
            className="mr-2"
          >
            New Strategy
          </Button>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => setIsCreateInvestmentModalVisible(true)}
          >
            New Investment
          </Button>
        </div>
      </div>

      <h2 className="text-xl font-semibold mb-4">Strategy Managers</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {mockStrategyManagers.map((strategy) => (
          <Card
            key={strategy.id}
            title={strategy.name}
            extra={<span>{strategy.symbol}</span>}
          >
            <p>Aave: {strategy.aave}%</p>
            <p>Uniswap: {strategy.uniswap}%</p>
            <p>Morpho: {strategy.morpho}%</p>
          </Card>
        ))}
      </div>

      <h2 className="text-xl font-semibold mb-4">Savings Investments</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {mockSavingsInvestments.map((investment) => (
          <Card key={investment.id} title={investment.name}>
            <p>Strategy: {investment.strategyManager}</p>
            <p>Investment Percentage: {investment.investmentPercentage}%</p>
            <p>Token: {investment.token}</p>
          </Card>
        ))}
      </div>

      <Modal
        title="Create New Strategy"
        visible={isCreateStrategyModalVisible}
        onCancel={() => setIsCreateStrategyModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleCreateStrategy} layout="vertical">
          <Form.Item
            name="name"
            label="Strategy Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item name="symbol" label="Symbol" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item
            name="aave"
            label="Aave Allocation (%)"
            rules={[{ required: true }]}
          >
            <InputNumber min={0} max={100} />
          </Form.Item>
          <Form.Item
            name="uniswap"
            label="Uniswap Allocation (%)"
            rules={[{ required: true }]}
          >
            <InputNumber min={0} max={100} />
          </Form.Item>
          <Form.Item
            name="morpho"
            label="Morpho Allocation (%)"
            rules={[{ required: true }]}
          >
            <InputNumber min={0} max={100} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Create Strategy
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="Create New Investment"
        visible={isCreateInvestmentModalVisible}
        onCancel={() => setIsCreateInvestmentModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleCreateInvestment} layout="vertical">
          <Form.Item
            name="name"
            label="Investment Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="strategyManager"
            label="Strategy Manager"
            rules={[{ required: true }]}
          >
            <Select>
              {mockStrategyManagers.map((strategy) => (
                <Select.Option key={strategy.id} value={strategy.name}>
                  {strategy.name}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>
          <Form.Item
            name="investmentPercentage"
            label="Investment Percentage"
            rules={[{ required: true }]}
          >
            <InputNumber min={0} max={100} />
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
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Create Investment
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default InvestmentPage;
