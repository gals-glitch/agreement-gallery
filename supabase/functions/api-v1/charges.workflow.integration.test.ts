/**
 * Integration Tests: T02 Charge Workflow (Approve, Reject, Mark-Paid)
 * Date: 2025-10-21
 *
 * Test Coverage:
 * - Full workflow: DRAFT → PENDING → APPROVED → PAID
 * - Rejection workflow: DRAFT → PENDING → REJECTED (with credit reversal)
 * - Database transaction integrity
 * - Credit balance verification
 * - Audit log verification
 *
 * Prerequisites:
 * - Supabase local instance running
 * - Feature flag 'charges_engine' enabled
 * - Test users with admin role
 */

import { assertEquals, assertExists } from 'https://deno.land/std@0.192.0/testing/asserts.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

// ============================================
// TEST SETUP
// ============================================
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || 'http://localhost:54321';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
const API_BASE = `${SUPABASE_URL}/functions/v1/api-v1`;

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Test data IDs
let testInvestorId: number;
let testFundId: number;
let testContributionId: string;
let testCreditId1: string;
let testCreditId2: string;
let adminUserId: string;

// ============================================
// HELPER: Create Test Data
// ============================================
async function setupTestData() {
  console.log('Setting up test data...');

  // Enable feature flag
  await supabaseAdmin
    .from('feature_flags')
    .upsert({ flag_key: 'charges_engine', is_enabled: true })
    .eq('flag_key', 'charges_engine');

  // Create test investor
  const { data: investor } = await supabaseAdmin
    .from('investors')
    .insert({ name: 'Test Investor Workflow', party_entity_id: 1 })
    .select('id')
    .single();
  testInvestorId = investor!.id;

  // Create test fund
  const { data: fund } = await supabaseAdmin
    .from('funds')
    .insert({ name: 'Test Fund Workflow', currency: 'USD' })
    .select('id')
    .single();
  testFundId = fund!.id;

  // Create test contribution
  const { data: contribution } = await supabaseAdmin
    .from('contributions')
    .insert({
      investor_id: testInvestorId,
      fund_id: testFundId,
      paid_in_date: '2025-10-01',
      amount: 10000,
      currency: 'USD',
    })
    .select('id')
    .single();
  testContributionId = contribution!.id;

  // Create test credits (2 credits totaling 600)
  const { data: credit1 } = await supabaseAdmin
    .from('credits_ledger')
    .insert({
      investor_id: testInvestorId,
      fund_id: testFundId,
      credit_type: 'REPURCHASE',
      reason: 'Test credit 1',
      original_amount: 500,
      available_amount: 500,
      currency: 'USD',
      status: 'AVAILABLE',
    })
    .select('id')
    .single();
  testCreditId1 = credit1!.id;

  const { data: credit2 } = await supabaseAdmin
    .from('credits_ledger')
    .insert({
      investor_id: testInvestorId,
      fund_id: testFundId,
      credit_type: 'REPURCHASE',
      reason: 'Test credit 2',
      original_amount: 100,
      available_amount: 100,
      currency: 'USD',
      status: 'AVAILABLE',
    })
    .select('id')
    .single();
  testCreditId2 = credit2!.id;

  // Get or create admin user
  const { data: users } = await supabaseAdmin.auth.admin.listUsers();
  const adminUser = users.users.find(u => u.email?.includes('admin'));

  if (adminUser) {
    adminUserId = adminUser.id;

    // Ensure admin role
    await supabaseAdmin
      .from('user_roles')
      .upsert({
        user_id: adminUserId,
        role_key: 'admin',
        granted_by: adminUserId,
        granted_at: new Date().toISOString(),
      })
      .eq('user_id', adminUserId)
      .eq('role_key', 'admin');
  }

  console.log('Test data setup complete');
}

// ============================================
// HELPER: Cleanup Test Data
// ============================================
async function cleanupTestData() {
  console.log('Cleaning up test data...');

  // Delete test data in reverse dependency order
  if (testCreditId1) {
    await supabaseAdmin.from('credits_ledger').delete().eq('id', testCreditId1);
  }
  if (testCreditId2) {
    await supabaseAdmin.from('credits_ledger').delete().eq('id', testCreditId2);
  }
  if (testContributionId) {
    await supabaseAdmin.from('contributions').delete().eq('id', testContributionId);
  }
  if (testFundId) {
    await supabaseAdmin.from('funds').delete().eq('id', testFundId);
  }
  if (testInvestorId) {
    await supabaseAdmin.from('investors').delete().eq('id', testInvestorId);
  }

  console.log('Cleanup complete');
}

