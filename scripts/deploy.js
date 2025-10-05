// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  console.log("🚀 Starting deployment to 0G Testnet...");

  const [deployer] = await hre.ethers.getSigners();
  console.log("👤 Deployer Address:", deployer.address);
  console.log("💰 Balance:", hre.ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");


  // ========= 📦 Deploy Contract =========
  const BasicToken = await hre.ethers.getContractFactory("BasicToken");

  console.log("📦 Deploying BasicToken contract...");
  const token = await BasicToken.deploy(
    name,
    symbol,
    totalSupply,
    router,
    buyFee,
    sellFee,
    marketingWallet,
    feeReceiver,
    serviceFee,
    { value: serviceFee }
  );

  console.log("⏳ Waiting for deployment confirmation...");
  await token.waitForDeployment();

  const tokenAddress = await token.getAddress();
  console.log(`✅ Deployment successful!`);
  console.log(`📍 Contract Address: ${tokenAddress}`);
  console.log(`🔗 Explorer: https://chainscan-galileo.0g.ai/address/${tokenAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
