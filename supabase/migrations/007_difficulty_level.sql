-- Add difficulty level to habits (1=Easy, 2=Medium, 3=Hard)
ALTER TABLE habits
    ADD COLUMN IF NOT EXISTS difficulty_level INT NOT NULL DEFAULT 1
    CHECK (difficulty_level BETWEEN 1 AND 3);
