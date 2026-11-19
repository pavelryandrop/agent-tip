# AgentTip

Tip BNB to any Agent ID holder by their readable name — e.g. `pavelryan.ai`.
No fees. No admin. No account. Just a payment.

Built for the **Binance Wallet × BNB Chain Agent ID Hackathon**
(submission period 18 Nov – 9 Dec 2026, 60,000 USDC in rewards).

## What it is

Agent ID is an on-chain name for an Agentic Wallet (`name.ai`), issued as a
non-transferable NFT by the SPACE ID Agent ID contract on BNB Chain.
Remembering `0x358e…` is hard; remembering `pavelryan.ai` is easy.
AgentTip lets any Agent ID holder send a BNB tip to another holder by typing
their name — the contract resolves the name to the owner's wallet on-chain
and forwards the full amount.

## How it works

1. Connect a wallet holding an Agent ID (the contract checks
   `balanceOf(msg.sender) > 0` on the Agent ID contract).
2. Type the recipient's name (`pavelryan.ai`) and an amount.
3. Preview the resolved destination address **before** confirming in your wallet.
4. Confirm. The contract sends the full amount to the recipient and emits a
   public `Tip` event. Nothing is kept, no fee is taken.

Name resolution (proven against live BSC state, see `RESEARCH.md`):

```
tokenId = uint256(keccak256(label))   # label = lowercase name without ".ai"
owner   = AgentID.ownerOf(tokenId)
```

## Architecture

| Piece | Location |
|---|---|
| Smart contract | `contracts/src/AgentTip.sol` (Solidity 0.8.20, OpenZeppelin ReentrancyGuard) |
| Tests | `contracts/test/` — 13 unit tests (mock Agent ID) + 3 fork tests (real BSC state), 16/16 passing |
| Frontend | `frontend/index.html` — static site (GitHub Pages), ethers.js, no backend |
| Research notes | `RESEARCH.md` — on-chain proofs, submission-channel status, red-line compliance |
| Submission draft | `SUBMISSION-DRAFT.md` |

## Addresses (BNB Chain, chain 56)

| Contract | Address |
|---|---|
| Agent ID (SPACE ID) | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` |
| AgentTip | `0x77f0f9fc39664de8ade5063ac32c8a199f330896` (BSC, deployed 2026-11-19) |

## Agent ID usage

- **Access control:** only Agent ID holders can call `tipByName` — enforced
  on-chain via `balanceOf` on the Agent ID contract.
- **Payments:** the core use case — tipping by human-readable name instead of
  a 0x address, with the destination previewed before the user confirms.
- **Identity:** the sender's and recipient's Agent ID names are recorded in the
  public `Tip` event, so the feed is verifiable by anyone on BscScan.

## Safety

- No owner, no fees, no admin functions, no pause, no upgrade — the contract
  cannot move or hold user funds on its own.
- No promised returns, no yield, no token. Tips are one-way payments and are
  irreversible.
- The recipient address is shown only as a payment-destination confirmation.
  AgentTip is not a directory or a name-to-wallet lookup tool.
- Source is MIT licensed and public; the deployed bytecode is verified on BscScan.

## Run it locally

```shell
# Frontend: serve the static site
cd frontend && python3 -m http.server 8000

# Contracts: build + test
cd contracts && forge build && forge test
```

## Deploy

Deployment is a separate, explicitly approved step (it costs gas — measured
**614,699 gas**, ~$0.02 at the 0.05 gwei gas price seen on 2026-11-19).
See `contracts/README.md` for the simulation-first deploy procedure.

## License

MIT.
