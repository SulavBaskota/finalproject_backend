const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const biddingTime = 0;
  const revealTime = 0;

  const adminContract = await ethers.getContract("Admin");
  const adminContractAddress = adminContract.address;

  const args = [biddingTime, revealTime, adminContractAddress, deployer];

  const blindAuctionContract = await deploy("BlindAuction", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: 1,
  });

  log("BlindAuction Contract deployed!");
  log(`Address: ${blindAuctionContract.address}`);
  log(
    "-----------------------------------------------------------------------"
  );
  const mockContract = await ethers.getContract("BlindAuction");
  const txResponse = await mockContract.rejectAuction("Mock Auction Contract");
  await txResponse.wait(1);
};

module.exports.tags = ["all", "blindAuction"];
