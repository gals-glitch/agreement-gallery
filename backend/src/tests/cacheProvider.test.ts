import { MemoryCache } from "../infrastructure/cache/MemoryCache";

describe("MemoryCache", () => {
  it("stores and retrieves entries", async () => {
    const cache = new MemoryCache();
    await cache.set("foo", { value: 1 }, "etag-1", 60);
    const result = await cache.get<typeof { value: number }>("foo");
    expect(result).not.toBeNull();
    expect(result?.value).toEqual({ value: 1 });
    expect(result?.etag).toBe("etag-1");
  });

  it("expires entries based on ttl", async () => {
    const cache = new MemoryCache();
    await cache.set("foo", { value: 1 }, "etag-1", 0);
    const result = await cache.get("foo");
    expect(result).toBeNull();
  });
});
