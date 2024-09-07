"use client";

import React, { useState } from "react";
import {
  Button,
  Card,
  Table,
  Modal,
  Form,
  Input,
  InputNumber,
  message,
} from "antd";
import { useParams } from "next/navigation";

// Mock data for the insurance pool
const mockInsurancePool = {
  id: 1,
  name: "Crop Insurance Pool",
  contributionAmount: 50,
  contributionPeriod: 30,
  nextContributionDeadline: "2023-06-15",
  votingPeriod: 7,
  coverageLimit: 10000,
  members: 100,
  totalFunds: 25000,
};

// Mock data for insurance claims
const mockInsuranceClaims = [
  {
    id: 1,
    claimant: "Alice",
    amount: 1000,
    reason: "Crop damage due to drought",
    status: "Pending",
  },
  {
    id: 2,
    claimant: "Bob",
    amount: 1500,
    reason: "Flood damage",
    status: "Approved",
  },
  {
    id: 3,
    claimant: "Charlie",
    amount: 800,
    reason: "Pest infestation",
    status: "Rejected",
  },
];

const InsurancePoolPage: React.FC = () => {
  const params = useParams();
  const poolId = params.id;

  const [isContributeModalVisible, setIsContributeModalVisible] =
    useState(false);
  const [isClaimModalVisible, setIsClaimModalVisible] = useState(false);

  const handleContribute = (values: any) => {
    // TODO: Implement contribution logic
    console.log("Contributing to pool:", poolId, values);
    setIsContributeModalVisible(false);
    message.success("Contribution successful!");
  };

  const handleClaim = (values: any) => {
    // TODO: Implement claim logic
    console.log("Submitting claim:", poolId, values);
    setIsClaimModalVisible(false);
    message.success("Claim submitted successfully!");
  };

  const handleVote = (claimId: number, approve: boolean) => {
    // TODO: Implement voting logic
    console.log("Voting on claim:", claimId, approve ? "Approve" : "Reject");
    message.success(`Vote submitted: ${approve ? "Approved" : "Rejected"}`);
  };

  const columns = [
    { title: "Claimant", dataIndex: "claimant", key: "claimant" },
    { title: "Amount ($)", dataIndex: "amount", key: "amount" },
    { title: "Reason", dataIndex: "reason", key: "reason" },
    { title: "Status", dataIndex: "status", key: "status" },
    {
      title: "Action",
      key: "action",
      render: (text: string, record: any) =>
        record.status === "Pending" && (
          <span>
            <Button
              onClick={() => handleVote(record.id, true)}
              className="mr-2"
            >
              Approve
            </Button>
            <Button onClick={() => handleVote(record.id, false)} danger>
              Reject
            </Button>
          </span>
        ),
    },
  ];

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">{mockInsurancePool.name}</h1>
        <Button type="primary" onClick={() => setIsClaimModalVisible(true)}>
          Submit Claim
        </Button>
      </div>

      <Card className="mb-6">
        <p>Contribution Amount: ${mockInsurancePool.contributionAmount}</p>
        <p>Contribution Period: {mockInsurancePool.contributionPeriod} days</p>
        <p>
          Next Contribution Deadline:{" "}
          {mockInsurancePool.nextContributionDeadline}
        </p>
        <p>Voting Period: {mockInsurancePool.votingPeriod} days</p>
        <p>Coverage Limit: ${mockInsurancePool.coverageLimit}</p>
        <p>Members: {mockInsurancePool.members}</p>
        <p>Total Funds: ${mockInsurancePool.totalFunds}</p>
        <Button
          onClick={() => setIsContributeModalVisible(true)}
          className="mt-4"
        >
          Make Contribution
        </Button>
      </Card>

      <h2 className="text-xl font-semibold mb-4">Insurance Claims</h2>
      <Table columns={columns} dataSource={mockInsuranceClaims} />

      <Modal
        title="Make Contribution"
        visible={isContributeModalVisible}
        onCancel={() => setIsContributeModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleContribute} layout="vertical">
          <Form.Item
            name="amount"
            label="Contribution Amount ($)"
            rules={[{ required: true }]}
          >
            <InputNumber
              min={1}
              defaultValue={mockInsurancePool.contributionAmount}
            />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Contribute
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="Submit Insurance Claim"
        visible={isClaimModalVisible}
        onCancel={() => setIsClaimModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleClaim} layout="vertical">
          <Form.Item
            name="amount"
            label="Claim Amount ($)"
            rules={[{ required: true }]}
          >
            <InputNumber min={1} max={mockInsurancePool.coverageLimit} />
          </Form.Item>
          <Form.Item
            name="reason"
            label="Claim Reason"
            rules={[{ required: true }]}
          >
            <Input.TextArea />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Submit Claim
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default InsurancePoolPage;
