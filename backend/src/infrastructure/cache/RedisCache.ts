import type { CacheProvider } from "./CacheProvider";
import type { Redis } from "ioredis";

export class RedisCache implements CacheProvider {
  constructor(private readonly client: Redis) {}

  async get<T>(key: string): Promise<{ value: T; etag: string } | null> {
    const result = await this.client.get(key);
    if (!result) {
      return null;
    }
    const parsed = JSON.parse(result) as { value: T; etag: string };
    return parsed;
  }

  async set<T>(key: string, value: T, etag: string, ttlSeconds: number): Promise<void> {
    const payload = JSON.stringify({ value, etag });
    await this.client.set(key, payload, "EX", ttlSeconds);
  }

  async del(key: string): Promise<void> {
    await this.client.del(key);
  }
}
