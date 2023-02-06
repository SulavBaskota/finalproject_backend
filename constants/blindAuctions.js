const currentTime = Math.floor(Date.now() / 1000);

const currentTimePlusHours = (hours) => {
  return parseInt(currentTime + hours * 60 * 60);
};

const blindAuctions = [
  {
    seller: 6,
    startTime: currentTimePlusHours(0.1),
    endTime: currentTimePlusHours(0.2),
    minimumBid: ethers.utils.parseEther("1"),
  },
  {
    seller: 7,
    startTime: currentTimePlusHours(0.2),
    endTime: currentTimePlusHours(0.3),
    minimumBid: ethers.utils.parseEther("1"),
  },
  {
    seller: 8,
    startTime: currentTimePlusHours(0.3),
    endTime: currentTimePlusHours(0.4),
    minimumBid: ethers.utils.parseEther("1"),
  },
];

module.exports = {
  blindAuctions,
};
