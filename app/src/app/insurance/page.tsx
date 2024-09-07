"use client";

import React, { useState } from "react";
import { Button, Card, Modal, Form, Input, InputNumber, message } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import Link from "next/link";
import Image from "next/image";

// Mock data for existing insurance pools
const mockInsurancePools = [
  {
    id: "0x01",
    name: "Crop Insurance Pool",
    contributionAmount: 50,
    contributionPeriod: 30,
    votingPeriod: 7,
    coverageLimit: 10000,
    members: 100,
    totalFunds: 25000,
  },
  {
    id: "0x03",
    name: "Small Business Protection",
    contributionAmount: 100,
    contributionPeriod: 15,
    votingPeriod: 5,
    coverageLimit: 20000,
    members: 50,
    totalFunds: 40000,
  },
];

const InsurancePage: React.FC = () => {
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);

  const handleCreatePool = (values: any) => {
    // TODO: Implement pool creation logic
    console.log("Creating insurance pool:", values);
    setIsCreateModalVisible(false);
    message.success("Insurance pool created successfully!");
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Micro Insurance Pools</h1>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsCreateModalVisible(true)}
        >
          Create Insurance Pool
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {mockInsurancePools.map((pool) => (
          <Link href={`/insurance/${pool.id}`} key={pool.id}>
            <Card
              hoverable
              cover={
                <Image
                  src="/insurance.jpeg"
                  alt={pool.name}
                  width={400}
                  height={200}
                />
              }
            >
              <Card.Meta
                title={pool.name}
                description={
                  <div>
                    <p>
                      Contribution: ${pool.contributionAmount} every{" "}
                      {pool.contributionPeriod} days
                    </p>
                    <p>Voting Period: {pool.votingPeriod} days</p>
                    <p>Coverage Limit: ${pool.coverageLimit}</p>
                    <p>Members: {pool.members}</p>
                    <p>Total Funds: ${pool.totalFunds}</p>
                  </div>
                }
              />
            </Card>
          </Link>
        ))}
      </div>

      <Modal
        title="Create New Insurance Pool"
        visible={isCreateModalVisible}
        onCancel={() => setIsCreateModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleCreatePool} layout="vertical">
          <Form.Item name="name" label="Pool Name" rules={[{ required: true }]}>
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
            name="coverageLimit"
            label="Coverage Limit ($)"
            rules={[{ required: true }]}
          >
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Create Pool
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default InsurancePage;
