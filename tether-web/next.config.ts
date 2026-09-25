import type { NextConfig } from 'next';
import path from 'path';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  output: 'standalone',
  // Local monorepo warning fix. Omit in Docker so standalone lands at .next/standalone/server.js
  ...(process.env.DOCKER_BUILD
    ? {}
    : { outputFileTracingRoot: path.join(__dirname, '..') }),
};

export default nextConfig;
