"use client";

import React, { useState } from "react";
import { Button, Card, message } from "antd";
import { CopyOutlined } from "@ant-design/icons";

import { fetchAGroupSaving } from "../../../api/savings";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../../../context/authContext";
import { Link, useParams } from "react-router-dom";

const GroupDetailsPage: React.FC = () => {
  const params = useParams();
  const groupId = params.address;
  // const { provider, address } = useAuth();

  const { data: mockGroupDetails } = useQuery({
    queryKey: ["A Group Saving", groupId],
    queryFn: () => fetchAGroupSaving(groupId + ""),
  });

  const handleRequestJoin = async () => {
    // TODO: Implement join request logic
    console.log("Requesting to join group:", groupId);

    // const timestamp = Date.now();
    // const message = createConsentMessage(mockGroupDetails?.owner, timestamp);
    // const signature = await provider.signMessage({
    //   account: address,
    //   message,
    // });
    // const payloadBytes = createConsentProofPayload(signature, timestamp);
    // const base64Payload = Buffer.from(payloadBytes).toString("base64");
    //send to backend
  };

  const handleCopyLink = () => {
    const link = `${window.location.origin}/savings/group/${mockGroupDetails?.id}/details`;
    navigator.clipboard.writeText(link);
    message.success("Link copied to clipboard!");
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">{mockGroupDetails?.name}</h1>
      <Card>
        <p>Members: {mockGroupDetails?.members}</p>
        <p>Total Savings: ${mockGroupDetails?.totalSavings}</p>
        <div className="mt-4 flex space-x-4">
          <Button type="primary" onClick={handleRequestJoin}>
            Request to Join
          </Button>
          <Button icon={<CopyOutlined />} onClick={handleCopyLink}>
            Copy Invite Link
          </Button>
          <Link to={`/savings/group/${mockGroupDetails?.id}`}>
            <Button>Group Chat</Button>
          </Link>
        </div>
      </Card>
    </div>
  );
};

export default GroupDetailsPage;
