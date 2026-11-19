// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AgentTip} from "../src/AgentTip.sol";

/// @notice Controllable stand-in for the SPACE ID Agent ID ERC-721.
/// @dev tokenId = uint256(keccak256(label)), mirroring the real contract.
contract MockAgentID {
    mapping(uint256 => address) public owners;
    mapping(address => uint256) public balances;

    function setOwner(string memory label, address owner) external {
        uint256 id = uint256(keccak256(bytes(label)));
        address prev = owners[id];
        if (prev != address(0) && prev != owner) {
            balances[prev] -= 1;
        }
        if (prev != owner) {
            owners[id] = owner;
            balances[owner] += 1;
        }
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "ERC721: nonexistent token");
        return owner;
    }
}

/// @notice A recipient that accepts BNB normally.
contract GoodRecipient {
    receive() external payable {}
}

/// @notice A recipient that tries to re-enter tipByName from its receive().
/// @dev The sender needs no Agent ID, so the re-entry reaches the
///      ReentrancyGuard directly. The re-entry is wrapped in try/catch so the
///      test can observe that the guard blocked it while the legitimate outer
///      tip still completes exactly once.
contract ReentrantAttacker {
    AgentTip public immutable tip;
    uint256 public entries;
    bool public reentrySucceeded;

    constructor(AgentTip _tip) {
        tip = _tip;
    }

    receive() external payable {
        entries++;
        if (entries == 1) {
            try tip.tipByName{value: 0.01 ether}("alice.ai") {
                reentrySucceeded = true;
            } catch {
                reentrySucceeded = false;
            }
        }
    }
}

contract AgentTipTest is Test {
    MockAgentID mock;
    AgentTip tip;

    address holder = makeAddr("holder");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address stranger = makeAddr("stranger");

    event Tip(address indexed sender, string recipientName, address indexed recipient, uint256 amount);

    function setUp() public {
        mock = new MockAgentID();
        tip = new AgentTip(address(mock));
        mock.setOwner("holder", holder);
        mock.setOwner("alice", alice);
        mock.setOwner("bob", bob);
        vm.deal(holder, 10 ether);
        vm.deal(stranger, 10 ether);
    }

    // ---- resolution ----

    function testResolveName() public view {
        assertEq(tip.resolveName("alice.ai"), alice);
        assertEq(tip.resolveName("alice"), alice);
        assertEq(tip.resolveName("ALICE.AI"), alice);
        assertEq(tip.resolveName("Alice.Ai"), alice);
        assertEq(tip.resolveName("  alice.ai  "), alice);
        assertEq(tip.resolveName("bob.ai"), bob);
    }

    function testResolveNameUnregistered() public view {
        assertEq(tip.resolveName("nobody.ai"), address(0));
        assertEq(tip.resolveName(""), address(0));
        assertEq(tip.resolveName(".ai"), address(0));
        assertEq(tip.resolveName("a.b.ai"), address(0));
        assertEq(tip.resolveName("   "), address(0));
    }

    function testIsHolder() public view {
        assertTrue(tip.isAgentIDHolder(holder));
        assertTrue(tip.isAgentIDHolder(alice));
        assertFalse(tip.isAgentIDHolder(stranger));
        assertFalse(tip.isAgentIDHolder(address(0)));
    }

    // ---- tipping ----

    function testTipSuccess() public {
        uint256 before = alice.balance;
        vm.expectEmit(true, true, false, true, address(tip));
        emit Tip(holder, "alice.ai", alice, 0.1 ether);
        vm.prank(holder);
        tip.tipByName{value: 0.1 ether}("alice.ai");
        assertEq(alice.balance, before + 0.1 ether);
        assertEq(address(tip).balance, 0, "contract must never hold funds");
    }

    function testTipWithoutSuffixAndUppercase() public {
        uint256 before = alice.balance;
        vm.prank(holder);
        tip.tipByName{value: 0.05 ether}("ALICE");
        assertEq(alice.balance, before + 0.05 ether);
    }

    function testTipToSelf() public {
        uint256 before = holder.balance;
        vm.prank(holder);
        tip.tipByName{value: 0.1 ether}("holder.ai");
        assertEq(holder.balance, before, "self-tip returns the funds minus gas");
    }

    function testTipToContractRecipient() public {
        GoodRecipient good = new GoodRecipient();
        mock.setOwner("good", address(good));
        vm.prank(holder);
        tip.tipByName{value: 0.2 ether}("good.ai");
        assertEq(address(good).balance, 0.2 ether);
    }

    function testTipFromNonHolder() public {
        // Anyone can tip — the sender needs no Agent ID; only the recipient must hold one.
        uint256 before = alice.balance;
        vm.expectEmit(true, true, false, true, address(tip));
        emit Tip(stranger, "alice.ai", alice, 0.1 ether);
        vm.prank(stranger);
        tip.tipByName{value: 0.1 ether}("alice.ai");
        assertEq(alice.balance, before + 0.1 ether);
        assertEq(address(tip).balance, 0, "contract must never hold funds");
    }

    function testTipRevertsUnregistered() public {
        vm.prank(holder);
        vm.expectRevert(AgentTip.NameNotRegistered.selector);
        tip.tipByName{value: 0.1 ether}("ghost12345.ai");
    }

    function testTipRevertsZeroValue() public {
        vm.prank(holder);
        vm.expectRevert(AgentTip.EmptyTip.selector);
        tip.tipByName{value: 0}("alice.ai");
    }

    function testTipRevertsInvalidName() public {
        vm.prank(holder);
        vm.expectRevert(AgentTip.InvalidName.selector);
        tip.tipByName{value: 0.1 ether}(".ai");
        vm.prank(holder);
        vm.expectRevert(AgentTip.InvalidName.selector);
        tip.tipByName{value: 0.1 ether}("");
    }

    // ---- reentrancy ----

    function testReentrancyBlocked() public {
        ReentrantAttacker attacker = new ReentrantAttacker(tip);
        mock.setOwner("attacker", address(attacker));
        vm.deal(address(attacker), 1 ether);

        uint256 attackerBefore = address(attacker).balance;
        uint256 holderBefore = holder.balance;
        uint256 aliceBefore = alice.balance;

        // Legitimate outer tip must succeed exactly once; the re-entry inside
        // receive() must be blocked by ReentrancyGuard (caught, not fatal).
        vm.prank(holder);
        tip.tipByName{value: 0.1 ether}("attacker.ai");

        assertEq(attacker.entries(), 1, "receive ran once");
        assertFalse(attacker.reentrySucceeded(), "re-entrant tip must be blocked");
        assertEq(address(attacker).balance, attackerBefore + 0.1 ether, "exactly one tip lands");
        assertEq(alice.balance, aliceBefore, "re-entrant tip must not pay alice");
        assertEq(holder.balance, holderBefore - 0.1 ether, "holder pays exactly once");
        assertEq(address(tip).balance, 0);
    }

    // ---- no admin surface ----

    function testNoFundsTrapped() public {
        // Even a forced plain BNB transfer cannot be recovered by anyone:
        // the contract has no withdraw/owner function by design.
        vm.deal(address(tip), 1 ether);
        assertEq(address(tip).balance, 1 ether);
        // No admin function exists to move it; assert the contract exposes no owner.
        (bool ok,) = address(tip).staticcall(abi.encodeWithSignature("owner()"));
        assertFalse(ok, "no owner() function must exist");
    }
}
