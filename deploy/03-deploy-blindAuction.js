const { ethers } = require("hardhat");
const fs = require("fs");
const { BackEndBlindAuctionAbiFile } = require("../helper-hardhat-config");

module.exports = async ({ deployments }) => {
  const { log } = deployments;
  const accounts = await ethers.getSigners();
  const deployer = accounts[0];

  const params = [
    {
      seller: 6,
      startTime: 1675044900,
      endTime: 1675048500,
      minimumBid: ethers.utils.parseEther("1"),
    },
    {
      seller: 7,
      startTime: 1675048500,
      endTime: 1675052100,
      minimumBid: ethers.utils.parseEther("1"),
    },
    {
      seller: 8,
      startTime: 1675052100,
      endTime: 1675055700,
      minimumBid: ethers.utils.parseEther("1"),
    },
  ];

  const blindAuctionFactoryContract = await ethers.getContract(
    "BlindAuctionFactory",
    deployer
  );

  let blindAuction, args, blindAuctionFactory, seller, txReceipt, txResponse;

  for (let i = 0; i < params.length; i++) {
    args = params[i];
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
