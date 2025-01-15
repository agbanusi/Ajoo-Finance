"use client";

import React, { useState } from "react";
import { Button, Modal, Form, Input, InputNumber, message } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { fetchLendingCircles } from "../../api/lendingCircles";

const MicroLendingPage: React.FC = () => {
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);
  const [newCircle, setNewCircle] = useState({
    name: "",
    interestRate: "",
    votingPeriod: "",
    contributionPeriod: "",
    contributionAmount: "",
  });

  const {
    data: circles,
    isLoading,
    error,
  } = useQuery({ queryKey: ["lendingCircle"], queryFn: fetchLendingCircles });

  // const createCircleMutation = useMutation(createLendingCircle, {
  //   onSuccess: () => {
  //     queryClient.invalidateQueries(['lendingCircles']);
  //     setIsCreateModalOpen(false);
  //     setNewCircle({ name: '', interestRate: '', votingPeriod: '', contributionAmount: '' });
  //   },
  // });

  const handleCreateCircle = (e: any) => {
    e.preventDefault();
    // console.log("Creating lending circle:", values);
    setIsCreateModalVisible(false);
    message.success("Lending circle created successfully!");
    // createCircleMutation.mutate(newCircle);
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl mt-10 font-bold">Lending Circles</h1>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsCreateModalVisible(true)}
        >
          Create Lending Circle
        </Button>
      </div>
      <div className="flex flex-row justify-around mt-10 bg-gray-800 p-10 mb-20">
        <div className="flex flex-col justify-center">
          <p>Total Value Locked</p>
          <p>$1,345,234</p>
        </div>
        <div className="flex flex-col justify-center">
          <p>Active Loans</p>
          <p>102</p>
        </div>
        <div className="flex flex-col justify-center">
          <p>Average APR</p>
          <p>6.7%</p>
        </div>
      </div>

      {/* <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {circles.map((circle) => (
          <Link to={`/lending/${circle.id}`} key={circle.id}>
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
      </div> */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {circles?.map((circle) => (
          <Link key={circle.id} to={`/lending/${circle.id}`} className="block">
            <div className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow duration-300">
              <div className="p-4 flex flex-col justify-left">
                <h2 className="text-xl font-bold mb-2 text-black">
                  {circle.name}
                </h2>
                <p className="text-gray-600 mb-2">
                  Interest APR: {circle.interestRate}%
                </p>
                <p className="text-gray-600 mb-2">
                  Voting Period: {circle.votingPeriod} days
                </p>
                <p className="text-gray-600 mb-2">
                  Pool Size: ${circle.tvl.toLocaleString()}
                </p>
                <p className="text-gray-600 mb-2">
                  Amount Loaned: ${circle.amountLoaned.toLocaleString()}
                </p>
                <p className="text-gray-600 mb-2">
                  Members: ${circle.members.toLocaleString()}
                </p>
                <p className="text-gray-600">
                  Contribution Amount: $
                  {circle.contributionAmount.toLocaleString()}
                </p>
              </div>
            </div>
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
            <Input
              className="w-full, h-[50px]"
              value={newCircle.name}
              onChange={(e) =>
                setNewCircle({ ...newCircle, name: e.target.value })
              }
            />
          </Form.Item>
          <Form.Item
            name="contributionAmount"
            label="Contribution Amount ($)"
            rules={[{ required: true }]}
          >
            <Input
              className="w-full, h-[50px]"
              value={newCircle.contributionAmount}
              onChange={(e) =>
                setNewCircle({
                  ...newCircle,
                  contributionAmount: e.target.value,
                })
              }
            />
          </Form.Item>
          <Form.Item
            name="contributionPeriod"
            label="Contribution Period (days)"
            rules={[{ required: true }]}
          >
            <Input
              className="w-full, h-[50px]"
              value={newCircle.contributionPeriod}
              onChange={(e) =>
                setNewCircle({
                  ...newCircle,
                  contributionPeriod: e.target.value,
                })
              }
            />
          </Form.Item>
          <Form.Item
            name="votingPeriod"
            label="Voting Period (days)"
            rules={[{ required: true }]}
          >
            <Input
              className="w-full, h-[50px]"
              value={newCircle.votingPeriod}
              onChange={(e) =>
                setNewCircle({
                  ...newCircle,
                  votingPeriod: e.target.value,
                })
              }
            />
          </Form.Item>
          <Form.Item
            name="interestRate"
            label="Interest Rate (%)"
            rules={[{ required: true }]}
          >
            <Input
              className="w-full, h-[50px]"
              value={newCircle.interestRate}
              onChange={(e) =>
                setNewCircle({
                  ...newCircle,
                  interestRate: e.target.value,
                })
              }
            />
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
