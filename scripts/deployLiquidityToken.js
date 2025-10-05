// scripts/deployLiquidityToken.js
const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying LiquidityToken to 0G Network...");

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // LiquidityToken constructor parameters
  const name = "Test Liquidity Token";
  const symbol = "TLT";
  const totalSupply = "1000000";
  const router = "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008"; // 0G testnet router
  const teamAddress = deployer.address; // Use deployer as team address
  const reflectionFee = 300; // 3% (in basis points)
  const liquidityFee = 300;  // 3% (in basis points)
  const teamFee = 200;       // 2% (in basis points)
  const feeReceiver = "0x317987A491E3042Da60F06F7eCC7551e820C9F28";
  const serviceFee = hre.ethers.parseEther("0.001"); // 0.001 ETH

  // Deploy LiquidityToken
  const LiquidityToken = await hre.ethers.getContractFactory("LiquidityToken");
  const liquidityToken = await LiquidityToken.deploy(
    name,
    symbol,
    totalSupply,
    router,
    teamAddress,
    reflectionFee,
    liquidityFee,
    teamFee,
    feeReceiver,
    serviceFee,
    { value: serviceFee }
  );
  
  await liquidityToken.waitForDeployment();
  const address = await liquidityToken.getAddress();
  
  console.log("LiquidityToken deployed to:", address);
  console.log("Explorer:", `https://chainscan-galileo.0g.ai/address/${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
