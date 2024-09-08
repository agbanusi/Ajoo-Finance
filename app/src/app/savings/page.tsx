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
      title: "Stash Savings",
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
      description: "Grow your wealth by saving in trusted circles.",
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
  ];

  return (
    <main className="flex min-h-screen flex-col items-center p-24">
      <h1 className="text-4xl font-bold mb-4">Welcome to Ajoo Finance</h1>
      <p className="text-2xl text-center mb-12 max-w-2xl">
        Novel Defi Solutions on Different Savings, Uncollateralized
        micro-lending, micro-insurance and DCA investments.
      </p>

      <p className="text-xl text-center mb-12 max-w-2xl">
        Ajoo Finance is a web3 personal finance platform offering diverse
        savings solutions especially our novel circle savings,
        micro-investments, uncollateralized lending services, custodial features
        for charity gofundme setup and family trust funds, and micro-insurance
        options. It emphasizes cross-chain compatibility, and decentralized
        governance to provide secure, transparent, and innovative financial
        solutions.
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
