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
import { useParams } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import { createMicroLendingInterface } from "../../utils/lending";
import { fetchALendingCircle } from "../../api/lendingCircles";
import { useQuery } from "@tanstack/react-query";

// Mock data for loan requests
const mockLoanRequests = [
  {
    id: 1,
    borrower: "0x0045...008",
    amount: 1000,
    duration: 60,
    status: "Pending",
  },
  {
    id: 2,
    borrower: "0x0045...090",
    amount: 1500,
    duration: 90,
    status: "Approved",
  },
  {
    id: 3,
    borrower: "0x0045...908",
    amount: 800,
    duration: 30,
    status: "Rejected",
  },
];

const MicroLendingCirclePage: React.FC = () => {
  const params = useParams();
  const { provider, sendTransaction } = useAuth();
  const circleId = params.address;
  console.log(circleId);

  const [isContributeModalVisible, setIsContributeModalVisible] =
    useState(false);
  const [isLoanRequestModalVisible, setIsLoanRequestModalVisible] =
    useState(false);

  const {
    data: mockLendingCircle,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["ALendingCircle", circleId],
    queryFn: () => fetchALendingCircle(circleId + ""),
  });

  const handleContribute = async (values: any) => {
    const microLending = createMicroLendingInterface(
      provider,
      mockLendingCircle?.id as string
    );
    const data = microLending.contributeData();
    await sendTransaction({ data, to: mockLendingCircle?.id as string });
    console.log("Contributing to circle:", circleId, values);
    setIsContributeModalVisible(false);
    message.success("Contribution successful!");
  };

  const handleLoanRequest = async (values: any) => {
    const microLending = createMicroLendingInterface(
      provider,
      mockLendingCircle?.id as string
    );
    const data = microLending.requestLoanData(
      values.amount,
      +values.duration * 24 * 3600 + ""
    );
    await sendTransaction({ data, to: mockLendingCircle?.id as string });
    console.log("Requesting loan:", circleId, values);
    setIsLoanRequestModalVisible(false);
    message.success("Loan request submitted successfully!");
    // sendMessage(mockLendingCircle.owner, `New Loan Request`);
  };

  const handleVote = async (loanId: string, approve: boolean) => {
    const microLending = createMicroLendingInterface(
      provider,
      mockLendingCircle?.id as string
    );
    const data = microLending.voteData(loanId, approve);
    await sendTransaction({ data, to: mockLendingCircle?.id as string });
    console.log("Voting on loan:", loanId, approve ? "Approve" : "Reject");
    message.success(`Vote submitted: ${approve ? "Approved" : "Rejected"}`);
  };

  const columns = [
    { title: "Borrower", dataIndex: "borrower", key: "borrower" },
    { title: "Amount ($)", dataIndex: "amount", key: "amount" },
    { title: "Duration (days)", dataIndex: "duration", key: "duration" },
    { title: "Status", dataIndex: "status", key: "status" },
    {
      title: "Vote",
      key: "vote",
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

  console.log(mockLendingCircle);

  return (
    <div className="p-8">
      <div className="flex flex-row justify-around mt-10 bg-gray-800 p-10 mb-4">
        <div className="flex flex-col justify-center w-[70%] text-white text-left font-bold text-xl">
          {mockLendingCircle?.name}
        </div>
        <div className="flex flex-row justify-around align-center w-[20%]">
          {mockLendingCircle?.isMember && (
            <Button
              type="default"
              className="w-[40%] p-4"
              onClick={() => setIsLoanRequestModalVisible(true)}
            >
              Make Payment
            </Button>
          )}
          {mockLendingCircle?.isMember ? (
            <Button
              type="primary"
              className="w-[40%] p-4"
              onClick={() => setIsLoanRequestModalVisible(true)}
            >
              Request Loan
            </Button>
          ) : (
            <Button
              type="primary"
              className="w-[40%] p-4"
              onClick={() => setIsLoanRequestModalVisible(true)}
            >
              Request to join
            </Button>
          )}
        </div>
      </div>

      <div className="flex flex-row justify-around mt-2 bg-gray-800 p-10 mb-20">
        <div className="flex flex-col justify-center">
          <p>Total Pool Size</p>
          <p>$1,345,234</p>
        </div>
        <div className="flex flex-col justify-center">
          <p>Your Share</p>
          <p>102</p>
        </div>
        <div className="flex flex-col justify-center">
          <p>Borrow APR</p>
          <p>6.7%</p>
        </div>
        <div className="flex flex-col justify-center">
          <p>Active Vote</p>
          <p>6.7%</p>
        </div>
        <div className="flex flex-col justify-center">
          <p>Next Contribution</p>
          <p>5 days</p>
        </div>
      </div>

      <h2 className="text-xl font-semibold mb-4">Active Requests</h2>
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
              defaultValue={mockLendingCircle?.contributionAmount}
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
