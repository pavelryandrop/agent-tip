# AgentTip — Hackathon Submission Draft

> Status: DRAFT — fill the TODOs after deployment + GitHub Pages publish.
> The official project-submission form URL was not public as of 2026-11-19;
> see `RESEARCH.md` §2. Check the Binance Square announcement post and
> @BinanceWallet on X for the link, then submit before 2026-12-09 08:00 UTC.

## Project name

AgentTip

## One-line description

Tip BNB to any Agent ID holder by their readable name (e.g. `pavelryan.ai`) —
no fees, no admin, no account. Just a payment.

## Description (for the form)

Agent ID gives every Agentic Wallet a human-readable on-chain name, but
sending value to a name still means copy-pasting a 0x address. AgentTip closes
that gap: anyone types a name, previews the resolved destination
address, confirms in their own wallet, and the contract forwards the full BNB
amount to the name's owner — who must hold an Agent ID. The contract takes no
fee, holds no funds, and has no owner or admin functions. Every tip emits a
public `Tip` event, so activity is verifiable by anyone on BscScan. The product
is live as a static site (no backend, no accounts) with the contract deployed
and source-verified on BNB Chain.

## Website

- GitHub Pages URL: https://pavelryandrop.github.io/agent-tip/ (LIVE 2026-11-19 ~17:25 WIB, branch main, folder /docs)

## Contract address(es) — BNB Chain (chain 56)

- AgentTip: 0x5475d04287A41707DBd68B7D5cc4b557C88A7006 (BSC, v2 redeployed 2026-11-19, tx 0x271fbd91d0c8927a84b46636decb7d7b56282b53ac53c67af85689f21c0b6136; v1 0x77f0f9fc39664de8ade5063ac32c8a199f330896 superseded)
- Agent ID (SPACE ID, reference): `0x60B9262456dE011F7d15a54cdd8c48baaa8B022F`

## Source code (open-source)

- GitHub repo: https://github.com/pavelryandrop/agent-tip (public, MIT license)
- BscScan verification: VERIFIED 2026-11-19 — https://bscscan.com/address/0x5475d04287A41707DBd68B7D5cc4b557C88A7006#code (Sourcify exact match too)

## Agent ID usage description

- **Access control:** anyone can send tips — there is no sender check.
  The recipient must hold an Agent ID: `tipByName` resolves the name and
  reverts (`NameNotRegistered`) unless the resolved owner holds an Agent ID
  (`AgentID.balanceOf(recipient) > 0`).
- **Payments:** the core use case — tipping by human-readable name instead of
  a 0x address. Resolution is `tokenId = uint256(keccak256(label))` +
  `ownerOf(tokenId)` on the Agent ID contract, proven against live BSC state
  (see `RESEARCH.md`; test vector `pavelryan.ai` →
  `0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92`).
- **Identity:** the recipient's Agent ID name and both addresses are recorded
  in the public `Tip(sender, recipientName, recipient, amount)` event, which
  powers the on-site recent-tips feed.

## Reward receiving address

- Reward receiving address: 0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92 (the submitting wallet, `pavelryan.ai`
  holder: `0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92` — confirm before submitting).

## Other materials (checklist)

- [x] Contract deployed on BNB Chain (v2 0x5475d04287A41707DBd68B7D5cc4b557C88A7006, 2026-11-19)
- [x] Source verified on BscScan (v2, 2026-11-19; Sourcify exact match too)
- [ ] Code public on GitHub (MIT)
- [x] Website live (GitHub Pages) — https://pavelryandrop.github.io/agent-tip/
- [ ] 30+ Agent ID addresses interacted during the submission period
      (Innovation Award eligibility) — needs X promotion; track via `Tip` events
- [ ] Screenshots / demo video (optional, if the form asks)
- [ ] X post about the project (community promotion is separate; optional)
