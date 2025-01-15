// "use client";

// import React, { useState } from "react";
// import { Button, Card, Table, Modal, Form, Input } from "antd";
// import { useParams } from "next/navigation";
// import { Client } from "@xmtp/xmtp-js";
// import { useAuth } from "@/context/authContext";
// import {
//   createConsentMessage,
//   createConsentProofPayload,
// } from "@xmtp/consent-proof-signature";
// import { createCircleSavingsInterface } from "@/app/utils/circleSavings";

// // Mock data for circle details
// const mockCircleDetails = {
//   id: "0x8b198aC597268a0693356970DbA3Ed2828c59208",
//   name: "0x8b198aC597268a0693356970DbA3Ed2828c59208",
//   members: 4,
//   amount: 2000,
//   currentAmount: 16000,
//   token: "DAI",
//   isCreator: false,
//   isMember: true,
//   owner: "0x8b198aC597268a0693356970DbA3Ed2828c59201",
// };

// // Mock data for join requests
// const mockJoinRequests = [
//   {
//     id: "0x8b198aC597268a0693356970DbA3Ed2828c59200",
//     name: "0x03",
//     status: "pending",
//     consentProofPayload: "",
//   },
//   {
//     id: "0x8b198aC597268a0693356970DbA3Ed2828c59202",
//     name: "0x08",
//     status: "pending",
//     consentProofPayload: "",
//   },
// ];

// const mockMembers = [
//   {
//     id: "0x8b198aC597268a0693356970DbA3Ed2828c59205",
//     name: "0x8b198aC597268a0693356970DbA3Ed2828c59205",
//     consentProofPayload: "",
//   },
//   {
//     id: "0x8b198aC597268a0693356970DbA3Ed2828c59206",
//     name: "0x8b198aC597268a0693356970DbA3Ed2828c59206",
//     consentProofPayload: "",
//   },
// ];

// const CirclePage: React.FC = () => {
//   const params = useParams();
//   const { address, provider, sendTransaction } = useAuth();
//   const circleId = params.id;

//   const [isPaymentModalVisible, setIsPaymentModalVisible] = useState(false);
//   const [paymentAmount, setPaymentAmount] = useState(
//     mockCircleDetails.amount + ""
//   );

//   const handlePayment = () => {
//     // TODO: Implement payment logic
//     console.log("Making payment:", paymentAmount);
//     setIsPaymentModalVisible(false);
//     setPaymentAmount("");
//   };

//   const handleRequestJoin = async () => {
//     console.log("Requesting to join group:");

//     const timestamp = Date.now();
//     const message = createConsentMessage(mockCircleDetails.owner, timestamp);
//     const signature = await provider.signMessage({
//       account: address,
//       message,
//     });
//     const payloadBytes = createConsentProofPayload(signature, timestamp);
//     const base64Payload = Buffer.from(payloadBytes).toString("base64");
//     //send to backend
//     mockJoinRequests.push({
//       id: "0x8b198aC597268a0693356970DbA3Ed2828c59200",
//       name: "0x8b198aC597268a0693356970DbA3Ed2828c59200",
//       status: "pending",
//       consentProofPayload: base64Payload,
//     });
//   };

//   const handleAcceptRequest = async (member: string) => {
//     const circleSavings = createCircleSavingsInterface(
//       provider,
//       mockCircleDetails.id
//     );
//     const data = circleSavings.addMemberData(member);
//     await sendTransaction({ data, to: mockCircleDetails.id });
//     const newMember = mockJoinRequests.find((req) => req.id == member);
//     mockMembers.push(newMember!);
//     console.log("Accepting request:", member);
//   };

//   const handleRejectRequest = async (member: string) => {
//     const circleSavings = createCircleSavingsInterface(
//       provider,
//       mockCircleDetails.id
//     );
//     const data = circleSavings.removeMemberData(member);
//     await sendTransaction({ data, to: mockCircleDetails.id });
//     console.log("Rejecting request:", member);
//   };

//   async function sendContributionReminderMessage() {
//     const recipients = mockMembers; //.map(mem=>mem.name);
//     const message = `Reminder to pay the periodic contribution amount to ensure you're not frozen from the circle`;
//     // In a real application, use the user's wallet
//     const xmtp = await Client.create(provider);

//     // Iterate over each recipient to send the message
//     for (const recipient of recipients) {
//       // Check if the recipient is activated on the XMTP network
//       if (await xmtp.canMessage(recipient.name)) {
//         const conversation = await xmtp.conversations.newConversation(
//           recipient.name,
//           undefined,
//           recipient.consentProofPayload as any
//         );
//         await conversation.send(message);
//         console.log(`Message successfully sent to ${recipient}`);
//       } else {
//         console.log(
//           `Recipient ${recipient} is not activated on the XMTP network.`
//         );
//       }
//     }
//   }

//   const requestColumns = [
//     { title: "Name", dataIndex: "name", key: "name" },
//     {
//       title: "Action",
//       key: "action",
//       render: (text: string, record: any) => (
//         <>
//           <Button
//             onClick={() => handleAcceptRequest(record.id)}
//             className="mr-2"
//           >
//             Accept
//           </Button>
//           <Button onClick={() => handleRejectRequest(record.id)} danger>
//             Reject
//           </Button>
//         </>
//       ),
//     },
//   ];

//   return (
//     <div className="p-8">
//       <h1 className="text-2xl font-bold mb-6">{mockCircleDetails.name}</h1>
//       <Card className="text-lg">
//         <p>Members: {mockCircleDetails.members}</p>
//         <p>Contribution Amount: ${mockCircleDetails.amount}</p>
//         <p>Circle Savings Amount: ${mockCircleDetails.currentAmount}</p>
//         {mockCircleDetails.isCreator && (
//           <div className="mt-4">
//             <h2 className="text-xl font-semibold mb-2">Join Requests</h2>
//             <Table columns={requestColumns} dataSource={mockJoinRequests} />
//           </div>
//         )}
//         {mockCircleDetails.isMember ? (
//           <Button
//             type="primary"
//             onClick={() => setIsPaymentModalVisible(true)}
//             className="mt-4"
//           >
//             Make Circle Saving Payment
//           </Button>
//         ) : (
//           <Button type="primary" onClick={handleRequestJoin} className="mt-4">
//             Request to Join
//           </Button>
//         )}

//         {mockCircleDetails.isCreator && (
//           <Button
//             type="primary"
//             onClick={() => sendContributionReminderMessage()}
//             className="mt-4"
//           >
//             Send Contribution Reminder
//           </Button>
//         )}
//       </Card>

//       <Modal
//         title="Make Circle Saving Payment"
//         visible={isPaymentModalVisible}
//         onOk={handlePayment}
//         onCancel={() => {
//           setIsPaymentModalVisible(false);
//           setPaymentAmount("");
//         }}
//         width={400}
//         centered
//         className="custom-modal"
//       >
//         <Form layout="vertical">
//           <Form.Item label="Payment Amount">
//             <Input
//               type="number"
//               value={paymentAmount}
//               onChange={(e) => setPaymentAmount(e.target.value)}
//               prefix="$"
//               placeholder="Enter amount"
//             />
//           </Form.Item>
//         </Form>
//       </Modal>
//     </div>
//   );
// };

// export default CirclePage;
