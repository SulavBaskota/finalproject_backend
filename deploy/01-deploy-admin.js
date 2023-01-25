module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const adminContract = await deploy("Admin", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  });
  log("Admin Contract deployed!");
  log(`Address: ${adminContract.address}`);
  log("-----------------------------------------------------------------------")
};

module.exports.tags = ["all", "admin"];
