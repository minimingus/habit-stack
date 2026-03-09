-- Add pause support to habits table
ALTER TABLE habits ADD COLUMN IF NOT EXISTS paused_until timestamptz;
