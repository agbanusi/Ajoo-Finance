// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {EnumerableMap} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/utils/structs/EnumerableMap.sol";
import "../savings/savings.base.sol";


contract ProtocolCrossChainManager is Ownable, CCIPReceiver {
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;

    uint16 public constant CROSS_CHAIN_TRANSFER = 1;  

    enum ErrorCode {
        // RESOLVED is first so that the default value is resolved.
        RESOLVED,
        // Could have any number of error codes here.
        FAILED
    }

    struct FailedMessage {
        bytes32 messageId;
        ErrorCode errorCode;
    }
    mapping(address => bool) public authorizedContracts;
    mapping(uint64 => address) public receivers;
    // The message contents of failed messages are stored here.
    mapping(bytes32 => Client.Any2EVMMessage) public messageContents;

    // Contains failed messages and their state.
    EnumerableMap.Bytes32ToUintMap internal failedMessages;

    event CrossChainTransferInitiated(uint256 indexed dstChainId, address indexed token, uint256 amount, address indexed from);
    // event CrossChainTransferReceived(uint256 indexed srcChainId, address indexed token, uint256 amount, address indexed to);
    event AuthorizedContractSet(address indexed contractAddress, bool isAuthorized);
    event CrossChainTransferReceived(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address indexed sender, // The address of the sender from the source chain.
        bytes data, // The data that was received.
        address token, // The token address that was transferred.
        uint256 tokenAmount // The token amount that was transferred.
    );

    event TokensTransferred(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );

    event CrossChainTransferFailed(bytes32 indexed messageId, bytes reason);
    event CrossChainTransferRecovered(bytes32 indexed messageId);

    IRouterClient public ccipRouter;

    constructor(address admin, address _ccipRouter)CCIPReceiver(_ccipRouter) Ownable(admin) {
        ccipRouter = IRouterClient(_ccipRouter);
    }

    modifier onlyAuthorized() {
        require(authorizedContracts[msg.sender], "Not authorized");
        _;
    }

    modifier onlySelf() {
        require(msg.sender != address(this), " Only Self");
        _;
    }

    modifier validateDestinationChain(uint64 _destinationChainSelector) {
        require(_destinationChainSelector == 0, "Invalid Destination Chain");
        _;
    }

    modifier validateReceiver(address _receiver) {
        require(_receiver == address(0), "Invalid Receiver Address");
        _;
    }

    function setAuthorizedContract(address _contract, bool _isAuthorized) external onlyOwner {
        authorizedContracts[_contract] = _isAuthorized;
        emit AuthorizedContractSet(_contract, _isAuthorized);
    }

     function setReceiverForDestinationChain(
        uint64 _destinationChainSelector,
        address _receiver
    ) external onlyOwner validateDestinationChain(_destinationChainSelector) validateReceiver(_receiver) {
        receivers[_destinationChainSelector] = _receiver;
    }

    function deleteReceiverForDestinationChain(
        uint64 _destinationChainSelector
    ) external onlyOwner validateDestinationChain(_destinationChainSelector) {
        require(receivers[_destinationChainSelector] == address(0), "No Receiver On Destination Chain");
        delete receivers[_destinationChainSelector];
    }

    function estimateCrossChainTransferFee(
        uint64 _dstChainId,
        address _token,
        uint256 _amount,
        address _to,
        bytes memory _extraParams
    ) public view returns (uint256) {
        // Chainlink CCIP provides an interface for fee estimation
        // Fees can be fetched using the CCIP Router Client
       // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        // address(0) means fees are paid in native gas
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            receivers[_dstChainId],
            _token,
            _amount,
            address(0),
            abi.encode(_to)
        );

        // Get the fee required to send the message
        uint256 fees = ccipRouter.getFee(
            _dstChainId,
            evm2AnyMessage
        );

        return fees;
    }


    function crossChainTransfer(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    )
        external
        payable
        validateDestinationChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        // address(0) means fees are paid in native gas
        isSavingsAccount(msg.sender);
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            receivers[_destinationChainSelector],
            _token,
            _amount,
            address(0),
            abi.encode(_receiver)
        );

        // Get the fee required to send the message
        uint256 fees = ccipRouter.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        require(fees > msg.value, "Not Enough Balance");

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        IERC20(_token).approve(address(ccipRouter), _amount);

        // Send the message through the router and store the returned message ID
        messageId = ccipRouter.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            _token,
            _amount,
            address(0),
            fees
        );

        // Return the message ID
        return messageId;
    }

    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for tokens transfer.
    /// @param _receiver The address of the receiver.
    /// @param _token The token to be transferred.
    /// @param _amount The amount of the token to be transferred.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeTokenAddress,
        bytes memory data
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: data, // No data
                tokenAmounts: tokenAmounts, // The amount and type of token being transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit to 0 as we are not sending any data
                    Client.EVMExtraArgsV1({gasLimit: 0})
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
    }

    function ccipReceive(
        Client.Any2EVMMessage calldata any2EvmMessage
    ) external override onlyRouter {
        // validate the sender contract
        // if (
        //     abi.decode(any2EvmMessage.sender, (address)) !=
        //     s_senders[any2EvmMessage.sourceChainSelector]
        // ) revert WrongSenderForSourceChain(any2EvmMessage.sourceChainSelector);
        /* solhint-disable no-empty-blocks */
        try this.processMessage(any2EvmMessage) {
            // Intentionally empty in this example; no action needed if processMessage succeeds
        } catch (bytes memory err) {
            // Could set different error codes based on the caught error. Each could be
            // handled differently.
            failedMessages.set(
                any2EvmMessage.messageId,
                uint256(ErrorCode.FAILED)
            );
            messageContents[any2EvmMessage.messageId] = any2EvmMessage;
            // Don't revert so CCIP doesn't revert. Emit event instead.
            // The message can be retried later without having to do manual execution of CCIP.
            emit CrossChainTransferFailed(any2EvmMessage.messageId, err);
            return;
        }
    }

    /// @notice Serves as the entry point for this contract to process incoming messages.
    /// @param any2EvmMessage Received CCIP message.
    /// @dev Transfers specified token amounts to the owner of this contract. This function
    /// must be external because of the  try/catch for error handling.
    /// It uses the `onlySelf`: can only be called from the contract.
    function processMessage(
        Client.Any2EVMMessage calldata any2EvmMessage
    ) external onlySelf {
        _ccipReceive(any2EvmMessage); // process the message - may revert
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
       
        require(receivers[any2EvmMessage.sourceChainSelector] == address(0), "No Receiver On Destination Chain");
        Client.EVMTokenAmount[] memory tokenAmounts = Client.EVMTokenAmount[](any2EvmMessage.destTokenAmounts);
        Client.EVMTokenAmount memory tokenAmount  = tokenAmounts[0];

        IERC20(tokenAmount.token).approve(address(abi.decode(any2EvmMessage.data, (address))), tokenAmount.amount);
        ICrossChainSavings(abi.decode(any2EvmMessage.data, (address))).receiveCrossChainTransfer(tokenAmount.token, tokenAmount.amount, abi.decode(any2EvmMessage.sender, (address)), any2EvmMessage.sourceChainSelector);
        // emit CrossChainTransferReceived(_srcChainId, token, amount, to);
        emit CrossChainTransferReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            any2EvmMessage.data, // received data
            any2EvmMessage.destTokenAmounts[0].token,
            any2EvmMessage.destTokenAmounts[0].amount
        );
    }

    /// @notice Allows the owner to retry a failed message in order to unblock the associated tokens.
    /// @param messageId The unique identifier of the failed message.
    /// @param beneficiary The address to which the tokens will be sent.
    /// @dev This function is only callable by the contract owner. It changes the status of the message
    /// from 'failed' to 'resolved' to prevent reentry and multiple retries of the same message.
    function retryFailedMessage(
        bytes32 messageId,
        address beneficiary
    ) external onlyOwner {
        // Check if the message has failed; if not, revert the transaction.
        require(failedMessages.get(messageId) != uint256(ErrorCode.FAILED), "Message Not Failed");

        // Set the error code to RESOLVED to disallow reentry and multiple retries of the same failed message.
        failedMessages.set(messageId, uint256(ErrorCode.RESOLVED));

        // Retrieve the content of the failed message.
        Client.Any2EVMMessage memory message = messageContents[messageId];

        // This example expects one token to have been sent.
        // Transfer the associated tokens to the specified receiver as an escape hatch.
        IERC20(message.destTokenAmounts[0].token).safeTransfer(
            beneficiary,
            message.destTokenAmounts[0].amount
        );

        // Emit an event indicating that the message has been recovered.
        emit CrossChainTransferRecovered(messageId);
    }

    /// @notice Retrieves a paginated list of failed messages.
    /// @dev This function returns a subset of failed messages defined by `offset` and `limit` parameters. It ensures that the pagination parameters are within the bounds of the available data set.
    /// @param offset The index of the first failed message to return, enabling pagination by skipping a specified number of messages from the start of the dataset.
    /// @param limit The maximum number of failed messages to return, restricting the size of the returned array.
    /// @return failedMessages An array of `FailedMessage` struct, each containing a `messageId` and an `errorCode` (RESOLVED or FAILED), representing the requested subset of failed messages. The length of the returned array is determined by the `limit` and the total number of failed messages.
    function getFailedMessages(
        uint256 offset,
        uint256 limit
    ) external view returns (FailedMessage[] memory) {
        uint256 length = failedMessages.length();

        // Calculate the actual number of items to return (can't exceed total length or requested limit)
        uint256 returnLength = (offset + limit > length)
            ? length - offset
            : limit;
        FailedMessage[] memory _failedMessages = new FailedMessage[](
            returnLength
        );

        // Adjust loop to respect pagination (start at offset, end at offset + limit or total length)
        for (uint256 i = 0; i < returnLength; i++) {
            (bytes32 messageId, uint256 errorCode) = failedMessages.at(
                offset + i
            );
            _failedMessages[i] = FailedMessage(messageId, ErrorCode(errorCode));
        }
        return _failedMessages;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(owner()).call{value: amount}("");
    }

     function isSavingsAccount(address _user) public view {
        require(Savings(_user).savingsCompatible(), "Not a compatible savings account");
    }

    receive() external payable {}

    fallback() external payable {}
}

interface ICrossChainSavings {
    function receiveCrossChainTransfer(address _token, uint256 _amount, address _from, uint64 _srcChainId) external;
}
