import dotenv from "dotenv";

dotenv.config();

const parseNumber = (value: string | undefined, fallback: number): number => {
  if (!value) {
    return fallback;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;\n  snapshotCacheProvider: process.env.SNAPSHOT_CACHE_PROVIDER ?? "memory",\n  redisUrl: process.env.REDIS_URL ?? "",\n  snapshotCacheTtlSeconds: parseNumber(process.env.SNAPSHOT_CACHE_TTL_SECONDS, 600),\n  snapshotCacheVersion: process.env.SNAPSHOT_CACHE_VERSION ?? "1",\n};

export const config = {
  port: parseNumber(process.env.PORT, 3000),
  nodeEnv: process.env.NODE_ENV ?? "development",
  erpBaseUrl: process.env.ERP_BASE_URL ?? "",
  erpApiKey: process.env.ERP_API_KEY ?? "",
  erpClientId: process.env.ERP_CLIENT_ID ?? "",
  erpClientSecret: process.env.ERP_CLIENT_SECRET ?? "",
  erpTimeoutMs: parseNumber(process.env.ERP_TIMEOUT_MS, 30000),
  cacheTtlSeconds: parseNumber(process.env.CACHE_TTL_SECONDS, 300),
  enableRequestLogging: (process.env.ENABLE_REQUEST_LOGGING ?? "true") === "true",
  useMocks: (process.env.ERP_USE_MOCKS ?? "").toLowerCase() === "true",
  enableDebugRoutes: (process.env.ENABLE_DEBUG_ROUTES ?? "true") === "true",\n  snapshotCacheProvider: process.env.SNAPSHOT_CACHE_PROVIDER ?? "memory",\n  redisUrl: process.env.REDIS_URL ?? "",\n  snapshotCacheTtlSeconds: parseNumber(process.env.SNAPSHOT_CACHE_TTL_SECONDS, 600),\n  snapshotCacheVersion: process.env.SNAPSHOT_CACHE_VERSION ?? "1",\n};

export type AppConfig = typeof config;

