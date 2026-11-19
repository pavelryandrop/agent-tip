// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Minimal interface of the SPACE ID Agent ID ERC-721 (BNB Chain).
interface IAgentID {
    function balanceOf(address account) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title AgentTip
/// @notice Tip BNB to Agent ID holders by their readable name (e.g. `pavelryan.ai`).
/// @dev Payments-only. No owner, no fees, no admin functions, no pause, no upgrade.
///      Anyone can send a tip; the recipient must hold an Agent ID.
///      Name resolution is proven on-chain against the Agent ID contract:
///      tokenId = uint256(keccak256(label)), where label is the lowercase name
///      without the ".ai" suffix. Proof (BSC mainnet, eth_call):
///        ownerOf(uint256(keccak256("pavelryan"))) = 0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92
///        ownerOf(uint256(namehash("pavelryan.ai"))) reverts (namehash is NOT the tokenId)
///        tokenURI(tokenId) = https://agentid.prd.space.id/metadata/pavelryan.json
///      See RESEARCH.md in the repo root for the full evidence.
///      The recipient address is only ever shown to the user as a payment-destination
///      preview before they confirm in their own wallet. This contract is NOT a
///      name-to-wallet lookup tool.
contract AgentTip is ReentrancyGuard {
    /// @notice The SPACE ID Agent ID contract on BNB Chain.
    IAgentID public immutable agentId;

    error EmptyTip();
    error InvalidName();
    error NameNotRegistered();
    error TransferFailed();

    /// @notice Emitted for every successful tip. `recipientName` is the normalized name with ".ai".
    event Tip(address indexed sender, string recipientName, address indexed recipient, uint256 amount);

    constructor(address agentId_) {
        agentId = IAgentID(agentId_);
    }

    /// @notice Resolve an Agent ID name (with or without ".ai", any case) to its owner's address.
    /// @return The owner's address, or address(0) when the name is not registered.
    function resolveName(string calldata name) public view returns (address) {
        return _resolveLabel(_normalize(name));
    }

    /// @notice True when `account` holds at least one Agent ID.
    function isAgentIDHolder(address account) public view returns (bool) {
        return agentId.balanceOf(account) > 0;
    }

    /// @notice Send a BNB tip to the owner of `name`. Anyone can tip;
    ///      the recipient must hold an Agent ID.
    /// @dev Forwards the full msg.value to the resolved owner. No fee is taken and
    ///      no funds ever stay in this contract.
    function tipByName(string calldata name) external payable nonReentrant {
        if (msg.value == 0) revert EmptyTip();
        bytes memory label = _normalize(name);
        if (label.length == 0) revert InvalidName();
        address recipient = _resolveLabel(label);
        if (recipient == address(0)) revert NameNotRegistered();
        (bool ok, ) = payable(recipient).call{value: msg.value}("");
        if (!ok) revert TransferFailed();
        emit Tip(msg.sender, string(abi.encodePacked(label, ".ai")), recipient, msg.value);
    }

    function _resolveLabel(bytes memory label) internal view returns (address) {
        if (label.length == 0) return address(0);
        uint256 tokenId = uint256(keccak256(label));
        try agentId.ownerOf(tokenId) returns (address owner) {
            return owner;
        } catch {
            return address(0);
        }
    }

    /// @dev Lowercase, trim surrounding spaces, strip one trailing ".ai" (case-insensitive).
    ///      Returns empty bytes for an empty label or a label still containing '.'.
    function _normalize(string calldata name) internal pure returns (bytes memory) {
        bytes memory raw = bytes(name);
        uint256 start = 0;
        uint256 end = raw.length;
        while (start < end && _isSpace(raw[start])) start++;
        while (end > start && _isSpace(raw[end - 1])) end--;
        // strip one trailing ".ai" (case-insensitive)
        if (end - start >= 3 && raw[end - 3] == "." && _lower(raw[end - 2]) == "a" && _lower(raw[end - 1]) == "i") {
            end -= 3;
        }
        // validate: non-empty and no '.' left (labels cannot contain dots)
        if (end <= start) return new bytes(0);
        for (uint256 i = start; i < end; i++) {
            if (raw[i] == ".") return new bytes(0);
        }
        // lowercase copy
        bytes memory out = new bytes(end - start);
        for (uint256 i; i < end - start; i++) {
            out[i] = _lower(raw[start + i]);
        }
        return out;
    }

    function _lower(bytes1 c) internal pure returns (bytes1) {
        if (c >= "A" && c <= "Z") return bytes1(uint8(c) + 32);
        return c;
    }

    function _isSpace(bytes1 c) internal pure returns (bool) {
        return c == " " || c == "\t" || c == "\n" || c == "\r";
    }
}
