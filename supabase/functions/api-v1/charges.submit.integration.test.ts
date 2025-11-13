/**
 * Integration Tests: POST /charges/:id/submit (T01: v1.8.0)
 * Date: 2025-10-21
 *
 * These tests use real database connections and test end-to-end flows.
 *
 * Test Scenarios:
 * - Real investor with real credits
 * - Multiple concurrent submissions (race condition test)
 * - Large credit count (performance test)
 * - Mixed scope credits (fund + deal)
 * - Complex FIFO scenarios
 */

import { assertEquals, assertExists } from 'https://deno.land/std@0.192.0/testing/asserts.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || 'http://localhost:54321';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// ============================================
// INTEGRATION TEST 1: E2E with Real Data
// ============================================
Deno.test('T01.INT.1: E2E - Real investor, contribution, charge, and credits', async () => {
  // 1. Create real investor
  const { data: investor } = await supabase
    .from('investors')
    .insert({ name: 'Integration Test Investor', party_entity_id: 1 })
    .select('id')
    .single();

  const investorId = investor!.id;

  // 2. Create real fund
  const { data: fund } = await supabase
    .from('funds')
    .insert({ name: 'Integration Test Fund', currency: 'USD' })
    .select('id')
    .single();

  const fundId = fund!.id;

  // 3. Create contribution
  const { data: contribution } = await supabase
    .from('contributions')
    .insert({
      investor_id: investorId,
      fund_id: fundId,
      paid_in_date: '2025-10-15',
      amount: 50000,
      currency: 'USD',
    })
    .select('id')
    .single();

  const contributionId = contribution!.id;

  // 4. Create charge via compute endpoint
  const computeResponse = await fetch(`${SUPABASE_URL}/functions/v1/api-v1/charges/compute`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ contribution_id: contributionId }),
  });

  const computeResult = await computeResponse.json();
  const chargeId = computeResult.data?.id;

  assertExists(chargeId, 'Charge should be created via compute endpoint');

  // 5. Create credits for this investor
  const { data: credit1 } = await supabase
    .from('credits_ledger')
    .insert({
      investor_id: investorId,
      fund_id: fundId,
      reason: 'Referral bonus',
      original_amount: 1000,
      available_amount: 1000,
      currency: 'USD',
      created_at: '2025-09-15T10:00:00Z',
    })
    .select('id')
    .single();

  const { data: credit2 } = await supabase
    .from('credits_ledger')
    .insert({
      investor_id: investorId,
      fund_id: fundId,
      reason: 'Promotional credit',
      original_amount: 500,
      available_amount: 500,
      currency: 'USD',
      created_at: '2025-10-01T10:00:00Z',
    })
    .select('id')
    .single();

  // 6. Submit charge
  const submitResponse = await fetch(`${SUPABASE_URL}/functions/v1/api-v1/charges/${chargeId}/submit`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
    },
  });

  const submitResult = await submitResponse.json();

  // 7. Assertions
  assertEquals(submitResponse.status, 200);
  assertExists(submitResult.data);

  const charge = submitResult.data;
  assertEquals(charge.status, 'PENDING');

  // Should have applied both credits in FIFO order
  assertExists(charge.credit_applications);
  assertEquals(charge.credit_applications.length, 2);

  // Older credit (credit1) should be first
  assertEquals(charge.credit_applications[0].credit_id, credit1!.id);

  // 8. Cleanup
  await supabase.from('credit_applications').delete().match({ charge_id: chargeId });
  await supabase.from('charges').delete().eq('id', chargeId);
  await supabase.from('credits_ledger').delete().in('id', [credit1!.id, credit2!.id]);
  await supabase.from('contributions').delete().eq('id', contributionId);
  await supabase.from('funds').delete().eq('id', fundId);
  await supabase.from('investors').delete().eq('id', investorId);

  console.log('✅ T01.INT.1 passed');
});

