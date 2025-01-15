import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Modal, Button } from "antd"; // Updated import for Ant Design Modal
import { createMicroLendingInterface } from "../utils/microLendingInterface";
import {
  fetchUserProfile,
  fetchUserLoans,
  requestLoan,
} from "../api/microLending";

export function MicroLendingProfile() {
  const [isLoanModalOpen, setIsLoanModalOpen] = useState(false);
  const [newLoan, setNewLoan] = useState({
    amount: "",
    duration: "",
    circleId: "",
  });

  const queryClient = useQueryClient();

  const { data: profile, isLoading: profileLoading } = useQuery(
    ["userProfile"],
    fetchUserProfile
  );
  const { data: loans, isLoading: loansLoading } = useQuery(
    ["userLoans"],
    fetchUserLoans
  );

  const requestLoanMutation = useMutation(requestLoan, {
    onSuccess: () => {
      queryClient.invalidateQueries(["userLoans"]);
      setIsLoanModalOpen(false);
      setNewLoan({ amount: "", duration: "", circleId: "" });
    },
  });

  const handleRequestLoan = (e) => {
    e.preventDefault();
    requestLoanMutation.mutate(newLoan);
  };

  if (profileLoading || loansLoading) return <div>Loading...</div>;

  return (
    <div className="max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold mb-6">Your MicroLending Profile</h1>

      <div className="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4">Profile Overview</h2>
        <p>Address: {profile.address}</p>
        <p>Total Balance: ${profile.totalBalance.toLocaleString()}</p>
        <p>Active Loans: {profile.activeLoans}</p>
        <p>Circles Joined: {profile.circlesJoined}</p>
      </div>

      <div className="mb-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-2xl font-bold">Your Loans</h2>
          <Button
            onClick={() => setIsLoanModalOpen(true)}
            className="bg-blue-500 text-white"
          >
            Request New Loan
          </Button>
        </div>

        <div className="bg-white rounded-lg shadow-md overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-100">
              <tr>
                <th className="px-4 py-2 text-left">Circle</th>
                <th className="px-4 py-2 text-left">Amount</th>
                <th className="px-4 py-2 text-left">Duration</th>
                <th className="px-4 py-2 text-left">Status</th>
                <th className="px-4 py-2 text-left">Repaid</th>
              </tr>
            </thead>
            <tbody>
              {loans.map((loan) => (
                <tr key={loan.id} className="border-t">
                  <td className="px-4 py-2">{loan.circleName}</td>
                  <td className="px-4 py-2">${loan.amount.toLocaleString()}</td>
                  <td className="px-4 py-2">{loan.duration} days</td>
                  <td className="px-4 py-2">{loan.status}</td>
                  <td className="px-4 py-2">
                    ${loan.repaidAmount.toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        title="Request New Loan"
        visible={isLoanModalOpen}
        onCancel={() => setIsLoanModalOpen(false)}
        footer={null}
      >
        <form onSubmit={handleRequestLoan}>
          <div className="mb-4">
            <label
              htmlFor="circleId"
              className="block text-sm font-medium text-gray-700"
            >
              Lending Circle
            </label>
            <select
              id="circleId"
              value={newLoan.circleId}
              onChange={(e) =>
                setNewLoan({ ...newLoan, circleId: e.target.value })
              }
              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm p-2"
              required
            >
              <option value="">Select a circle</option>
              {profile.circles.map((circle) => (
                <option key={circle.id} value={circle.id}>
                  {circle.name}
                </option>
              ))}
            </select>
          </div>
          <div className="mb-4">
            <label
              htmlFor="amount"
              className="block text-sm font-medium text-gray-700"
            >
              Loan Amount
            </label>
            <input
              type="number"
              id="amount"
              value={newLoan.amount}
              onChange={(e) =>
                setNewLoan({ ...newLoan, amount: e.target.value })
              }
              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm p-2"
              required
            />
          </div>
          <div className="mb-4">
            <label
              htmlFor="duration"
              className="block text-sm font-medium text-gray-700"
            >
              Loan Duration (days)
            </label>
            <input
              type="number"
              id="duration"
              value={newLoan.duration}
              onChange={(e) =>
                setNewLoan({ ...newLoan, duration: e.target.value })
              }
              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm p-2"
              required
            />
          </div>
          <div className="mt-4">
            <Button
              type="submit"
              className="inline-flex justify-center px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700"
            >
              Request Loan
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
