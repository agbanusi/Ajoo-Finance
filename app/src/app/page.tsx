import Image from "next/image";
import Link from "next/link";

export default function SavingsPage() {
  const savingsTypes = [
    {
      title: "Target Savings",
      description: "Set and achieve your financial goals with ease.",
      image: "/savings.jpeg",
      link: "/savings/target",
    },
    {
      title: "Vault Savings",
      description: "Securely lock away funds for long-term growth.",
      image: "/piggy-save.jpeg",
      link: "/savings/vault",
    },
    {
      title: "Cross Chain Savings",
      description: "Quickly save small amounts for immediate needs.",
      image: "/savings.jpeg",
      link: "/savings/stash",
    },
    {
      title: "Challenge Savings",
      description: "Make saving fun with exciting savings challenges.",
      image: "/savings.jpeg",
      link: "/savings/challenge",
    },
    {
      title: "Investment Savings",
      description: "Grow your wealth with smart investment options.",
      image: "/save-invest.jpeg",
      link: "/investments",
    },
    {
      title: "Circle Savings",
      description:
        "Grow your wealth by saving in trusted circles and earn in bulk during the saving cycle.",
      image: "/piggy-save.jpeg",
      link: "/savings/circle",
    },
    {
      title: "Group Savings",
      description:
        "Grow your savings by saving together in group of friends or family.",
      image: "/save-invest.jpeg",
      link: "/savings/group",
    },
    {
      title: "Charity Funding",
      description:
        "Setup and donate to created Charity fundings like web3 GoFundMe",
      image: "/save-invest.jpeg",
      link: "/custodial",
    },
    {
      title: "Micro Lending",
      description: "Borrow money from membership circles without Collateral",
      image: "/piggy-save.jpeg",
      link: "/lending",
    },
    {
      title: "Micro Insurance",
      description:
        "Pay premium to membership circles and make insurance claims where members vote to accept your claims",
      image: "/piggy-save.jpeg",
      link: "/insurance",
    },
  ];

  return (
    <main className="flex min-h-screen flex-col items-center p-24">
      <h1 className="text-4xl font-bold mb-4">
        Welcome to Ajoo Finance Savings
      </h1>
      <p className="text-xl text-center mb-12 max-w-2xl">
        Discover smarter ways to save and grow your money with our diverse range
        of savings options.
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {savingsTypes.map((type, index) => (
          <Link href={type.link} key={index} className="block">
            <div className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow">
              <div className="relative h-48">
                <Image
                  src={type.image}
                  alt={type.title}
                  fill
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-black bg-opacity-50 flex flex-col justify-end p-4">
                  <h2 className="text-xl font-semibold text-white">
                    {type.title}
                  </h2>
                </div>
                {/* <div className="absolute inset-0 bg-black bg-opacity-50 flex flex-col justify-end p-4">
                  <p className="text-gray-600 text-sm">{type.description}</p>
                </div> */}
              </div>
              <div className="p-4">
                <p className="text-gray-600 text-sm">{type.description}</p>
              </div>
            </div>
          </Link>
        ))}
      </div>
    </main>
  );
}