// ============================================
// INTEGRATION TEST 2: Concurrent Submissions (Race Condition)
// ============================================
Deno.test('T01.INT.2: Concurrent Submissions - Only one succeeds, others idempotent', async () => {
  // Setup
  const { data: investor } = await supabase
    .from('investors')
    .insert({ name: 'Concurrent Test Investor', party_entity_id: 1 })
    .select('id')
    .single();

  const { data: fund } = await supabase
    .from('funds')
    .insert({ name: 'Concurrent Test Fund', currency: 'USD' })
    .select('id')
    .single();

  const { data: contribution } = await supabase
    .from('contributions')
    .insert({
      investor_id: investor!.id,
      fund_id: fund!.id,
      paid_in_date: '2025-10-15',
      amount: 10000,
      currency: 'USD',
    })
    .select('id')
    .single();

  const { data: charge } = await supabase
    .from('charges')
    .insert({
      investor_id: investor!.id,
      fund_id: fund!.id,
      contribution_id: contribution!.id,
      status: 'DRAFT',
      base_amount: 500,
      discount_amount: 0,
      vat_amount: 100,
      total_amount: 600,
      currency: 'USD',
      snapshot_json: {},
    })
    .select('id')
    .single();

  const { data: credit } = await supabase
    .from('credits_ledger')
    .insert({
      investor_id: investor!.id,
      fund_id: fund!.id,
      reason: 'Test credit',
      original_amount: 1000,
      available_amount: 1000,
      currency: 'USD',
    })
    .select('id')
    .single();

  // Concurrent submissions (simulate race condition)
  const submitPromises = Array(5).fill(null).map(() =>
    fetch(`${SUPABASE_URL}/functions/v1/api-v1/charges/${charge!.id}/submit`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
    })
  );

  const results = await Promise.all(submitPromises);

  // All should succeed with 200
  results.forEach(r => assertEquals(r.status, 200));

  // Verify only one set of credit applications was created
  const { count } = await supabase
    .from('credit_applications')
    .select('*', { count: 'exact' })
    .eq('charge_id', charge!.id)
    .is('reversed_at', null);

  assertEquals(count, 1, 'Should have exactly 1 credit application (no duplicates)');

  // Cleanup
  await supabase.from('credit_applications').delete().match({ charge_id: charge!.id });
  await supabase.from('charges').delete().eq('id', charge!.id);
  await supabase.from('credits_ledger').delete().eq('id', credit!.id);
  await supabase.from('contributions').delete().eq('id', contribution!.id);
  await supabase.from('funds').delete().eq('id', fund!.id);
  await supabase.from('investors').delete().eq('id', investor!.id);

  console.log('✅ T01.INT.2 passed');
});

// ============================================
// INTEGRATION TEST 3: Large Credit Count (Performance)
// ============================================
Deno.test('T01.INT.3: Performance - Handle 100 credits efficiently', async () => {
  // Setup
  const { data: investor } = await supabase
    .from('investors')
    .insert({ name: 'Performance Test Investor', party_entity_id: 1 })
    .select('id')
    .single();

  const { data: fund } = await supabase
    .from('funds')
    .insert({ name: 'Performance Test Fund', currency: 'USD' })
    .select('id')
    .single();

  const { data: contribution } = await supabase
    .from('contributions')
    .insert({
      investor_id: investor!.id,
      fund_id: fund!.id,
      paid_in_date: '2025-10-15',
      amount: 100000,
      currency: 'USD',
    })
    .select('id')
    .single();

  const { data: charge } = await supabase
    .from('charges')
    .insert({
      investor_id: investor!.id,
      fund_id: fund!.id,
      contribution_id: contribution!.id,
      status: 'DRAFT',
      base_amount: 5000,
      discount_amount: 0,
      vat_amount: 1000,
      total_amount: 6000,
      currency: 'USD',
      snapshot_json: {},
    })
    .select('id, numeric_id')
    .single();

  // Create 100 small credits
  const credits = Array(100).fill(null).map((_, i) => ({
    investor_id: investor!.id,
    fund_id: fund!.id,
    reason: `Test credit ${i + 1}`,
    original_amount: 100,
    available_amount: 100,
    currency: 'USD',
    created_at: new Date(Date.UTC(2025, 0, 1 + i)).toISOString(), // Sequential dates
  }));

  const { data: insertedCredits } = await supabase
    .from('credits_ledger')
    .insert(credits)
    .select('id');

  // Measure submit performance
  const startTime = Date.now();

  const submitResponse = await fetch(`${SUPABASE_URL}/functions/v1/api-v1/charges/${charge!.id}/submit`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
    },
  });

  const endTime = Date.now();
  const duration = endTime - startTime;

  const submitResult = await submitResponse.json();

  // Assertions
  assertEquals(submitResponse.status, 200);
  assertExists(submitResult.data);

  const finalCharge = submitResult.data;
  assertEquals(finalCharge.status, 'PENDING');

  // Should have applied 60 credits (6000 / 100 = 60)
  assertEquals(finalCharge.credit_applications.length, 60);
  assertEquals(finalCharge.credits_applied_amount, 6000);
  assertEquals(finalCharge.net_amount, 0);

  console.log(`⏱️  Submit duration: ${duration}ms (100 credits)`);

  // Performance check: Should complete in under 5 seconds
  assertEquals(duration < 5000, true, 'Submit should complete in under 5 seconds');

  // Cleanup
  await supabase.from('credit_applications').delete().match({ charge_id: charge!.numeric_id });
  await supabase.from('charges').delete().eq('id', charge!.id);
  await supabase.from('credits_ledger').delete().in('id', insertedCredits!.map(c => c.id));
  await supabase.from('contributions').delete().eq('id', contribution!.id);
  await supabase.from('funds').delete().eq('id', fund!.id);
  await supabase.from('investors').delete().eq('id', investor!.id);

  console.log('✅ T01.INT.3 passed');
});

