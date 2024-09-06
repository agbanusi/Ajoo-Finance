// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@layerzero-contracts/lzApp/NonblockingLzApp.sol";
import "@layerzero-contracts/lzApp/libs/LzLib.sol";

// import "@layerzerolabs/solidity-examples/contracts/libraries/LzLib.sol";

contract ProtocolCrossChainManager is Ownable, NonblockingLzApp {
    using SafeERC20 for IERC20;

    uint16 public constant CROSS_CHAIN_TRANSFER = 1;

    // mapping(uint16 => bytes) public override trustedRemoteLookup;
    mapping(address => bool) public authorizedContracts;

    event CrossChainTransferInitiated(uint16 indexed dstChainId, address indexed token, uint256 amount, address indexed from);
    event CrossChainTransferReceived(uint16 indexed srcChainId, address indexed token, uint256 amount, address indexed to);
    // event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event AuthorizedContractSet(address indexed contractAddress, bool isAuthorized);

    constructor(address _owner, address _lzEndpoint) Ownable(_owner) NonblockingLzApp(_lzEndpoint) {}

    modifier onlyAuthorized() {
        require(authorizedContracts[msg.sender], "Not authorized");
        _;
    }

    // function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external override onlyOwner {
    //     trustedRemoteLookup[_remoteChainId] = _path;
    //     emit SetTrustedRemote(_remoteChainId, _path);
    // }

    function setAuthorizedContract(address _contract, bool _isAuthorized) external onlyOwner {
        authorizedContracts[_contract] = _isAuthorized;
        emit AuthorizedContractSet(_contract, _isAuthorized);
    }

    function estimateCrossChainTransferFee(uint16 _dstChainId, address _token, uint256 _amount, address _from, address _to, bool _useZro, bytes memory _adapterParams) public view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(CROSS_CHAIN_TRANSFER, _token, _amount, _from, _to);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function crossChainTransfer(
        uint16 _dstChainId,
        address _token,
        uint256 _amount,
        address _from,
        address _to,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) external payable onlyAuthorized {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "Trusted remote not set");

        bytes memory payload = abi.encode(CROSS_CHAIN_TRANSFER, _token, _amount, _from, _to);
        
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);

        emit CrossChainTransferInitiated(_dstChainId, _token, _amount, _from);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal override {
        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        require(trustedRemote.length != 0 && _srcAddress.length == trustedRemote.length, "Invalid source address");
        // require(LzLib.addressToBytes32(_srcAddress) == LzLib.addressToBytes32(trustedRemote), "Invalid source contract");

        (uint16 msgType, address token, uint256 amount, address from, address to) = abi.decode(_payload, (uint16, address, uint256, address, address));

        if (msgType == CROSS_CHAIN_TRANSFER) {
            require(authorizedContracts[to], "Recipient not authorized");
            ICrossChainSavings(to).receiveCrossChainTransfer(token, amount, from, _srcChainId);
            emit CrossChainTransferReceived(_srcChainId, token, amount, to);
        } else {
            revert("Invalid message type");
        }
    }

    // function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
    //     lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    // }

    // LayerZero configuration functions
    // function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external override onlyOwner {
    //     lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    // }

    // function setSendVersion(uint16 _version) external override onlyOwner {
    //     lzEndpoint.setSendVersion(_version);
    // }

    // function setReceiveVersion(uint16 _version) external override onlyOwner {
    //     lzEndpoint.setReceiveVersion(_version);
    // }

    // function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint256 _configType) external override view returns (bytes memory) {
    //     return lzEndpoint.getConfig(_version, _chainId, _userApplication, _configType);
    // }
}

interface ICrossChainSavings {
    function receiveCrossChainTransfer(address _token, uint256 _amount, address _from, uint16 _srcChainId) external;
}