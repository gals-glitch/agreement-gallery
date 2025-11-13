export type RunStatus = 'draft' | 'reviewed' | 'approved' | 'exported' | 'failed';

export interface FeeRun {
  id: string;
  period_start: string;
  period_end: string;
  cut_off_label: string;
  status: RunStatus;
  totals?: {
    base: number;
    net: number;
    vat: number;
    total: number;
  };
  exceptions_count?: number;
  created_at: string;
  updated_at: string;
  created_by?: string;
  started_by?: string;
  completed_at?: string;
  progress_percentage?: number;
  estimated_completion?: string;
}

export interface RunProgress {
  step: 'import' | 'match' | 'calculate' | 'review' | 'approve' | 'export';
  percent: number;
  eta_sec?: number;
  counters: Record<string, number>;
}

export interface ApprovalEvent {
  stage: 'reviewed' | 'approved';
  actor: string;
  at: string;
  comment?: string;
}

export interface ExceptionItem {
  id: string;
  code: string;
  severity: 'low' | 'med' | 'high';
  message: string;
  entity_type?: string;
  entity_id?: string;
  suggested_fix?: string;
  resolved: boolean;
}

export interface CreateRunRequest {
  period_start: string;
  period_end: string;
  cut_off_label: string;
}

export interface ApiList<T> {
  data: T[];
  next_cursor?: string;
}

export interface ApiError {
  error: {
    code: 'INVALID_INPUT' | 'NOT_FOUND' | 'FORBIDDEN' | 'CONFLICT' | 'INTERNAL';
    message: string;
  };
}