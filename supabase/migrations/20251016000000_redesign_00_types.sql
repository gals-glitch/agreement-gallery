-- Migration: 00_types.sql
-- Purpose: Create enum types for redesigned agreement system
-- Date: 2025-10-16

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'agreement_scope') THEN
    CREATE TYPE agreement_scope AS ENUM ('FUND','DEAL');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pricing_mode') THEN
    CREATE TYPE pricing_mode AS ENUM ('TRACK','CUSTOM');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'agreement_status') THEN
    CREATE TYPE agreement_status AS ENUM ('DRAFT','AWAITING_APPROVAL','APPROVED','SUPERSEDED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'track_code') THEN
    CREATE TYPE track_code AS ENUM ('A','B','C');
  END IF;
END $$;

COMMENT ON TYPE agreement_scope IS 'Agreement can apply to entire FUND or specific DEAL';
COMMENT ON TYPE pricing_mode IS 'TRACK = use Fund VI tracks A/B/C, CUSTOM = deal-specific rates';
COMMENT ON TYPE agreement_status IS 'Agreement lifecycle: DRAFT → AWAITING_APPROVAL → APPROVED (immutable) → SUPERSEDED (by amendment)';
COMMENT ON TYPE track_code IS 'Fund VI track codes: A (≤$3M), B ($3-6M), C (>$6M)';
