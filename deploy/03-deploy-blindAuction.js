const { ethers } = require("hardhat");
const fs = require("fs");
const { BackEndBlindAuctionAbiFile } = require("../helper-hardhat-config");
const { blindAuctions } = require("../constants/blindAuctions");

module.exports = async ({ deployments }) => {
  const { log } = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];

  const blindAuctionFactoryContract = await ethers.getContract(
    "BlindAuctionFactory",
    deployer
  );

  let blindAuction, args, blindAuctionFactory, seller, txReceipt, txResponse;

  for (let i = 0; i < blindAuctions.length; i++) {
    args = blindAuctions[i];
    seller = accounts[args.seller];
    blindAuctionFactory = blindAuctionFactoryContract.connect(seller);
    await blindAuctionFactory.createBlindAuctionContract(
      args.startTime,
      args.endTime,
      args.minimumBid
    );
  }

  blindAuctionFactory = blindAuctionFactoryContract.connect(deployer);

  const blindAuctionAddresses =
    await blindAuctionFactory.getBlindAuctionAddresses();

  const blindAuctionAbi = JSON.parse(
    fs.readFileSync(BackEndBlindAuctionAbiFile, "utf8")
  ).abi;

  for (let i = 0; i < blindAuctionAddresses.length; i++) {
    blindAuction = new ethers.Contract(
      blindAuctionAddresses[i],
      blindAuctionAbi,
      deployer
    );
    await blindAuction.verifyAuction();
    log(`Blind Auction deployed at address: ${blindAuction.address}`);
    log(
      "-----------------------------------------------------------------------"
    );
  }
};

module.exports.tags = ["all", "blindAuction"];
