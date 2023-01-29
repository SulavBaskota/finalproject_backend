const fs = require("fs");
const { ethers } = require("hardhat");
const {
  frontEndAdminAbiFile,
  frontEndAdminAddressFile,
  frontEndBlindAuctionAbiFile,
  frontEndBlindAuctionFactoryAbiFile,
  frontEndBlindAuctionFactoryAddressFile,
  BackEndBlindAuctionAbiFile,
} = require("../helper-hardhat-config");

module.exports = async () => {
  await updateContractAddresses();
  await updateAbi();
};

async function updateAbi() {
  const admin = await ethers.getContract("Admin");
  const blindAuctionFactory = await ethers.getContract("BlindAuctionFactory");

  fs.writeFileSync(
    frontEndAdminAbiFile,
    admin.interface.format(ethers.utils.FormatTypes.json)
  );
  fs.writeFileSync(
    frontEndBlindAuctionFactoryAbiFile,
    blindAuctionFactory.interface.format(ethers.utils.FormatTypes.json)
  );

  const blindAuctionAbi = JSON.parse(
    fs.readFileSync(BackEndBlindAuctionAbiFile, "utf8")
  ).abi;

  fs.writeFileSync(
    frontEndBlindAuctionAbiFile,
    JSON.stringify(blindAuctionAbi)
  );
}

async function updateContractAddresses() {
  const admin = await ethers.getContract("Admin");
  const blindAuctionFactory = await ethers.getContract("BlindAuctionFactory");

  fs.writeFileSync(frontEndAdminAddressFile, JSON.stringify(admin.address));
  fs.writeFileSync(
    frontEndBlindAuctionFactoryAddressFile,
    JSON.stringify(blindAuctionFactory.address)
  );
}

module.exports.tags = ["all", "frontend"];
