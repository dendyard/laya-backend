-- ============================================================
-- Migration 002 — card_image pindah ke episodes
-- Jalankan sekali di production:
--   psql -U <user> -d laya_db -f database/migrate_002.pg.sql
-- ============================================================

\connect laya_db

ALTER TABLE episodes
  ADD COLUMN IF NOT EXISTS card_image VARCHAR(500);

SELECT 'Migration 002 applied successfully' AS status;
