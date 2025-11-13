import { FeeRun, RunProgress, ApprovalEvent, ExceptionItem, CreateRunRequest, ApiList } from '@/types/runs';
import { supabase } from '@/integrations/supabase/client';
import { http } from '@/api/http';

// Mock data for demonstration (fallback)
const mockRuns: FeeRun[] = [
  {
    id: 'run-001',
    period_start: '2024-01-01',
    period_end: '2024-03-31',
    cut_off_label: 'Q1 2024',
    status: 'approved',
    totals: { base: 125000, net: 103250, vat: 21750, total: 125000 },
    exceptions_count: 0,
    created_at: '2024-04-01T09:00:00Z',
    updated_at: '2024-04-05T15:30:00Z',
    progress_percentage: 100,
  },
  {
    id: 'run-002', 
    period_start: '2024-04-01',
    period_end: '2024-06-30',
    cut_off_label: 'Q2 2024',
    status: 'reviewed',
    totals: { base: 89000, net: 73370, vat: 15630, total: 89000 },
    exceptions_count: 3,
    created_at: '2024-07-01T08:00:00Z',
    updated_at: '2024-07-03T14:20:00Z',
    progress_percentage: 85,
  },
  {
    id: 'run-003',
    period_start: '2024-07-01', 
    period_end: '2024-09-30',
    cut_off_label: 'Q3 2024',
    status: 'draft',
    exceptions_count: 0,
    created_at: '2024-09-28T10:00:00Z',
    updated_at: '2024-09-28T10:00:00Z',
    progress_percentage: 0,
  }
];

const mockExceptions: ExceptionItem[] = [
  {
    id: 'ex-001',
    code: 'MISSING_INVESTOR_DATA',
    severity: 'high',
    message: 'Investor "Omega Holdings LLC" missing tax residency information',
    entity_type: 'investor',
    entity_id: 'inv-001',
    suggested_fix: 'Update investor profile with tax residency',
    resolved: false,
  },
  {
    id: 'ex-002', 
    code: 'VAT_RATE_MISMATCH',
    severity: 'med',
    message: 'VAT rate conflict for partner "Aventine Advisors" (21% vs 19%)',
    entity_type: 'partner',
    entity_id: 'part-001',
    suggested_fix: 'Verify correct VAT rate for jurisdiction',
    resolved: false,
  },
  {
    id: 'ex-003',
    code: 'RULE_VERSION_CONFLICT', 
    severity: 'low',
    message: 'Commission rule AG-201 has newer version available',
    entity_type: 'rule',
    entity_id: 'AG-201',
    suggested_fix: 'Review and approve rule version update',
    resolved: false,
  }
];

// Simulate API delays
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

