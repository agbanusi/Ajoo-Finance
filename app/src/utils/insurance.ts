import { ethers } from "ethers";
import insuranceCircle from "../abis/MicroInsurance.sol/MicroInsurance.json";
import insuranceCircleFactory from "../abis/MicroInsuranceFactory.sol/MicroInsuranceFactory.json";

// Replace with your contract's ABI
const contractABI = insuranceCircle.abi;
const contractFactoryABI = insuranceCircleFactory.abi;

export function createInsuranceCircleInterface(
  provider: any,
  contractAddress: string,
  factoryAddress?: string
) {
  const contract = new ethers.Contract(contractAddress, contractABI, provider);
  const contractFactory = new ethers.Contract(
    factoryAddress || "",
    contractFactoryABI,
    provider
  );

  return {
    // View functions
    getMemberStatusData(address: string) {
      return contract.interface.encodeFunctionData("members", [address]);
    },

    getClaimData(claimId: number) {
      return contract.interface.encodeFunctionData("claims", [claimId]);
    },

    isPremiumUpToDateData(address: string) {
      return contract.interface.encodeFunctionData("isPremiumUpToDate", [
        address,
      ]);
    },

    getTotalMembersData() {
      return contract.interface.encodeFunctionData("totalMembers");
    },

    getPoolBalanceData() {
      return contract.interface.encodeFunctionData("poolBalance");
    },

    // State-changing functions
    requestMembershipData() {
      return contract.interface.encodeFunctionData("requestMembership");
    },

    approveMembershipData(requester: string) {
      return contract.interface.encodeFunctionData("approveMembership", [
        requester,
      ]);
    },

    rejectMembershipData(requester: string) {
      return contract.interface.encodeFunctionData("rejectMembership", [
        requester,
      ]);
    },

    payPremiumData() {
      return contract.interface.encodeFunctionData("payPremium");
    },

    submitClaimData(amount: number) {
      return contract.interface.encodeFunctionData("submitClaim", [amount]);
    },

    voteOnClaimData(claimId: number, inFavor: boolean) {
      return contract.interface.encodeFunctionData("voteOnClaim", [
        claimId,
        inFavor,
      ]);
    },

    executeClaimData(claimId: number) {
      return contract.interface.encodeFunctionData("executeClaim", [claimId]);
    },

    vetoClaimData(claimId: number) {
      return contract.interface.encodeFunctionData("vetoClaim", [claimId]);
    },

    // Helper function to decode function results
    decodeFunctionResult(functionName: string, result: any) {
      return contract.interface.decodeFunctionResult(functionName, result);
    },

    factoryLendingCircle(id: number) {
      return contractFactory.interface.encodeFunctionData("insuranceCircles", [
        id,
      ]);
    },

    // State-changing functions
    createInsuranceCircle(
      token: string,
      contributionAmount: number,
      period: number,
      votingThresholdRate: number,
      maxClaimAmount: number,
      name: string
    ) {
      return contractFactory.interface.encodeFunctionData(
        "createMicroInsurance",
        [
          token,
          contributionAmount,
          period,
          votingThresholdRate * 100,
          maxClaimAmount,
          name,
        ]
      );
    },
  };
}
