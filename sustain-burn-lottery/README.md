# Sustain-&-BurnLottery🔥♻️

**A daily on‑chain game that deflates your IACS token while crowning one lucky winner.**
Each 10000IACS ticket burns20% forever → the other80% snowballs into the day’s jackpot.
No rake, no admin custody – just autonomous smart‑contracts plus Chainlink Automation+VRFv2.5.

[Live Deployment](https://basescan.org/address/0x16740dc263e7aB962B74554327113f09aFe01380)

---

## 🚀QuickStart (BaseMain‑net)

|  # | Action             | CLI/UI step                                                                                                                                    |
| :--: | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
|  1 | **Clone** repo& cd | `git clone … && cd sustain-burn-lottery`                                                                                                         |
|  2 | **Env vars**        | `cp .env.example .env` → fill`PRIVATE_KEY, BASE_RPC_URL, IACS_TOKEN, SUBSCRIPTION_ID, ETHERSCAN_KEY`                                            |
|  3 | **Install** deps    | `npm i`                                                                                                                                          |
|  4 | Compile             | `npm run compile` → ✅ no errors                                                                                                                  |
|  5 | **Deploy**          | `npm run deploy` → copy contractaddress                                                                                                         |
|  6 | VRFconsumer        | [https://vrf.chain.link](https://vrf.chain.link) → add contract to your **v2.5** subscription                                                    |
|  7 | Verify source       | `npm run verify -- <addr> <IACS> <SubID> <Coordinator> <KeyHash>`                                                                                |
|  8 | Register upkeep     | [https://automation.chain.link](https://automation.chain.link) → time‑based, target `performUpkeep`, input`0x`, cron`00***`, gas≥300000 |
|  9 | **Fund**            | Upkeep≥0.02WETH •VRF sub≥0.2LINK (native BASE allowed)                                                                                    |
| 10 | **Play!**           | `IACS.approve(lottery,10000e18)` then `lottery.buyTicket(1)`                                                                                    |

---

## 🛠️NPMScripts

| Script          | Use‑case                        |
| ---------------- | ------------------------------- |
| `npm run dev`    | Local Hardhat node for tests    |
| `npm run deploy` | Deploy to Base (reads`.env`)   |
| `npm run verify` | Basescan/Etherscan verification |
| `npm test`       | Hardhat tests (coming soon)     |

---

## 📜ContractInterface

```solidity
// IACS must be pre‑approved for cost = qty * 10_000 * 1e18
function buyTicket(uint256 qty) external;
function ticketCount() external view returns (uint256);
function jackpot() external view returns (uint256); // 80% pool in IACS
function winners(uint256 round) external view returns (address);
```

Events to watch:

* `TicketBought(address player, uint256 round, uint256 qty)`
* `WinnerPicked(address winner, uint256 round, uint256 prize)`

---

## ✨Whyitrocks

* **Permanent burn**– gameplay that shrinks supply every day.
* **Provably fair**– randomness from Chainlink VRFv2.5.
* **Hands‑off**– one upkeep + a LINK/WETH drip keeps it spinning forever.
* **Plug‑&‑Play**– swap the token address, redeploy, done.

> May the burn be ever in your favour!
