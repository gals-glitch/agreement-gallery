import { CommissionRule } from '@/domain/types';

/**
 * Precedence Engine
 * Handles agreement scope precedence: DEAL-scoped agreements take priority over FUND-scoped
 */
export class PrecedenceEngine {
  /**
   * Find the best applicable rule for an entity based on scope precedence
   * DEAL-scoped agreements (with deal_id match) take priority over FUND-scoped
   * 
   * @param rules - All rules for this entity type/name
   * @param dealId - The deal ID from the contribution (if any)
   * @param fundName - The fund name from the contribution
   * @returns The highest priority rule, or null if none applicable
   */
  static findApplicableRule(
    rules: CommissionRule[],
    dealId: string | null | undefined,
    fundName: string
  ): CommissionRule | null {
    if (rules.length === 0) return null;

    // Sort by priority (higher first)
    const sorted = [...rules].sort((a, b) => (b.priority || 0) - (a.priority || 0));

    // First, try to find a DEAL-scoped rule that matches the deal_id
    if (dealId) {
      const dealRule = sorted.find(r => 
        r.applies_scope === 'DEAL' && 
        r.deal_id === dealId &&
        (!r.fund_name || r.fund_name === fundName)
      );
      
      if (dealRule) {
        return dealRule;
      }
    }

    // Fallback to FUND-scoped rule
    const fundRule = sorted.find(r => 
      r.applies_scope === 'FUND' &&
      (!r.fund_name || r.fund_name === fundName) &&
      !r.deal_id // FUND rules should not have deal_id
    );

    return fundRule || null;
  }

  /**
   * Get scope badge info for a fee line
   */
  static getScopeBadge(rule: CommissionRule): { scope: string; variant: 'default' | 'secondary' } {
    if (rule.applies_scope === 'DEAL') {
      return { scope: 'DEAL', variant: 'default' };
    }
    return { scope: 'FUND', variant: 'secondary' };
  }

  /**
   * Validate that a contribution won't be double-charged
   * This is a safety check - the precedence logic should already prevent this
   */
  static validateNoDuplicateScope(
    selectedRules: Array<{ entityType: string; entityName: string; rule: CommissionRule }>,
    contribution: { id: string; investor_name: string }
  ): void {
    // Group by entity (type + name)
    const byEntity = new Map<string, CommissionRule[]>();
    
    for (const { entityType, entityName, rule } of selectedRules) {
      const key = `${entityType}:${entityName}`;
      if (!byEntity.has(key)) {
        byEntity.set(key, []);
      }
      byEntity.get(key)!.push(rule);
    }

    // Check each entity has only one scope
    for (const [entityKey, rulesForEntity] of byEntity) {
      const scopes = new Set(rulesForEntity.map(r => r.applies_scope));
      if (scopes.size > 1) {
        throw new Error(
          `Double-charging detected for ${entityKey} on contribution ${contribution.id}. ` +
          `Both DEAL and FUND scoped rules were selected. This should never happen.`
        );
      }
    }
  }
}