// ============================================
// INTEGRATION TEST 4: Mixed Scope Credits
// ============================================
Deno.test('T01.INT.4: Mixed Scope - Fund credits + Deal credits, only fund applied', async () => {
  // Setup
  const { data: investor } = await supabase
    .from('investors')
    .insert({ name: 'Mixed Scope Investor', party_entity_id: 1 })
    .select('id')
    .single();

  const { data: fund } = await supabase
    .from('funds')
    .insert({ name: 'Mixed Scope Fund', currency: 'USD' })
    .select('id')
    .single();

  const { data: deal } = await supabase
    .from('deals')
    .insert({ name: 'Mixed Scope Deal', fund_id: fund!.id })
    .select('id')
    .single();

  const { data: contribution } = await supabase
    .from('contributions')
    .insert({
      investor_id: investor!.id,
      fund_id: fund!.id,
      paid_in_date: '2025-10-15',
      amount: 10000,
      currency: 'USD',
    })
    .select('id')
    .single();

  const { data: charge } = await supabase
    .from('charges')
    .insert({
      investor_id: investor!.id,
      fund_id: fund!.id, // Fund-scoped charge
      contribution_id: contribution!.id,
      status: 'DRAFT',
      base_amount: 500,
      discount_amount: 0,
      vat_amount: 100,
      total_amount: 600,
      currency: 'USD',
      snapshot_json: {},
    })
    .select('id')
    .single();

  // Create fund-scoped credit (should match)
  const { data: fundCredit } = await supabase
    .from('credits_ledger')
    .insert({
      investor_id: investor!.id,
      fund_id: fund!.id,
      reason: 'Fund credit',
      original_amount: 400,
      available_amount: 400,
      currency: 'USD',
    })
    .select('id')
    .single();

  // Create deal-scoped credit (should NOT match)
  const { data: dealCredit } = await supabase
    .from('credits_ledger')
    .insert({
      investor_id: investor!.id,
      deal_id: deal!.id,
      reason: 'Deal credit',
      original_amount: 1000,
      available_amount: 1000,
      currency: 'USD',
    })
    .select('id')
    .single();

  // Submit charge
  const submitResponse = await fetch(`${SUPABASE_URL}/functions/v1/api-v1/charges/${charge!.id}/submit`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
    },
  });

  const submitResult = await submitResponse.json();

  // Assertions
  assertEquals(submitResponse.status, 200);

  const finalCharge = submitResult.data;

  // Only fund credit should be applied
  assertEquals(finalCharge.credits_applied_amount, 400);
  assertEquals(finalCharge.net_amount, 200); // 600 - 400
  assertEquals(finalCharge.credit_applications.length, 1);
  assertEquals(finalCharge.credit_applications[0].credit_id, fundCredit!.id);

  // Cleanup
  await supabase.from('credit_applications').delete().match({ charge_id: charge!.id });
  await supabase.from('charges').delete().eq('id', charge!.id);
  await supabase.from('credits_ledger').delete().in('id', [fundCredit!.id, dealCredit!.id]);
  await supabase.from('contributions').delete().eq('id', contribution!.id);
  await supabase.from('deals').delete().eq('id', deal!.id);
  await supabase.from('funds').delete().eq('id', fund!.id);
  await supabase.from('investors').delete().eq('id', investor!.id);

  console.log('✅ T01.INT.4 passed');
});

console.log('🎯 All T01 integration tests defined. Run with: deno test charges.submit.integration.test.ts');
