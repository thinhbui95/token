import { ethers } from "hardhat";

async function main() {
  const [account] = await ethers.getSigners();
  const factory = await ethers.getContractFactory("Token");
  const name = "TestEXP";
  const symbol = "EXP";


  const token = await factory.deploy(name, symbol,{ gasLimit: 470000000 });
  await token.waitForDeployment();

  console.log("Token deployed to:", token.target);
  
}


main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});