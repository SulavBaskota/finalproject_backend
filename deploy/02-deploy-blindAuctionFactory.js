const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const adminContract = await ethers.getContract("Admin");
  const adminContractAddress = adminContract.address;

  const blindAuctionFactoryContract = await deploy("BlindAuctionFactory", {
    from: deployer,
    args: [adminContractAddress],
    log: true,
    waitConfirmations: 1,
  });

  log("BlindAuctionFactory Contract deployed!");
  log(`Address: ${blindAuctionFactoryContract.address}`);
  log(
    "-----------------------------------------------------------------------"
  );
};

module.exports.tags = ["all", "blindAuctionFactory"];
