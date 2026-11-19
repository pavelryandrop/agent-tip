# AgentTip — Research Notes (Phase 1)

All findings below were verified on-chain or from the official announcement
on 2026-11-19. Nothing in the contract design rests on an unverified assumption.

## 1. Hackathon facts

- **Organizers:** Binance Wallet + BNB Chain — "Agent ID Hackathon".
- **Announcement:** https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf
  (published 2026-11-18; full text read, lines 0–277 — the tail is only T&Cs boilerplate).
- **Submission period:** 2026-11-18 08:00 UTC → 2026-12-09 08:00 UTC (15:00 WIB).
- **Prizes:** 60,000 USDC total — Pioneer Award 29,000 (top 10 by on-chain metrics:
  interacting Agent ID addresses, tx volume/count), Innovation Award 29,000
  (top 10 by judging panel; product must be live with **≥ 30 Agent ID addresses**
  interacting during the submission period), Community Promotion 2,000 (20 winners × 100 USDC for X posts).
- **Requirements:** contracts on BNB Chain, source verified on BscScan, public
  open-source code, actively uses Agent ID for a real use case (payments named explicitly).
- **Agent ID contract (BSC):** `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`
  (SPACE ID Agent ID, ERC-721, non-transferable, symbol AI). Holder check:
  `balanceOf(address) > 0`.

## 2. Submission channel — OPEN, not yet public

- The announcement says: "Submit your project name, website, contract address(es),
  Agent ID usage description, and other required materials during the Submission Period.
  No registration needed." — **but it contains no submission link or form URL.**
- Two web searches (2026-11-19) found no public project-submission form. The only
  survey link in the announcement is the **community-promotion** survey
  (app.binance.com), which is for X-post links, not project submissions.
- Precedent: Binance's earlier "My Agent ID" story campaign used a
  `binance.com/en/survey/...` link. The project submission is most likely also a
  Binance survey form, to be published via the Binance Square post or @BinanceWallet on X.
- **Action:** monitor the Square post
  (https://www.binance.com/en/square/post/389517345917641) and @BinanceWallet for
  the submission link. Fields to prepare (per announcement + T&Cs): project name,
  website, contract address(es), Agent ID usage description, other required materials,
  **reward receiving address** (T&Cs: "Rewards will be sent to the reward receiving
  address provided during project submission").

## 3. Name resolution — PROVEN on-chain

Question: how does `nama.ai` map to a wallet address?

### Proven mechanism: tokenId = uint256(keccak256(label))

`label` = the name without `.ai`, lowercase. The Agent ID NFT's tokenId is the
keccak256 hash of the label; `ownerOf(tokenId)` returns the owner's address.

Evidence (BSC mainnet, `cast call` against `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`,
RPC `https://bsc-dataseed.binance.org`, 2026-11-19):

| Check | Result |
|---|---|
| `balanceOf(0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92)` | `1` (Pavel holds an Agent ID) |
| `name()` / `symbol()` | `"SPACE ID Agent ID"` / `"AI"` |
| `keccak256("pavelryan")` | `0x30d5d0656e27869a68ca3a5e8806b454fcb7c11d0ead951c133e44081a18d2ad` |
| `ownerOf(uint256(keccak256("pavelryan")))` | **`0x358e42fD1aA6097BdCBFe86424Dcc4D5633E0a92`** ✅ (== owner of `pavelryan.ai`) |
| `ownerOf(uint256(namehash("pavelryan.ai")))` | **reverts** `ERC721NonexistentToken` — namehash is NOT the tokenId ❌ (alternative ruled out) |
| `tokenURI(tokenId)` | `https://agentid.prd.space.id/metadata/pavelryan.json` |
| `keccak256("pavelryan")` as decimal | `22088793454589940375519420172041164188932617518293884152363547042427837141677` — **identical** to the tokenId embedded in the metadata image URL ✅ (independent cross-check) |
| Metadata JSON | `{"name": "pavelryan", "image": "https://agentid-nft.prd.space.id/prd/<tokenId>/image.png", "description": "Binance Agent Id"}` |

The same resolution is re-proven by the Foundry fork tests
(`contracts/test/AgentTipFork.t.sol`), which run against live BSC state.

### Reverse lookup (address → name) — limited, and how the frontend handles it

| Option | Verdict |
|---|---|
| `tokenOfOwnerByIndex(address, 0)` | **Not implemented** — call reverts; `supportsInterface(0x780e9d63)` (ERC721Enumerable) = `false`. |
| `tokenURI(tokenId)` → metadata `name` | Works, but needs the tokenId first. |
| Public SPACE ID reverse API for `.ai` | **None found** (web search 2026-11-19 returned only Unstoppable Domains docs, not applicable to SPACE ID `.ai`). No reverse registrar verified for Agent ID. |
| **Chosen approach (frontend)** | **Primary:** the user types their own Agent ID name; the frontend verifies on-chain that `ownerOf(keccak256(label)) == connected address`. No reverse lookup needed. **Optional:** BscScan API `tokennfttx` (free API key) can fetch the user's Agent ID tokenId from transfer history → `tokenURI` → metadata name, to pre-fill the name. |

## 4. Red lines (from the announcement) and how the design complies

| Red line | Compliance |
|---|---|
| No web-based QR code login / no storing login sessions | Frontend uses only the user's own injected wallet (MetaMask); no sessions stored server-side (there is no server). |
| No prompts that bypass user transaction confirmation | Every tip is a transaction the user reviews and confirms in their own wallet; the recipient address is previewed before confirming. |
| No unauthorized / scheduled / bundled transfers, no unlimited approvals | The contract moves funds only inside the single `tipByName` call the user signed, for exactly `msg.value`, to exactly the resolved recipient. No approvals are requested anywhere. |
| Contracts open-source, owner permissions disclosed | MIT, public repo; there are **no** owner permissions — no owner, no admin functions at all. |
| No impersonation of the Binance brand | Project name "AgentTip", no "Binance"/"BNB" in the name or (future) domain. |
| No collection of seed phrases / private keys / API secrets | Nothing of the kind is asked for or stored. |
| No promised returns ("passive income", "automatic money-making") | Tipping is a one-way payment; no yield, no token, no returns promised anywhere. |
| Trading products must display risk warnings | AgentTip is not a trading product; the site still states plainly that tips are irreversible. |
| Agent ID must not be packaged as a "look up other people's wallets by name" tool | The product is **payments**: the recipient address is shown only as a payment-destination confirmation before the user confirms. There is no name-search/directory feature. |
| No abnormal behavior (fake volume, mass fake accounts) | Real usage only; no farming, no bots. The 30-holder threshold must be reached with genuine users. |

## 5. Costs measured 2026-11-19

- BSC gas price (public RPC): **0.05 gwei** (`cast gas-price`).
- BNB price: **$588.61** (CoinGecko).
- AgentTip deployment gas (measured by deploying to local anvil): **614,699 gas**
  → ~0.0000307 BNB ≈ **$0.02** at 0.05 gwei; ~$0.36 at a conservative 1 gwei.
  The deployer's wallet (BSC) holds 0.002352 BNB (~$1.39) — enough, with the exact
  figure to be confirmed by simulation immediately before deployment.
- Tip call: < ~70,000 gas (inside fork-test total of 71,547) → ~$0.002 at 0.05 gwei.
