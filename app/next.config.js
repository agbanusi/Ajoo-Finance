/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: ["antd"],
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
      };
    }
    return config;
  },
};

// export default nextConfig;
module.exports = nextConfig;
