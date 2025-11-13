/**
 * Isomorphic SHA-256 hashing
 * Works in browser (Web Crypto API) and Node (dynamic import)
 */
export async function sha256Hex(input: string | Uint8Array): Promise<string> {
  const data =
    typeof input === "string" ? new TextEncoder().encode(input) : input;

  // Browser & modern runtimes
  if (typeof globalThis !== "undefined" && globalThis.crypto?.subtle) {
    const digest = await globalThis.crypto.subtle.digest("SHA-256", data as Uint8Array<ArrayBuffer>);
    const hashArray = new Uint8Array(digest);
    return Array.from(hashArray)
      .map(b => b.toString(16).padStart(2, "0"))
      .join("");
  }

  // Node fallback (dynamic import so bundlers don't try to polyfill in web)
  const { createHash } = await import("node:crypto");
  return createHash("sha256").update(Buffer.from(data as Uint8Array<ArrayBuffer>)).digest("hex");
}