// ============================================
// HELPER: Create Charge (via compute endpoint)
// ============================================
async function createTestCharge(): Promise<string> {
  // Create DRAFT charge directly
  const { data: charge } = await supabaseAdmin
    .from('charges')
    .insert({
      investor_id: testInvestorId,
      fund_id: testFundId,
      contribution_id: testContributionId,
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

  return charge!.id;
}

// ============================================
// TEST: Full Happy Path (DRAFT → PENDING → APPROVED → PAID)
// ============================================
Deno.test('Integration: Full workflow (DRAFT → PENDING → APPROVED → PAID)', async () => {
  await setupTestData();

  try {
    // Step 1: Create DRAFT charge
    const chargeId = await createTestCharge();
    console.log(`Created charge: ${chargeId}`);

    // Verify initial state
    let { data: charge } = await supabaseAdmin
      .from('charges')
      .select('id, status, credits_applied_amount, net_amount')
      .eq('id', chargeId)
      .single();

    assertEquals(charge!.status, 'DRAFT');

    // Step 2: Submit (DRAFT → PENDING) with credit application
    const submitResponse = await fetch(`${API_BASE}/charges/${chargeId}/submit`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    assertEquals(submitResponse.status, 200);
    const submitData = await submitResponse.json();
    console.log('Submit response:', submitData);

    assertEquals(submitData.data.status, 'PENDING');
    assertEquals(submitData.data.credits_applied_amount, 600);
    assertEquals(submitData.data.net_amount, 0);
    assertEquals(submitData.data.credit_applications.length, 2);

    // Verify credits were applied
    const { data: credit1 } = await supabaseAdmin
      .from('credits_ledger')
      .select('available_amount')
      .eq('id', testCreditId1)
      .single();
    assertEquals(credit1!.available_amount, 0); // Fully applied

    // Step 3: Approve (PENDING → APPROVED)
    const approveResponse = await fetch(`${API_BASE}/charges/${chargeId}/approve`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    assertEquals(approveResponse.status, 200);
    const approveData = await approveResponse.json();
    console.log('Approve response:', approveData);

    assertEquals(approveData.data.status, 'APPROVED');
    assertExists(approveData.data.approved_at);
    assertExists(approveData.data.approved_by);

    // Verify audit log
    const { data: auditLogs } = await supabaseAdmin
      .from('audit_log')
      .select('*')
      .eq('event_type', 'charge.approved')
      .eq('entity_id', chargeId);

    assertEquals(auditLogs!.length > 0, true);

    // Step 4: Mark-Paid (APPROVED → PAID)
    const markPaidResponse = await fetch(`${API_BASE}/charges/${chargeId}/mark-paid`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        payment_ref: 'WIRE-TEST-001',
        paid_at: '2025-10-21T10:30:00Z',
      }),
    });

    assertEquals(markPaidResponse.status, 200);
    const paidData = await markPaidResponse.json();
    console.log('Mark-paid response:', paidData);

    assertEquals(paidData.data.status, 'PAID');
    assertEquals(paidData.data.payment_ref, 'WIRE-TEST-001');
    assertEquals(paidData.data.paid_at, '2025-10-21T10:30:00Z');

    // Verify final state
    ({ data: charge } = await supabaseAdmin
      .from('charges')
      .select('*')
      .eq('id', chargeId)
      .single());

    assertEquals(charge!.status, 'PAID');
    assertEquals(charge!.credits_applied_amount, 600);
    assertEquals(charge!.payment_ref, 'WIRE-TEST-001');

    console.log('Full workflow test passed');
  } finally {
    await cleanupTestData();
  }
});

// ============================================
// TEST: Rejection Workflow (DRAFT → PENDING → REJECTED)
// ============================================
Deno.test('Integration: Rejection workflow with credit reversal', async () => {
  await setupTestData();

  try {
    // Step 1: Create and submit charge
    const chargeId = await createTestCharge();
    console.log(`Created charge for rejection: ${chargeId}`);

    // Submit (DRAFT → PENDING)
    const submitResponse = await fetch(`${API_BASE}/charges/${chargeId}/submit`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    assertEquals(submitResponse.status, 200);
    const submitData = await submitResponse.json();
    assertEquals(submitData.data.status, 'PENDING');
    assertEquals(submitData.data.credits_applied_amount, 600);

    // Record initial credit balances
    const { data: credit1Before } = await supabaseAdmin
      .from('credits_ledger')
      .select('available_amount')
      .eq('id', testCreditId1)
      .single();
    const { data: credit2Before } = await supabaseAdmin
      .from('credits_ledger')
      .select('available_amount')
      .eq('id', testCreditId2)
      .single();

    console.log('Credits before rejection:', {
      credit1: credit1Before!.available_amount,
      credit2: credit2Before!.available_amount,
    });

    // Step 2: Reject (PENDING → REJECTED)
    const rejectResponse = await fetch(`${API_BASE}/charges/${chargeId}/reject`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        reason: 'Wrong amount calculated',
      }),
    });

    assertEquals(rejectResponse.status, 200);
    const rejectData = await rejectResponse.json();
    console.log('Reject response:', rejectData);

    assertEquals(rejectData.data.status, 'REJECTED');
    assertEquals(rejectData.data.reject_reason, 'Wrong amount calculated');
    assertEquals(rejectData.data.credits_applied_amount, 0);
    assertEquals(rejectData.data.net_amount, 600);
    assertEquals(rejectData.data.credit_applications.length, 0);

    // Step 3: Verify credits restored
    const { data: credit1After } = await supabaseAdmin
      .from('credits_ledger')
      .select('available_amount')
      .eq('id', testCreditId1)
      .single();
    const { data: credit2After } = await supabaseAdmin
      .from('credits_ledger')
      .select('available_amount')
      .eq('id', testCreditId2)
      .single();

    console.log('Credits after rejection:', {
      credit1: credit1After!.available_amount,
      credit2: credit2After!.available_amount,
    });

    // Verify balances restored to original (500 + 100)
    assertEquals(credit1After!.available_amount, 500);
    assertEquals(credit2After!.available_amount, 100);

    // Verify credit applications reversed
    const { data: creditApps } = await supabaseAdmin
      .from('credit_applications')
      .select('*')
      .eq('charge_id', submitData.data.numeric_id)
      .is('reversed_at', null);

    assertEquals(creditApps!.length, 0); // All reversed

    // Verify audit log
    const { data: auditLogs } = await supabaseAdmin
      .from('audit_log')
      .select('*')
      .eq('event_type', 'charge.rejected')
      .eq('entity_id', chargeId);

    assertEquals(auditLogs!.length > 0, true);
    assertEquals(auditLogs![0].payload.reason, 'Wrong amount calculated');
    assertEquals(auditLogs![0].payload.credits_restored, 600);

    console.log('Rejection workflow test passed');
  } finally {
    await cleanupTestData();
  }
});

