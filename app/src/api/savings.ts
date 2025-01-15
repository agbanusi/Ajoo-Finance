export const fetchGroupSavings = () => [
  { id: "0x01", name: "Family Vacation Fund", members: 5, totalSavings: 5000 },
  { id: "0x02", name: "Wedding Gift Pool", members: 8, totalSavings: 2000 },
];

export const fetchAGroupSaving = (groupId: string) => ({
  id: groupId,
  name: "Family Group",
  members: 5,
  totalSavings: 5000,
  goal: 10000,
  owner: "0x02",
});

export const fetchInvestmentSavings = (userAddress: string) => [
  { id: "0x01", name: "Family Vacation Fund", members: 5, totalSavings: 5000 },
  { id: "0x02", name: "Wedding Gift Pool", members: 8, totalSavings: 2000 },
];