export const runsApi = {
  // Create new run
  async createRun(payload: CreateRunRequest): Promise<{ id: string }> {
    try {
      const { data, error } = await supabase.functions.invoke('fee-runs-api', {
        body: payload
      });

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Failed to create run:', error);
      // Fallback to mock
      await delay(500);
      const newId = `run-${String(Math.random()).slice(2, 8)}`;
      const newRun: FeeRun = {
        id: newId,
        ...payload,
        status: 'draft',
        exceptions_count: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        progress_percentage: 0,
      };
      mockRuns.unshift(newRun);
      return { id: newId };
    }
  },

  // List runs
  async listRuns(): Promise<ApiList<FeeRun>> {
    try {
      const response = await http.get('/runs');
      return { data: response.data || [] };
    } catch (error) {
      console.error('Failed to list runs:', error);
      // Fallback to mock
      await delay(300);
      return { data: [...mockRuns] };
    }
  },

  // Get single run
  async getRun(id: string): Promise<{ data: FeeRun }> {
    try {
      const { data, error } = await supabase.functions.invoke('fee-runs-api', {
        body: { action: 'get', id }
      });
      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Failed to get run:', error);
      // Fallback to mock
      await delay(200);
      const run = mockRuns.find(r => r.id === id);
      if (!run) {
        throw new Error(`Run ${id} not found`);
      }
      return { data: run };
    }
  },

  // Start calculation
  async startCalculate(id: string): Promise<{ jobId: string }> {
    try {
      const { data, error } = await supabase.functions.invoke('fee-runs-api', {
        body: { action: 'calculate', id }
      });
      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Failed to start calculation:', error);
      // Fallback to mock
      await delay(300);
      const run = mockRuns.find(r => r.id === id);
      if (run) {
        run.status = 'draft';
        run.progress_percentage = 5;
        run.updated_at = new Date().toISOString();
      }
      return { jobId: `job_${id}_${Date.now()}` };
    }
  },

  // Get progress (for polling)
  async getProgress(id: string): Promise<{ data: RunProgress }> {
    try {
      const { data, error } = await supabase.functions.invoke('fee-runs-api', {
        body: { action: 'progress', id }
      });
      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Failed to get progress:', error);
      // Fallback to mock
      await delay(100);
      const run = mockRuns.find(r => r.id === id);
      const progress = run?.progress_percentage || 0;
      
      // Simulate progress increment for demo
      if (run && progress < 100 && run.status === 'draft') {
        run.progress_percentage = Math.min(100, progress + Math.floor(Math.random() * 15));
        if (run.progress_percentage >= 100) {
          run.status = 'reviewed';
        }
      }
      
      return {
        data: {
          step: progress < 20 ? 'import' : progress < 40 ? 'match' : progress < 80 ? 'calculate' : progress < 95 ? 'review' : 'export',
          percent: progress,
          eta_sec: progress < 100 ? Math.max(10, (100 - progress) * 3) : undefined,
          counters: {
            distributions_processed: Math.floor(progress * 1.2),
            calculations_completed: Math.floor(progress * 0.8),
            exceptions_found: progress > 50 ? Math.floor(Math.random() * 3) : 0,
          }
        }
      };
    }
  },

  // Get run summary
  async getSummary(id: string): Promise<{ data: { totals?: FeeRun['totals']; exceptions_count: number } }> {
    await delay(200);
    const run = mockRuns.find(r => r.id === id);
    return {
      data: {
        totals: run?.totals,
        exceptions_count: run?.exceptions_count || 0,
      }
    };
  },

  // Approve run
  async approveRun(id: string, stage: 'reviewed' | 'approved'): Promise<void> {
    await delay(400);
    const run = mockRuns.find(r => r.id === id);
    if (run) {
      run.status = stage;
      run.updated_at = new Date().toISOString();
      if (stage === 'approved') {
        run.progress_percentage = 100;
      }
    }
  },

  // Get approvals log
  async getApprovals(id: string): Promise<{ data: ApprovalEvent[] }> {
    await delay(200);
    return {
      data: [
        {
          stage: 'reviewed',
          actor: 'Miri Cohen',
          at: '2024-09-28T14:30:00Z',
          comment: 'Initial review completed, 3 exceptions need resolution'
        }
      ]
    };
  },

  // Get exceptions
  async getExceptions(id: string): Promise<{ data: ExceptionItem[] }> {
    await delay(300);
    return { data: [...mockExceptions] };
  },

  // Resolve exception
  async resolveException(id: string, exceptionId: string): Promise<void> {
    await delay(400);
    const exception = mockExceptions.find(e => e.id === exceptionId);
    if (exception) {
      exception.resolved = true;
    }
    // Update run exceptions count
    const run = mockRuns.find(r => r.id === id);
    if (run) {
      run.exceptions_count = mockExceptions.filter(e => !e.resolved).length;
    }
  },

  // Recalculate
  async recalculate(id: string, scope: 'item' | 'partner' | 'run'): Promise<{ jobId: string }> {
    await delay(500);
    const run = mockRuns.find(r => r.id === id);
    if (run) {
      run.progress_percentage = 10;
      run.updated_at = new Date().toISOString();
    }
    return { jobId: `recalc_${id}_${Date.now()}` };
  },

  /**
   * Get detailed run outputs for re-export (from run_record)
   */
  async getRunDetail(id: string): Promise<{
    data: {
      run_hash: string;
      config_version: string;
      inputs: any;
      outputs: any;
      scope_breakdown: any;
      created_at: string;
    }
  }> {
    const url = `https://qwgicrdcoqdketqhxbys.supabase.co/functions/v1/fee-runs-api/${id}/detail`;
    const { data } = await supabase.auth.getSession();
    
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${data.session?.access_token || ''}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error(`Failed to fetch run detail: ${response.statusText}`);
    }
    
    return await response.json();
  },
};