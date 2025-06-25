const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const subId        = BigInt(process.env.SUBSCRIPTION_ID);
  const iacs         = process.env.IACS_TOKEN;
  const vrfCoord     = "0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634"; // Base main-net VRF v2.5 coordinator :contentReference[oaicite:0]{index=0}
  const keyHash      = "0xdc2f87677b01473c763cb0aee938ed3341512f6057324a584e5944e786144d70"; // 30 gwei lane :contentReference[oaicite:1]{index=1}

  const Lottery = await ethers.getContractFactory("SustainBurnLottery");
  const lotto   = await Lottery.deploy(iacs, subId, vrfCoord, keyHash);

  await lotto.waitForDeployment();
  console.log("Lottery deployed to:", lotto.target);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});