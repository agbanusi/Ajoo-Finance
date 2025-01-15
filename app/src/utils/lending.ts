import { ethers } from "ethers";
import microLending from "../abis/MicroLending.sol/MicroLending.json";
import microLendingFactory from "../abis/MicroLendingFactory.sol/MicroLendingFactory.json";

// Replace with your contract's ABI
const contractABI = microLending.abi;
const contractFactoryABI = microLendingFactory.abi;

export function createMicroLendingInterface(
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
    getLendingTokenData() {
      return contract.interface.encodeFunctionData("lendingToken");
    },

    getContributionAmountData() {
      return contract.interface.encodeFunctionData("contributionAmount");
    },

    getMemberBalanceData(address: string) {
      return contract.interface.encodeFunctionData("memberBalance", [address]);
    },

    getLoanRequestData(loanId: string) {
      return contract.interface.encodeFunctionData("loanRequests", [loanId]);
    },

    isContributionUpToDateData(address: string) {
      return contract.interface.encodeFunctionData("isContributionUpToDate", [
        address,
      ]);
    },

    factoryLendingCircle(id: number) {
      return contractFactory.interface.encodeFunctionData("lendingCircles", [
        id,
      ]);
    },

    // State-changing functions
    createLendingCircle(
      creatorAddress: string,
      token: string,
      contributionAmount: number,
      period: number,
      initialRate: number
    ) {
      return contractFactory.interface.encodeFunctionData(
        "createMicroLending",
        [creatorAddress, token, contributionAmount, period, initialRate * 100]
      );
    },

    requestMembershipData() {
      return contract.interface.encodeFunctionData("requestMembership");
    },

    contributeData() {
      return contract.interface.encodeFunctionData("contribute");
    },

    requestLoanData(amount: string, duration: string) {
      return contract.interface.encodeFunctionData("requestLoan", [
        amount,
        duration,
      ]);
    },

    voteData(loanId: string, inFavor: boolean) {
      return contract.interface.encodeFunctionData("vote", [loanId, inFavor]);
    },

    executeLoanData(loanId: string) {
      return contract.interface.encodeFunctionData("executeLoan", [loanId]);
    },

    repayLoanData(loanId: string, amount: string) {
      return contract.interface.encodeFunctionData("repayLoan", [
        loanId,
        amount,
      ]);
    },

    withdrawInterestData() {
      return contract.interface.encodeFunctionData("withdrawInterest");
    },

    withdrawBalanceData(amount: string) {
      return contract.interface.encodeFunctionData("withdrawBalance", [amount]);
    },

    // Helper function to decode function results
    decodeFunctionResult(functionName: string, result: any) {
      return contract.interface.decodeFunctionResult(functionName, result);
    },
  };
}
