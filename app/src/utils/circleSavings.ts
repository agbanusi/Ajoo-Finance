import { ethers } from "ethers";
import circleSavings from "../abis/savings.circle.sol/CircleSavings.json";

// Replace with your contract's ABI
const contractABI = circleSavings.abi;

export function createCircleSavingsInterface(
  provider: ethers.providers.Provider,
  contractAddress: string
) {
  const contract = new ethers.Contract(contractAddress, contractABI, provider);

  return {
    // View functions
    tokenData(): string {
      return contract.interface.encodeFunctionData("token");
    },

    periodDurationData(): string {
      return contract.interface.encodeFunctionData("periodDuration");
    },

    contributionAmountData(): string {
      return contract.interface.encodeFunctionData("contributionAmount");
    },

    startTimeData(): string {
      return contract.interface.encodeFunctionData("startTime");
    },

    currentPeriodData(): string {
      return contract.interface.encodeFunctionData("currentPeriod");
    },

    cycleLengthData(): string {
      return contract.interface.encodeFunctionData("cycleLength");
    },

    memberListData(index: number): string {
      return contract.interface.encodeFunctionData("memberList", [index]);
    },

    membersData(address: string): string {
      return contract.interface.encodeFunctionData("members", [address]);
    },

    selectedData(address: string): string {
      return contract.interface.encodeFunctionData("selected", [address]);
    },

    totalContributedData(): string {
      return contract.interface.encodeFunctionData("totalContributed");
    },

    protocolTaxRateData(): string {
      return contract.interface.encodeFunctionData("protocolTaxRate");
    },

    taxCollectorData(): string {
      return contract.interface.encodeFunctionData("taxCollector");
    },

    randomResultData(): string {
      return contract.interface.encodeFunctionData("randomResult");
    },

    selectedWithdrawerData(): string {
      return contract.interface.encodeFunctionData("selectedWithdrawer");
    },

    withdrawerSelectedData(): string {
      return contract.interface.encodeFunctionData("withdrawerSelected");
    },

    // State-changing functions
    addMemberData(member: string): string {
      return contract.interface.encodeFunctionData("addMember", [member]);
    },

    removeMemberData(member: string): string {
      return contract.interface.encodeFunctionData("removeMember", [member]);
    },

    startCycleData(contributionAmount: ethers.BigNumber): string {
      return contract.interface.encodeFunctionData("startCycle", [
        contributionAmount,
      ]);
    },

    contributeData(): string {
      return contract.interface.encodeFunctionData("contribute");
    },

    triggerAutoSaveData(member: string): string {
      return contract.interface.encodeFunctionData("triggerAutoSave", [member]);
    },

    withdrawData(): string {
      return contract.interface.encodeFunctionData("withdraw");
    },

    setTokenData(newToken: string): string {
      return contract.interface.encodeFunctionData("setToken", [newToken]);
    },

    setPeriodDurationData(newDuration: ethers.BigNumber): string {
      return contract.interface.encodeFunctionData("setPeriodDuration", [
        newDuration,
      ]);
    },

    getCurrentPeriodData(): string {
      return contract.interface.encodeFunctionData("getCurrentPeriod");
    },

    getMemberCountData(): string {
      return contract.interface.encodeFunctionData("getMemberCount");
    },

    getEligibleWithdrawerData(): string {
      return contract.interface.encodeFunctionData("getEligibleWithdrawer");
    },

    updateVRFSubscriptionData(subscriptionId: ethers.BigNumber): string {
      return contract.interface.encodeFunctionData("updateVRFSubscription", [
        subscriptionId,
      ]);
    },

    updateCallbackGasLimitData(callbackGasLimit: number): string {
      return contract.interface.encodeFunctionData("updateCallbackGasLimit", [
        callbackGasLimit,
      ]);
    },

    // Helper function to decode function results
    decodeFunctionResult(functionName: string, result: string): any {
      return contract.interface.decodeFunctionResult(functionName, result);
    },
  };
}