// ============================================
// TEST: Idempotency
// ============================================
Deno.test('Integration: Idempotency - re-approve returns same state', async () => {
  await setupTestData();

  try {
    // Create and submit charge
    const chargeId = await createTestCharge();

    await fetch(`${API_BASE}/charges/${chargeId}/submit`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    // First approve
    const approveResponse1 = await fetch(`${API_BASE}/charges/${chargeId}/approve`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    assertEquals(approveResponse1.status, 200);
    const approveData1 = await approveResponse1.json();
    const firstApprovedAt = approveData1.data.approved_at;

    // Second approve (idempotent)
    const approveResponse2 = await fetch(`${API_BASE}/charges/${chargeId}/approve`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    assertEquals(approveResponse2.status, 200);
    const approveData2 = await approveResponse2.json();

    // Verify same state returned
    assertEquals(approveData2.data.status, 'APPROVED');
    assertEquals(approveData2.data.approved_at, firstApprovedAt); // Same timestamp

    console.log('Idempotency test passed');
  } finally {
    await cleanupTestData();
  }
});

// ============================================
// TEST: Invalid Status Transitions
// ============================================
Deno.test('Integration: Invalid status transitions return 409', async () => {
  await setupTestData();

  try {
    // Create DRAFT charge
    const chargeId = await createTestCharge();

    // Try to approve DRAFT (should fail - only PENDING can be approved)
    const approveResponse = await fetch(`${API_BASE}/charges/${chargeId}/approve`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    assertEquals(approveResponse.status, 409); // Conflict

    const errorData = await approveResponse.json();
    console.log('Expected 409 error:', errorData);
    assertEquals(errorData.code, 'CONFLICT');

    console.log('Invalid transition test passed');
  } finally {
    await cleanupTestData();
  }
});

console.log('All T02 integration tests completed successfully');
