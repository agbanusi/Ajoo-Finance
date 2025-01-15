export const fetchInsuranceCircles = () => [
  {
    id: "0x69030eFC11616251C01f2cA4CA181e7c85E67080",
    name: "Crop Insurance Pool",
    contributionAmount: 50,
    contributionPeriod: 30,
    votingPeriod: 7,
    coverageLimit: 10000,
    members: 100,
    totalFunds: 25000,
  },
  {
    id: "0x69030eFC11616251C01f2cA4CA181e7c85E67073",
    name: "Small Business Protection",
    contributionAmount: 100,
    contributionPeriod: 15,
    votingPeriod: 5,
    coverageLimit: 20000,
    members: 50,
    totalFunds: 40000,
  },
];

export const fetchAnInsuranceCircle = (id: string) =>
  [
    {
      id: "0x69030eFC11616251C01f2cA4CA181e7c85E67080",
      name: "Crop Insurance Pool",
      contributionAmount: 50,
      contributionPeriod: 30,
      votingPeriod: 7,
      coverageLimit: 10000,
      members: 100,
      totalFunds: 25000,
    },
    {
      id: "0x69030eFC11616251C01f2cA4CA181e7c85E67073",
      name: "Small Business Protection",
      contributionAmount: 100,
      contributionPeriod: 15,
      votingPeriod: 5,
      coverageLimit: 20000,
      members: 50,
      totalFunds: 40000,
    },
  ].find((circle) => circle.id == id);
