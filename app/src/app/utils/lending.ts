// import { ethers } from 'ethers';

// // Replace with your contract's ABI
// const contractABI = [/* Insert your contract ABI here */];

// // Replace with your contract's address
// const contractAddress = process;

// export function createMicroLendingInterface(provider, signer, contractAddress:string) {
//   const contract = new ethers.Contract(contractAddress, contractABI, provider);
//   const contractWithSigner = contract.connect(signer);

//   return {
//     // View functions
//     async getLendingToken() {
//       const data = contract.interface.encodeFunctionData('lendingToken');
//       const result = await provider.call({
//         to: contractAddress,
//         data,
//       });
//       return contract.interface.decodeFunctionResult('lendingToken', result)[0];
//     },

//     async getContributionAmount() {
//       const data = contract.interface.encodeFunctionData('contributionAmount');
//       const result = await provider.call({
//         to: contractAddress,
//         data,
//       });
//       return contract.interface.decodeFunctionResult('contributionAmount', result)[0];
//     },

//     async getMemberBalance(address) {
//       const data = contract.interface.encodeFunctionData('memberBalance', [address]);
//       const result = await provider.call({
//         to: contractAddress,
//         data,
//       });
//       return contract.interface.decodeFunctionResult('memberBalance', result)[0];
//     },

//     async getLoanRequest(loanId) {
//       const data = contract.interface.encodeFunctionData('loanRequests', [loanId]);
//       const result = await provider.call({
//         to: contractAddress,
//         data,
//       });
//       return contract.interface.decodeFunctionResult('loanRequests', result);
//     },

//     async isContributionUpToDate(address) {
//       const data = contract.interface.encodeFunctionData('isContributionUpToDate', [address]);
//       const result = await provider.call({
//         to: contractAddress,
//         data,
//       });
//       return contract.interface.decodeFunctionResult('isContributionUpToDate', result)[0];
//     },

//     // State-changing functions
//     async requestMembership() {
//       const data = contractWithSigner.interface.encodeFunctionData('requestMembership');
//       const tx = await signer.sendTransaction({
//         to: contractAddress,
//         data,
//       });
//       return tx;
//     },

//     async contribute() {
//       const data = contractWithSigner.interface.encodeFunctionData('contribute');
//       const tx = await signer.sendTransaction({
//         to: contractAddress,
//         data,
//       });
//       return tx;
//     },

//     async requestLoan(amount, duration) {
//       const data = contractWithSigner.interface.encodeFunctionData('requestLoan', [amount, duration]);
//       const tx = await signer.sendTransaction({
//         to: contractAddress,
//         data,
//       });
//       return tx;
//     },

//     async vote(loanId, inFavor) {
//       const data = contractWithSigner.interface.encodeFunctionData('vote', [loanId, inFavor]);
//       const tx = await signer.sendTransaction({
//         to: contractAddress,
//         data,
//       });
//       return tx;
//     },

//     async executeLoan(loanId) {
//       const data = contractWithSigner.interface.encodeFunctionData('executeLoan', [loanId]);
//       const tx = await signer.sendTransaction({
//         to: contractAddress,
//         data,
//       });
//       return tx;
//     },

//     async repayLoan(loanId, amount) {
//       const data = contractWithSigner.interface.encodeFunctionData('repayLoan', [loanId, amount]);
//       const tx = await signer.sendTransaction({
//         to: contractAddress,
//         data,
//       });
//       return tx;
//     },

//     async withdrawInterest() {
//       const data = contractWithSigner.interface.encodeFunctionData('withdrawInterest');
//       const tx = await signer.sendTransaction({
//         to: contractAddress,
//         data,
//       });
//       return tx;
//     },

//     async withdrawBalance(amount) {
//       const data = contractWithSigner.interface.encodeFunctionData('withdrawBalance', [amount]);
//       const tx = await signer.sendTransaction({
//         to: contractAddress,
//         data,
//       });
//       return tx;
//     },
//   };
// }

import { ethers } from "ethers";
import microLending from "../../abis/MicroLending.sol/MicroLending.json";

// Replace with your contract's ABI
const contractABI = microLending.abi;

export function createMicroLendingInterface(
  provider: any,
  contractAddress: string
) {
  const contract = new ethers.Contract(contractAddress, contractABI, provider);

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

    // State-changing functions
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
