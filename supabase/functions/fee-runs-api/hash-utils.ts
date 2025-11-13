/**
 * Hash utilities for run record integrity
 * Uses Deno Web Crypto for deterministic SHA-256 hashing
 */

/**
 * Stable JSON stringification (keys sorted)
 */
function stableStringify(obj: any): string {
  if (obj === null) return 'null';
  if (typeof obj !== 'object') return JSON.stringify(obj);
  if (Array.isArray(obj)) return `[${obj.map(stableStringify).join(',')}]`;
  
  const keys = Object.keys(obj).sort();
  const pairs = keys.map(k => `${JSON.stringify(k)}:${stableStringify(obj[k])}`);
  return `{${pairs.join(',')}}`;
}

/**
 * Compute SHA-256 hash using Deno Web Crypto
 * Returns hex string
 */
export async function computeSHA256(data: string): Promise<string> {
  const encoder = new TextEncoder();
  const dataBuffer = encoder.encode(data);
  const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Compute deterministic run hash
 * 
 * Hash includes:
 * - config_version
 * - sorted inputs (distributions)
 * - calculation settings (VAT mode, rounding, etc.)
 */
export async function computeRunHash(params: {
  config_version: string;
  inputs: any[];
  settings?: Record<string, any>;
}): Promise<string> {
  const { config_version, inputs, settings = {} } = params;

  // Sort inputs by a stable key (e.g., investor_name, distribution_date, amount)
  const sortedInputs = [...inputs].sort((a, b) => {
    const keyA = `${a.investor_name}|${a.distribution_date}|${a.distribution_amount}`;
    const keyB = `${b.investor_name}|${b.distribution_date}|${b.distribution_amount}`;
    return keyA.localeCompare(keyB);
  });

  const hashInput = {
    config_version,
    inputs: sortedInputs,
    settings,
  };

  const stableJson = stableStringify(hashInput);
  return await computeSHA256(stableJson);
}
