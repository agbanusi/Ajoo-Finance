/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverComponentsExternalPackages: ["@xmtp/user-preferences-bindings-wasm"],
  },
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
      };
      config.experiments.asyncWebAssembly = true;
    }
    return config;
  },
};

// export default nextConfig;
module.exports = nextConfig;
