# AgentTip — Smart Contract

Tip BNB to Agent ID holders by their readable name (e.g. `pavelryan.ai`).
Built for the Binance Wallet × BNB Chain **Agent ID Hackathon** (submission period
18 Nov – 9 Dec 2026).

## How it works

1. Anyone can send a tip — there is no sender check. The recipient must hold
   an Agent ID: the name must resolve to an address with `balanceOf > 0` on the
   Agent ID contract (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, SPACE ID Agent ID,
   ERC-721), otherwise the tip reverts with `NameNotRegistered`.
2. The recipient name is resolved on-chain:
   `tokenId = uint256(keccak256(label))`, where `label` is the lowercase name
   without the `.ai` suffix. `ownerOf(tokenId)` gives the recipient address.
   This was proven against BSC mainnet before the contract was written
   (see `../RESEARCH.md`): `ownerOf(keccak256("pavelryan"))` returns
   `0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92` (the owner of `pavelryan.ai`).
3. The full `msg.value` is forwarded to the recipient. Nothing stays in the contract.
4. A `Tip(sender, recipientName, recipient, amount)` event is emitted.

## Design choices (red-line compliance)

- **No owner, no fees, no admin functions, no pause, no upgrade.** The contract
  cannot hold or move user funds by itself; there is no withdraw function.
- **Payments only.** The recipient address is shown to the user as a
  payment-destination preview before they confirm in their own wallet.
  AgentTip is NOT a tool for looking up other people's wallets by name.
- **No promised returns.** Tipping is a one-way payment. There is no yield,
  no passive income, no token.
- **No Binance/BNB branding** in the project name or (future) domain.
- **Reentrancy-safe:** OpenZeppelin `ReentrancyGuard` + checks-effects-interactions;
  the tip is sent with a low-level `call` so contract wallets can receive it.
- **Name normalization:** input is lowercased, trimmed, and accepts the name with
  or without the `.ai` suffix (`PAVELRYAN.AI`, `pavelryan`, `  pavelryan.ai  `
  all resolve to the same owner). Invalid names revert with `InvalidName`;
  unregistered names revert with `NameNotRegistered`.

## Contract

| Item | Value |
|---|---|
| Source | `src/AgentTip.sol` (Solidity 0.8.20, optimizer on, 200 runs) |
| Agent ID contract (BSC) | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` |
| AgentTip address (BSC) | **0x5475d04287A41707DBd68B7D5cc4b557C88A7006** (v2, deployed 2026-11-19, tx 0x271fbd91d0c8927a84b46636decb7d7b56282b53ac53c67af85689f21c0b6136; v1 0x77f0f9fc39664de8ade5063ac32c8a199f330896 superseded) |
| Bytecode size | 2,638 bytes |
| Deployment gas (measured on local anvil) | **606,471 gas** (v2 redeploy 2026-11-19; v1 used 614,699 gas) |
| Deployment cost at BSC gas price 0.05 gwei (19 Nov 2026) | ~0.0000303 BNB (~$0.02 at $588.61/BNB) |
| Tip call gas | < ~70,000 gas (inside fork-test total of 71,547) |

## Build & test

```shell
forge build
forge test            # 13 unit tests (mock Agent ID) + 4 fork tests (real BSC state)
```

Fork tests read live BSC state via `https://bsc-dataseed.binance.org` and verify
the real test vector: `resolveName("pavelryan.ai") == 0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92`
and a full tip from that address on the fork.

## Deploy (v2 redeployed 2026-11-19 — simulation-first, then broadcast)

```shell
# 1. Dry-run the deployment simulation first and confirm the exact gas cost.
forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed.binance.org
# 2. Deploy + verify on BscScan (needs the deployer's explicit approval for the exact gas cost).
forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed.binance.org --broadcast --verify --etherscan-api-key <BSCSCAN_API_KEY>
```

## Verify on BscScan

After deployment, verify the source on BscScan (flat source or standard JSON)
so the hackathon's "source code verified" requirement is met, then update the
`AgentTip address (BSC)` row above and `AGENT_TIP_ADDRESS` in `../frontend/index.html`.
