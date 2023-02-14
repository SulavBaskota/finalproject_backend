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
    cid: "bafybeia4qyidtsyayxpd3gjsnvjzdaadku4u5be3gm6zqy45bywixzqgwe",
  },
  {
    seller: 7,
    startTime: currentTimePlusHours(0.2),
    endTime: currentTimePlusHours(0.3),
    minimumBid: ethers.utils.parseEther("2"),
    cid: "bafybeifvbv4c2damyxwxgr6whwi5amblspmcff2rx2mtz3qgzsvxllkie4",
  },
  {
    seller: 8,
    startTime: currentTimePlusHours(0.3),
    endTime: currentTimePlusHours(0.4),
    minimumBid: ethers.utils.parseEther("3"),
    cid: "bafybeihiairwr6sw6mag5rl7x2n5fdr22n6lg34fw3ipjciju7xuwueobi",
  },
];

module.exports = {
  blindAuctions,
};
