// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AgentTip} from "../src/AgentTip.sol";

/// @notice Fork tests against the REAL Agent ID contract on BSC mainnet.
/// @dev Requires network access to https://bsc-dataseed.binance.org at test time.
///      Run: forge test --match-contract AgentTipForkTest
contract AgentTipForkTest is Test {
    address constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    address constant PAVEL = 0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92;

    AgentTip tip;

    event Tip(address indexed sender, string recipientName, address indexed recipient, uint256 amount);

    function setUp() public {
        vm.createSelectFork("https://bsc-dataseed.binance.org");
        tip = new AgentTip(AGENT_ID);
    }

    function testForkResolvePavelRyan() public view {
        // Test vector from the hackathon task, proven by eth_call before the contract was written.
        assertEq(tip.resolveName("pavelryan.ai"), PAVEL);
        assertEq(tip.resolveName("pavelryan"), PAVEL);
        assertEq(tip.resolveName("PAVELRYAN.AI"), PAVEL);
        assertTrue(tip.isAgentIDHolder(PAVEL));
    }

    function testForkTipPavelSelf() public {
        // Self-tip from Pavel's real address (pranked on the fork): proves the full
        // path real resolution -> transfer -> event against live state.
        vm.deal(PAVEL, 1 ether);
        uint256 before = PAVEL.balance;
        vm.expectEmit(true, true, false, true, address(tip));
        emit Tip(PAVEL, "pavelryan.ai", PAVEL, 0.01 ether);
        vm.prank(PAVEL);
        tip.tipByName{value: 0.01 ether}("pavelryan.ai");
        assertEq(PAVEL.balance, before, "self-tip returns funds minus gas");
        assertEq(address(tip).balance, 0);
    }

    function testForkTipFromNonHolder() public {
        // A random address with no Agent ID can tip Pavel on the fork.
        address stranger = makeAddr("fork-stranger");
        vm.deal(stranger, 1 ether);
        uint256 before = PAVEL.balance;
        vm.expectEmit(true, true, false, true, address(tip));
        emit Tip(stranger, "pavelryan.ai", PAVEL, 0.01 ether);
        vm.prank(stranger);
        tip.tipByName{value: 0.01 ether}("pavelryan.ai");
        assertEq(PAVEL.balance, before + 0.01 ether);
        assertEq(address(tip).balance, 0);
    }

    function testForkUnregisteredName() public view {
        assertEq(tip.resolveName("definitelynotregistered12345.ai"), address(0));
    }
}
