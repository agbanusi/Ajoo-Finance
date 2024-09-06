// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./savings.base.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IProtocolCrossChainManager {
    function crossChainTransfer(
        uint64 _dstChainId,
        address _token,
        uint256 _amount,
        address _from,
        address _to,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) external payable;

    function estimateCrossChainTransferFee(
        uint64 _dstChainId,
        address _token,
        uint256 _amount,
        address _from,
        address _to,
        bool _useZro,
        bytes memory _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

contract CrossChainSavings is Savings {
    using SafeERC20 for IERC20;

    IProtocolCrossChainManager public protocolCrossChainManager;

    event CrossChainTransferInitiated(uint64 indexed dstChainId, address indexed token, uint256 amount);
    event CrossChainTransferReceived(uint64 indexed srcChainId, address indexed token, uint256 amount, address indexed from);

    constructor(
        address _owner,
        address[] memory _acceptedTokens,
        address _protocolCrossChainManager
    ) Savings(_owner, _acceptedTokens) {
        protocolCrossChainManager = IProtocolCrossChainManager(_protocolCrossChainManager);
    }

    function setProtocolCrossChainManager(address _protocolCrossChainManager) external onlyOwner {
        protocolCrossChainManager = IProtocolCrossChainManager(_protocolCrossChainManager);
    }

    function initiateCrossChainTransfer(
        uint64 _dstChainId,
        address _token,
        uint256 _amount,
        address _to,
        bool _useZro,
        bytes memory _adapterParams
    ) external payable onlyOwner {
        require(isTokenAccepted[_token], "Token not accepted");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= tokenSavings[_token], "Insufficient balance");

        (uint256 nativeFee, ) = protocolCrossChainManager.estimateCrossChainTransferFee(
            _dstChainId, _token, _amount, address(this), _to, _useZro, _adapterParams
        );
        require(msg.value >= nativeFee, "Insufficient LayerZero fee");

        tokenSavings[_token] -= _amount;
        IERC20(_token).approve(address(protocolCrossChainManager), _amount);

        protocolCrossChainManager.crossChainTransfer{value: msg.value}(
            _dstChainId,
            _token,
            _amount,
            address(this),
            _to,
            payable(msg.sender),
            address(0),
            _adapterParams
        );

        emit CrossChainTransferInitiated(_dstChainId, _token, _amount);
    }

    function receiveCrossChainTransfer(address _token, uint256 _amount, address _from, uint16 _srcChainId) external {
        require(msg.sender == address(protocolCrossChainManager), "Unauthorized");
        require(isTokenAccepted[_token], "Token not accepted");
        require(_amount > 0, "Amount must be greater than 0");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        tokenSavings[_token] += _amount;
        emit CrossChainTransferReceived(_srcChainId, _token, _amount, _from);
        emit Deposit(msg.sender, _token, _amount);
    }
}