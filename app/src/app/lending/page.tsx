"use client";

import React, { useState } from "react";
import { Button, Card, Modal, Form, Input, InputNumber, message } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import Link from "next/link";
import Image from "next/image";

// Mock data for existing micro lending circles
const mockLendingCircles = [
  {
    id: "0x01",
    name: "Community Growth Fund",
    contributionAmount: 100,
    contributionPeriod: 30,
    votingPeriod: 7,
    interestRate: 5,
    members: 10,
    totalFunds: 5000,
  },
  {
    id: "0x02",
    name: "Entrepreneurs Support Circle",
    contributionAmount: 500,
    contributionPeriod: 15,
    votingPeriod: 5,
    interestRate: 7,
    members: 28,
    totalFunds: 80000,
  },
];

const MicroLendingPage: React.FC = () => {
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);

  const handleCreateCircle = (values: any) => {
    // TODO: Implement circle creation logic
    console.log("Creating lending circle:", values);
    setIsCreateModalVisible(false);
    message.success("Lending circle created successfully!");
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Micro Lending Circles</h1>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsCreateModalVisible(true)}
        >
          Create Lending Circle
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {mockLendingCircles.map((circle) => (
          <Link href={`/lending/${circle.id}`} key={circle.id}>
            <Card
              hoverable
              cover={
                <Image
                  src="/lending.jpg"
                  alt={circle.name}
                  width={400}
                  height={200}
                />
              }
            >
              <Card.Meta
                title={circle.name}
                description={
                  <div>
                    <p>
                      Contribution: ${circle.contributionAmount} every{" "}
                      {circle.contributionPeriod} days
                    </p>
                    <p>Voting Period: {circle.votingPeriod} days</p>
                    <p>Interest Rate: {circle.interestRate}%</p>
                    <p>Members: {circle.members}</p>
                    <p>Total Funds: ${circle.totalFunds}</p>
                  </div>
                }
              />
            </Card>
          </Link>
        ))}
      </div>

      <Modal
        title="Create New Lending Circle"
        visible={isCreateModalVisible}
        onCancel={() => setIsCreateModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleCreateCircle} layout="vertical">
          <Form.Item
            name="name"
            label="Circle Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="contributionAmount"
            label="Contribution Amount ($)"
            rules={[{ required: true }]}
          >
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item
            name="contributionPeriod"
            label="Contribution Period (days)"
            rules={[{ required: true }]}
          >
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item
            name="votingPeriod"
            label="Voting Period (days)"
            rules={[{ required: true }]}
          >
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item
            name="interestRate"
            label="Interest Rate (%)"
            rules={[{ required: true }]}
          >
            <InputNumber min={0} max={100} />
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

export default MicroLendingPage;
