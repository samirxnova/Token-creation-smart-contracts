// scripts/deployBasicToken.js
const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying BasicToken to 0G Network...");

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // BasicToken constructor parameters
  const name = "Test Basic Token";
  const symbol = "TBT";
  const totalSupply = "1000000";
  const router = "0x0000000000000000000000000000000000000000"; // Zero address to skip Uniswap
  const buyFee = 0;
  const sellFee = 0;
  const marketingWallet = deployer.address;
  const feeReceiver = "0x317987A491E3042Da60F06F7eCC7551e820C9F28";
  const serviceFee = hre.ethers.parseEther("0.001");

  try {
    // Deploy BasicToken
    const BasicToken = await hre.ethers.getContractFactory("BasicToken");
    const basicToken = await BasicToken.deploy(
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
    
    await basicToken.waitForDeployment();
    const address = await basicToken.getAddress();
    
    console.log("✅ BasicToken deployed to:", address);
    console.log("🔍 Explorer:", `https://chainscan-galileo.0g.ai/address/${address}`);
    
    // Save deployment info
    console.log("\n📋 Deployment Summary:");
    console.log("Contract:", "BasicToken");
    console.log("Address:", address);
    console.log("Name:", name);
    console.log("Symbol:", symbol);
    console.log("Total Supply:", totalSupply);
    
  } catch (error) {
    console.error("❌ Deployment failed:", error.message);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });