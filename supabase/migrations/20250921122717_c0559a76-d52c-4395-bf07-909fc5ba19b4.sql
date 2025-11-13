-- Update rule_type enum to include new values
ALTER TYPE rule_type ADD VALUE IF NOT EXISTS 'management_fee';
ALTER TYPE rule_type ADD VALUE IF NOT EXISTS 'promote_share'; 
ALTER TYPE rule_type ADD VALUE IF NOT EXISTS 'credit_netting';
ALTER TYPE rule_type ADD VALUE IF NOT EXISTS 'discount';
ALTER TYPE rule_type ADD VALUE IF NOT EXISTS 'sub_agent_split';