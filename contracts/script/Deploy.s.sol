// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AgentTip} from "../src/AgentTip.sol";

/// @notice Deploy AgentTip to BNB Chain (NOT executed yet — deploy is a separate,
///         user-approved step after simulation).
/// @dev Run: forge script script/Deploy.s.sol --rpc-url <BSC_RPC> --broadcast --verify
///      The deployer must hold enough BNB for gas; see README.md for the estimate.
contract Deploy is Script {
    address constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external returns (AgentTip) {
        vm.startBroadcast();
        AgentTip tip = new AgentTip(AGENT_ID);
        vm.stopBroadcast();
        return tip;
    }
}
