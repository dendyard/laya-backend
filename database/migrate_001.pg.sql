-- ============================================================
-- Migration 001 — tambah kolom musik_bg, hero_banners, description
-- Jalankan sekali di production:
--   psql -U <user> -d laya_db -f database/migrate_001.pg.sql
-- ============================================================

\connect laya_db

-- 1. Kolom musik_bg di episodes
ALTER TABLE episodes
  ADD COLUMN IF NOT EXISTS musik_bg VARCHAR(500);

-- 2. Tabel hero_banners (buat jika belum ada)
CREATE TABLE IF NOT EXISTS hero_banners (
  id         SERIAL       PRIMARY KEY,
  title      VARCHAR(255),
  description TEXT,
  image_url  VARCHAR(500) NOT NULL,
  series_id  INTEGER      REFERENCES series(id) ON DELETE SET NULL,
  episode_id INTEGER      REFERENCES episodes(id) ON DELETE SET NULL,
  is_active  SMALLINT     NOT NULL DEFAULT 1,
  sort_order INTEGER      NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE TRIGGER trg_hero_banners_updated_at
  BEFORE UPDATE ON hero_banners
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 3. Kolom description di hero_banners (jika tabel sudah ada tapi kolom belum)
ALTER TABLE hero_banners
  ADD COLUMN IF NOT EXISTS description TEXT;

-- Done
SELECT 'Migration 001 applied successfully' AS status;
