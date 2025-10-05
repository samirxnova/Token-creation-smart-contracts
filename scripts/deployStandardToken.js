// scripts/deployStandardToken.js
const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying StandardToken to 0G Network...");

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // StandardToken constructor parameters
  const name = "Test Standard Token";
  const symbol = "TST";
  const decimals = 18;
  const totalSupply = "1000000";
  const feeReceiver = "0x317987A491E3042Da60F06F7eCC7551e820C9F28";
  const serviceFee = hre.ethers.parseEther("0.001"); // 0.001 ETH

  // Deploy StandardToken
  const StandardToken = await hre.ethers.getContractFactory("StandardToken");
  const standardToken = await StandardToken.deploy(
    name,
    symbol,
    decimals,
    totalSupply,
    feeReceiver,
    serviceFee,
    { value: serviceFee }
  );
  
  await standardToken.waitForDeployment();
  const address = await standardToken.getAddress();
  
  console.log("StandardToken deployed to:", address);
  console.log("Explorer:", `https://chainscan-galileo.0g.ai/address/${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
