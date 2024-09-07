"use client";

import React, { useState } from "react";
import { Button, Card, Modal, Form, Input, InputNumber } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import Link from "next/link";

// Mock data for joined group savings
const mockGroupSavings = [
  { id: "0x01", name: "Family Vacation Fund", members: 5, totalSavings: 5000 },
  { id: "0x02", name: "Wedding Gift Pool", members: 8, totalSavings: 2000 },
];

const GroupSavingsPage: React.FC = () => {
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);

  const handleCreateGroup = (values: any) => {
    // TODO: Implement group creation logic
    console.log("Creating group:", values);
    setIsCreateModalVisible(false);
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Group Savings</h1>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsCreateModalVisible(true)}
        >
          Create Group Saving
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {mockGroupSavings.map((group) => (
          <Link href={`/savings/group/${group.id}/details`} key={group.id}>
            <Card title={group.name} hoverable>
              <p>Members: {group.members}</p>
              <p>Total Savings: ${group.totalSavings}</p>
            </Card>
          </Link>
        ))}
      </div>

      <Modal
        title="Create New Group Saving"
        visible={isCreateModalVisible}
        onCancel={() => setIsCreateModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleCreateGroup} layout="vertical">
          <Form.Item
            name="name"
            label="Group Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="goal"
            label="Savings Goal"
            rules={[{ required: true }]}
          >
            <InputNumber prefix="$" style={{ width: "100%" }} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Create Group
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default GroupSavingsPage;
