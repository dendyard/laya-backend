-- ============================================================
-- Laya Backend — Database Schema
-- MySQL 8.0+  |  charset utf8mb4
-- ============================================================

CREATE DATABASE IF NOT EXISTS laya_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE laya_db;

-- ------------------------------------------------------------
-- categories
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  id         INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  name       VARCHAR(100)     NOT NULL,
  slug       VARCHAR(100)     NOT NULL,
  created_at TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- articles  (series / original content)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS articles (
  id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  slug         VARCHAR(150)  NOT NULL,
  title        VARCHAR(255)  NOT NULL,
  subtitle     VARCHAR(255)      NULL,
  description  TEXT              NULL,
  hero_image   VARCHAR(500)      NULL,
  card_image   VARCHAR(500)      NULL,
  category_id  INT UNSIGNED      NULL,
  is_published TINYINT(1)    NOT NULL DEFAULT 0,
  sort_order   INT           NOT NULL DEFAULT 0,
  created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_articles_slug (slug),
  KEY idx_articles_published (is_published),
  CONSTRAINT fk_articles_category
    FOREIGN KEY (category_id) REFERENCES categories (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- episodes
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS episodes (
  id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  article_id   INT UNSIGNED  NOT NULL,
  number       INT           NOT NULL DEFAULT 1,
  title        VARCHAR(255)  NOT NULL,
  publish_date VARCHAR(50)       NULL COMMENT 'Display string, e.g. "1 Juni 2026" or "Akan Datang"',
  is_published TINYINT(1)    NOT NULL DEFAULT 0,
  is_locked    TINYINT(1)    NOT NULL DEFAULT 1,
  created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_episodes_article (article_id),
  CONSTRAINT fk_episodes_article
    FOREIGN KEY (article_id) REFERENCES articles (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- slides  (each episode is split into slides / reels)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS slides (
  id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  episode_id INT UNSIGNED  NOT NULL,
  number     INT           NOT NULL DEFAULT 1,
  video_id   VARCHAR(50)       NULL COMMENT 'JX Player video ID',
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_slides_episode (episode_id),
  CONSTRAINT fk_slides_episode
    FOREIGN KEY (episode_id) REFERENCES episodes (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- slide_contents  (text / heading blocks inside a slide)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS slide_contents (
  id          INT UNSIGNED                                NOT NULL AUTO_INCREMENT,
  slide_id    INT UNSIGNED                                NOT NULL,
  type        ENUM('h1','h2','h3','p','img','quote')      NOT NULL DEFAULT 'p',
  content     TEXT                                        NOT NULL,
  order_index INT                                         NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_slide_contents_slide (slide_id),
  CONSTRAINT fk_slide_contents_slide
    FOREIGN KEY (slide_id) REFERENCES slides (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- users
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED                          NOT NULL AUTO_INCREMENT,
  name          VARCHAR(150)                          NOT NULL,
  email         VARCHAR(255)                          NOT NULL,
  password      VARCHAR(255)                          NOT NULL,
  role          ENUM('admin','editor','user')         NOT NULL DEFAULT 'user',
  is_premium    TINYINT(1)                            NOT NULL DEFAULT 0,
  premium_until DATETIME                                  NULL,
  api_token     VARCHAR(64)                               NULL,
  created_at    TIMESTAMP                             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP                             NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_token (api_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- settings  (key-value store for app config)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (
  id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `key`      VARCHAR(100)  NOT NULL,
  value      TEXT              NULL,
  updated_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_settings_key (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
