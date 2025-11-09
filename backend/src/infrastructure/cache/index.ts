import Redis from "ioredis";
import { config } from "../../config/env";
import type { CacheProvider } from "./CacheProvider";
import { MemoryCache } from "./MemoryCache";
import { RedisCache } from "./RedisCache";

const createProvider = (): CacheProvider => {
  if (config.snapshotCacheProvider === "redis" && config.redisUrl) {
    const client = new Redis(config.redisUrl, {
      lazyConnect: true,
    });
    return new RedisCache(client);
  }
  return new MemoryCache();
};

export const cacheProvider = createProvider();
