import type { NextConfig } from 'next';

// Made by Dr Ali — Admin Web. API proxied via app/obic-api/[...path]/route.ts

const nextConfig: NextConfig = {
  allowedDevOrigins: ['http://127.0.0.1:3010', 'http://localhost:3010'],
};

export default nextConfig;
