import type { CacheProvider } from "./CacheProvider";

type Entry = {
  value: unknown;
  etag: string;
  expiresAt: number;
};

export class MemoryCache implements CacheProvider {
  private store = new Map<string, Entry>();

  async get<T>(key: string): Promise<{ value: T; etag: string } | null> {
    const entry = this.store.get(key);
    if (!entry) {
      return null;
    }
    if (entry.expiresAt < Date.now()) {
      this.store.delete(key);
      return null;
    }
    return { value: entry.value as T, etag: entry.etag };
  }

  async set<T>(key: string, value: T, etag: string, ttlSeconds: number): Promise<void> {
    const expiresAt = Date.now() + ttlSeconds * 1000;
    this.store.set(key, { value, etag, expiresAt });
  }

  async del(key: string): Promise<void> {
    this.store.delete(key);
  }
}
