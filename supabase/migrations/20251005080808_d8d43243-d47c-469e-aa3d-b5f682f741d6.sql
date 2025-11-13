-- Create simplified fund_vi_tracks table
CREATE TABLE IF NOT EXISTS public.fund_vi_tracks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  track_key text NOT NULL CHECK (track_key IN ('A', 'B', 'C')),
  min_raised numeric NOT NULL,
  max_raised numeric,
  upfront_rate_bps integer NOT NULL,
  deferred_rate_bps integer NOT NULL,
  deferred_offset_months integer NOT NULL DEFAULT 24,
  config_version text NOT NULL DEFAULT 'v1.0',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(track_key, config_version)
);

-- Enable RLS
ALTER TABLE public.fund_vi_tracks ENABLE ROW LEVEL SECURITY;

-- Admin/Manager can access tracks
CREATE POLICY "Admin/Manager can access fund vi tracks"
  ON public.fund_vi_tracks
  FOR ALL
  USING (is_admin_or_manager(auth.uid()));

-- Insert default Fund VI tracks (A/B/C)
INSERT INTO public.fund_vi_tracks (track_key, min_raised, max_raised, upfront_rate_bps, deferred_rate_bps, config_version)
VALUES
  ('A', 0, 3000000, 120, 80, 'v1.0'),           -- ≤$3M: 1.2% upfront + 0.8% at +24m
  ('B', 3000000, 6000000, 180, 80, 'v1.0'),     -- $3-6M: 1.8% upfront + 0.8% at +24m
  ('C', 6000000, NULL, 180, 130, 'v1.0')        -- >$6M: 1.8% upfront + 1.3% at +24m
ON CONFLICT (track_key, config_version) DO NOTHING;

-- Add agreement.track_key for Fund VI
ALTER TABLE public.agreements
ADD COLUMN IF NOT EXISTS track_key text CHECK (track_key IN ('A', 'B', 'C'));

-- Add vat_mode to agreements if not exists
ALTER TABLE public.agreements
ADD COLUMN IF NOT EXISTS vat_mode text DEFAULT 'added' CHECK (vat_mode IN ('included', 'added'));

-- Create run_records table for audit (simple JSON blob storage)
CREATE TABLE IF NOT EXISTS public.run_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  calculation_run_id uuid REFERENCES public.calculation_runs(id),
  config_version text NOT NULL,
  inputs jsonb NOT NULL,
  outputs jsonb NOT NULL,
  run_hash text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.run_records ENABLE ROW LEVEL SECURITY;

-- Admin/Manager can access run records
CREATE POLICY "Admin/Manager can access run records"
  ON public.run_records
  FOR ALL
  USING (is_admin_or_manager(auth.uid()));