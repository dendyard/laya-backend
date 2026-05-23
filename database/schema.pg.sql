-- ============================================================
-- Laya Backend — PostgreSQL Schema
-- PostgreSQL 14+
-- ============================================================

CREATE DATABASE laya_db;
\connect laya_db

-- trigger helper for auto-updating updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- categories
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id         SERIAL       PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  slug       VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- series
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS series (
  id           SERIAL        PRIMARY KEY,
  slug         VARCHAR(150)  NOT NULL UNIQUE,
  title        VARCHAR(255)  NOT NULL,
  subtitle     VARCHAR(255),
  description  TEXT,
  hero_image   VARCHAR(500),
  card_image   VARCHAR(500),
  category_id  INTEGER       REFERENCES categories(id) ON DELETE SET NULL ON UPDATE CASCADE,
  is_published SMALLINT      NOT NULL DEFAULT 0,
  sort_order   INTEGER       NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_series_published ON series(is_published);

CREATE TRIGGER trg_series_updated_at
  BEFORE UPDATE ON series
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------
-- episodes
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS episodes (
  id           SERIAL        PRIMARY KEY,
  series_id   INTEGER       NOT NULL REFERENCES series(id) ON DELETE CASCADE ON UPDATE CASCADE,
  number       INTEGER       NOT NULL DEFAULT 1,
  title        VARCHAR(255)  NOT NULL,
  publish_date VARCHAR(50),
  is_published SMALLINT      NOT NULL DEFAULT 0,
  is_locked    SMALLINT      NOT NULL DEFAULT 1,
  musik_bg     VARCHAR(500),
  card_image   VARCHAR(500),
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_episodes_series ON episodes(series_id);

CREATE TRIGGER trg_episodes_updated_at
  BEFORE UPDATE ON episodes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------
-- slides
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS slides (
  id         SERIAL       PRIMARY KEY,
  episode_id INTEGER      NOT NULL REFERENCES episodes(id) ON DELETE CASCADE ON UPDATE CASCADE,
  number     INTEGER      NOT NULL DEFAULT 1,
  video_id   VARCHAR(50),
  content    TEXT,
  created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_slides_episode ON slides(episode_id);

CREATE TRIGGER trg_slides_updated_at
  BEFORE UPDATE ON slides
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------
-- users
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id            SERIAL        PRIMARY KEY,
  name          VARCHAR(150)  NOT NULL,
  email         VARCHAR(255)  NOT NULL UNIQUE,
  password      VARCHAR(255)  NOT NULL,
  role          VARCHAR(10)   NOT NULL DEFAULT 'user'
                  CHECK (role IN ('admin','editor','user')),
  is_premium    SMALLINT      NOT NULL DEFAULT 0,
  premium_until TIMESTAMPTZ,
  api_token     VARCHAR(64),
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_token ON users(api_token);

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------
-- settings
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (
  id         SERIAL       PRIMARY KEY,
  key        VARCHAR(100) NOT NULL UNIQUE,
  value      TEXT,
  updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_settings_updated_at
  BEFORE UPDATE ON settings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------
-- hero_banners
-- ------------------------------------------------------------
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

CREATE TRIGGER trg_hero_banners_updated_at
  BEFORE UPDATE ON hero_banners
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
