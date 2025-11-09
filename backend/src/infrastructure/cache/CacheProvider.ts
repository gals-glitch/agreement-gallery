export interface CacheProvider {
  get<T>(key: string): Promise<{ value: T; etag: string } | null>;
  set<T>(key: string, value: T, etag: string, ttlSeconds: number): Promise<void>;
  del(key: string): Promise<void>;
}
