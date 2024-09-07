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

// Mock data for the lending circle
const mockLendingCircle = {
  id: 1,
  name: "Community Growth Fund",
  contributionAmount: 100,
  contributionPeriod: 30,
  nextContributionDeadline: "2023-06-15",
  votingPeriod: 7,
  interestRate: 5,
  members: 10,
  totalFunds: 5000,
};

// Mock data for loan requests
const mockLoanRequests = [
  { id: 1, borrower: "Alice", amount: 1000, duration: 60, status: "Pending" },
  { id: 2, borrower: "Bob", amount: 1500, duration: 90, status: "Approved" },
  { id: 3, borrower: "Charlie", amount: 800, duration: 30, status: "Rejected" },
];

const MicroLendingCirclePage: React.FC = () => {
  const params = useParams();
  const circleId = params.id;

  const [isContributeModalVisible, setIsContributeModalVisible] =
    useState(false);
  const [isLoanRequestModalVisible, setIsLoanRequestModalVisible] =
    useState(false);

  const handleContribute = (values: any) => {
    // TODO: Implement contribution logic
    console.log("Contributing to circle:", circleId, values);
    setIsContributeModalVisible(false);
    message.success("Contribution successful!");
  };

  const handleLoanRequest = (values: any) => {
    // TODO: Implement loan request logic
    console.log("Requesting loan:", circleId, values);
    setIsLoanRequestModalVisible(false);
    message.success("Loan request submitted successfully!");
  };

  const handleVote = (loanId: number, approve: boolean) => {
    // TODO: Implement voting logic
    console.log("Voting on loan:", loanId, approve ? "Approve" : "Reject");
    message.success(`Vote submitted: ${approve ? "Approved" : "Rejected"}`);
  };

  const columns = [
    { title: "Borrower", dataIndex: "borrower", key: "borrower" },
    { title: "Amount ($)", dataIndex: "amount", key: "amount" },
    { title: "Duration (days)", dataIndex: "duration", key: "duration" },
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
        <h1 className="text-2xl font-bold">{mockLendingCircle.name}</h1>
        <Button
          type="primary"
          onClick={() => setIsLoanRequestModalVisible(true)}
        >
          Request Loan
        </Button>
      </div>

      <Card className="mb-6">
        <p>Contribution Amount: ${mockLendingCircle.contributionAmount}</p>
        <p>Contribution Period: {mockLendingCircle.contributionPeriod} days</p>
        <p>
          Next Contribution Deadline:{" "}
          {mockLendingCircle.nextContributionDeadline}
        </p>
        <p>Voting Period: {mockLendingCircle.votingPeriod} days</p>
        <p>Interest Rate: {mockLendingCircle.interestRate}%</p>
        <p>Members: {mockLendingCircle.members}</p>
        <p>Total Funds: ${mockLendingCircle.totalFunds}</p>
        <Button
          onClick={() => setIsContributeModalVisible(true)}
          className="mt-4"
        >
          Make Contribution
        </Button>
      </Card>

      <h2 className="text-xl font-semibold mb-4">Loan Requests</h2>
      <Table columns={columns} dataSource={mockLoanRequests} />

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
              defaultValue={mockLendingCircle.contributionAmount}
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
        title="Request Loan"
        visible={isLoanRequestModalVisible}
        onCancel={() => setIsLoanRequestModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleLoanRequest} layout="vertical">
          <Form.Item
            name="amount"
            label="Loan Amount ($)"
            rules={[{ required: true }]}
          >
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item
            name="duration"
            label="Loan Duration (days)"
            rules={[{ required: true }]}
          >
            <InputNumber min={1} />
          </Form.Item>
          <Form.Item
            name="purpose"
            label="Loan Purpose"
            rules={[{ required: true }]}
          >
            <Input.TextArea />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Submit Request
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default MicroLendingCirclePage;
