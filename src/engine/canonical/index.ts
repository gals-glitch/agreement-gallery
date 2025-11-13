/**
 * Canonical Calculation Engine
 * 
 * Single source of truth for commission calculations
 * - Contribution-based (not commitment-based)
 * - VAT-aware (included vs on-top)
 * - Tier and cap support
 * - Credit application
 * - Deterministic with checksums
 */

export { CanonicalCalculationEngine } from './calculator';
export { RuleLoader } from './rule-loader';
export { TierEngine } from './tier-engine';
export { VatEngine } from './vat-engine';
export { CreditEngine } from './credit-engine';
export { PrecedenceEngine } from './precedence-engine';
export { CreditsScopingEngine } from './credits-scoping-engine';
export { RateResolver } from './rate-resolver';
export { AgreementLoader } from './agreement-loader';
export type { RuleSet } from './rule-loader';
export type { FundVITrack, ResolvedRates } from './rate-resolver';
export type { Agreement } from './agreement-loader';
