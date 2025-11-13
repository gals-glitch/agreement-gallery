/**
 * Deterministic JSON serialization
 * Ensures consistent key ordering for reliable checksums
 */
export function stableStringify(obj: unknown): string {
  return JSON.stringify(sort(obj));
  
  function sort(v: any): any {
    if (Array.isArray(v)) return v.map(sort);
    if (v && typeof v === "object") {
      return Object.keys(v).sort().reduce((acc: any, k) => {
        acc[k] = sort(v[k]);
        return acc;
      }, {});
    }
    return v;
  }
}
