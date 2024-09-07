"use client";

import React, { useState, useEffect } from "react";
import { Button, Input, List, Modal, Form, InputNumber } from "antd";
import { Client } from "@xmtp/xmtp-js";
import { ethers } from "ethers";
import { useParams } from "next/navigation";
import { useAuth } from "@/context/authContext";
import {
  CachedConversation,
  ContentTypeMetadata,
  useConversation,
  useMessages,
  useSendMessage,
} from "@xmtp/react-sdk";

const GroupChatPage: React.FC = () => {
  const params = useParams();
  const groupId = params.address;

  // const [messages, setMessages] = useState<any[]>([]);
  // const [newMessage, setNewMessage] = useState("");
  // const [xmtp, setXmtp] = useState<Client | null>(null);
  // const [conversation, setConversation] = useState<any>(null);
  // const [isSaveModalVisible, setIsSaveModalVisible] = useState(false);
  // const [isRequestFundsModalVisible, setIsRequestFundsModalVisible] =
  //   useState(false);

  const { address, xmtpClient, login } = useAuth();
  const { sendMessage } = useSendMessage();

  const [newMessage, setNewMessage] = useState("");
  const [messages, setMessages] = useState<any[]>([]);
  const [isSaveModalVisible, setIsSaveModalVisible] = useState(false);
  const [isRequestFundsModalVisible, setIsRequestFundsModalVisible] =
    useState(false);

  const convoTopic = `group-savings-${address}@xmtp.org`;
  const { getCachedByTopic } = useConversation(); //`group-savings-${groupId}@xmtp.org`, xmtpClient);

  // useEffect(() => {
  //   const initXmtp = async () => {
  //     // TODO: Replace with actual wallet connection
  //     const wallet = ethers.Wallet.createRandom();
  //     const xmtp = await Client.create(wallet);
  //     setXmtp(xmtp);

  //     // TODO: Replace with actual group chat topic
  //     const conversation = await xmtp.conversations.newConversation(
  //       `group-savings-${groupId}@xmtp.org`
  //     );
  //     setConversation(conversation);

  //     // Load existing messages
  //     const messages = await conversation.messages();
  //     setMessages(messages);

  //     // Listen for new messages
  //     for await (const message of await conversation.streamMessages()) {
  //       setMessages((prevMessages) => [...prevMessages, message]);
  //     }
  //   };

  //   initXmtp();
  // }, [groupId]);

  useEffect(() => {
    (async () => {
      const conversation = await getCachedByTopic(convoTopic);
      const { messages } = useMessages(
        conversation as CachedConversation<ContentTypeMetadata>
      );
      setMessages(messages);
    })();
  }, [address, groupId, newMessage]);

  useEffect(() => {
    if (!address) {
      login();
    }
  }, [address, login]);

  const sendNewMessage = async () => {
    const conversation = await getCachedByTopic(convoTopic);
    if (newMessage.trim() && conversation) {
      await sendMessage(conversation, newMessage);
      setNewMessage("");
    }
  };

  const handleSave = (values: any) => {
    // TODO: Implement save logic
    console.log("Saving:", values);
    setIsSaveModalVisible(false);
  };

  const handleRequestFunds = (values: any) => {
    // TODO: Implement request funds logic
    console.log("Requesting funds:", values);
    setIsRequestFundsModalVisible(false);
  };

  const handleBatchSend = () => {
    // TODO: Implement batch send logic
    console.log("Batch sending funds");
  };

  const handleAcceptTransfer = () => {
    // TODO: Implement accept transfer logic
    console.log("Accepting transfer request");
  };

  const handleRemoveMember = () => {
    // TODO: Implement remove member logic
    console.log("Removing member");
  };

  const handleAcceptJoinRequest = () => {
    // TODO: Implement accept join request logic
    console.log("Accepting join request");
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Group Chat</h1>
      <div className="flex space-x-4 mb-4">
        <Button onClick={() => setIsSaveModalVisible(true)}>Save</Button>
        <Button onClick={() => setIsRequestFundsModalVisible(true)}>
          Request Funds
        </Button>
        <Button onClick={handleBatchSend}>Batch Send</Button>
        <Button onClick={handleAcceptTransfer}>Accept Transfer</Button>
        <Button onClick={handleRemoveMember}>Remove Member</Button>
        <Button onClick={handleAcceptJoinRequest}>Accept Join Request</Button>
      </div>
      <List
        dataSource={messages}
        renderItem={(msg) => (
          <List.Item>
            <strong>{msg.senderAddress}:</strong> {msg.content}
          </List.Item>
        )}
      />
      <div className="mt-4 flex">
        <Input
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          onPressEnter={sendNewMessage}
          placeholder="Type a message..."
        />
        <Button onClick={sendNewMessage}>Send</Button>
      </div>

      <Modal
        title="Save to Group"
        visible={isSaveModalVisible}
        onCancel={() => setIsSaveModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleSave} layout="vertical">
          <Form.Item name="amount" label="Amount" rules={[{ required: true }]}>
            <InputNumber prefix="$" style={{ width: "100%" }} />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Save
            </Button>
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="Request Funds"
        visible={isRequestFundsModalVisible}
        onCancel={() => setIsRequestFundsModalVisible(false)}
        footer={null}
        width={400}
        centered
        className="custom-modal"
      >
        <Form onFinish={handleRequestFunds} layout="vertical">
          <Form.Item name="amount" label="Amount" rules={[{ required: true }]}>
            <InputNumber prefix="$" style={{ width: "100%" }} />
          </Form.Item>
          <Form.Item name="reason" label="Reason" rules={[{ required: true }]}>
            <Input.TextArea />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Request
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default GroupChatPage;
