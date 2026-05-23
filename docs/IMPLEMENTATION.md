# Laya Backend — Implementation Reference

Technical architecture, design decisions, and data flows.

---

## Architecture Overview

```
Browser / SPA
      │
      ▼
Elysia HTTP Server (Bun, port 3001)
      │
      ├── Static Plugin (/admin → public/)
      │     ├── index.html     (login page)
      │     └── dashboard.html (admin CMS)
      │
      └── API Routes (/api/...)
            ├── auth.ts       → users table
            ├── articles.ts   → articles + categories
            ├── episodes.ts   → episodes + slides + slide_contents
            ├── slides.ts     → slides + slide_contents
            ├── categories.ts → categories
            └── settings.ts   → settings
                    │
                    ▼
             PostgreSQL 5432
               (laya_db)
```

---

## Database Schema

```
categories
  id, name, slug, created_at

articles
  id, slug, title, subtitle, description,
  hero_image, card_image, category_id (→categories),
  is_published, sort_order, created_at, updated_at

episodes
  id, article_id (→articles CASCADE), number, title,
  publish_date, is_published, is_locked, created_at, updated_at

slides
  id, episode_id (→episodes CASCADE), number,
  video_id, created_at, updated_at

slide_contents
  id, slide_id (→slides CASCADE), type, content, order_index

users
  id, name, email, password, role, is_premium,
  premium_until, api_token, created_at, updated_at

settings
  id, key, value, updated_at
```

All `updated_at` columns are maintained by PostgreSQL triggers (function `set_updated_at()`).

Cascade deletes: `article → episodes → slides → slide_contents` (deleting an article removes all its content).

---

## Data Layer (`src/db.ts`)

Uses `postgres` (postgres.js v3) — a lightweight, zero-dependency PostgreSQL client.

### Why postgres.js over node-postgres (pg)?

- Native Bun compatibility, no native bindings required
- Better TypeScript types out of the box
- `sql.unsafe()` accepts dynamic SQL + params array (needed for dynamic UPDATE queries in routes)

### `?` → `$n` conversion

Route files use MySQL-style `?` placeholders for historical reasons. `db.ts` contains:

```ts
function toPositional(sql, params): [string, unknown[]] {
  let i = 0
  return [sql.replace(/\?/g, () => `$${++i}`), params]
}
```

This means **all route SQL must use `?`**, never `$1` directly. The conversion happens transparently.

### `run()` auto-RETURNING

`run()` detects INSERT statements and auto-appends `RETURNING id`:

```ts
const isInsert = /^\s*INSERT/i.test(sql)
const finalSql = isInsert && !/RETURNING/i.test(sql) ? sql + ' RETURNING id' : sql
```

Return shape:
```ts
{ insertId: number | null, affectedRows: number }
```

- After INSERT: `insertId` = new row's `id`, `affectedRows` = 1
- After UPDATE/DELETE: `insertId` = null, `affectedRows` = row count (0 = not found)

---

## Authentication Flow

1. **Login** (`POST /api/auth/login`)
   - Look up user by email
   - Verify password with `Bun.password.verify()` (bcrypt, `$2y$` prefix compatible with PHP's bcrypt)
   - Generate 64-char hex token: `crypto.getRandomValues(new Uint8Array(32))`
   - Store in `users.api_token`
   - Return token + user object

2. **Request authentication** (protected routes)
   - `requireAuth(headers)` extracts `Authorization: Bearer <token>`
   - Looks up user by `api_token` in DB
   - Throws `{ status: 401 }` if missing/invalid

3. **Admin check**
   - `requireAdmin(headers)` calls `requireAuth` then checks `role IN ('admin','editor')`
   - Throws `{ status: 403 }` if insufficient role

4. **Logout** (`POST /api/auth/logout`)
   - Sets `api_token = NULL` in DB

5. **Session check** (`GET /api/auth/session`)
   - Returns `{ authenticated: false }` if no/invalid token (no 401 — safe for frontend polling)

---

## Content Hierarchy

```
Article (serial/series)
  └── Episode (numbered chapter)
        └── Slide (single screen / "reel")
              └── Content Block (text/heading/image block)
```

### Slide content model

A slide is a single-screen "reel" containing ordered content blocks:

```json
{
  "id": 1,
  "number": 1,
  "videoId": "1931697",
  "content": [
    { "id": 1, "type": "h1",   "text": "Profil Pak Ding", "order_index": 0 },
    { "id": 2, "type": "p",    "text": "PERKENALKAN...",   "order_index": 1 },
    { "id": 3, "type": "quote","text": "...",               "order_index": 2 }
  ]
}
```

Content types: `h1`, `h2`, `h3`, `p`, `img`, `quote`

`PUT /api/slides/:id` with a `content` array **replaces all blocks** (DELETE + INSERT). This is intentional — it simplifies the editor (no partial patch needed).

---

## API Response Envelope

All responses use a consistent envelope:

```json
{ "success": true,  "data": <payload> }
{ "success": false, "message": "Error description" }
{ "success": true,  "data": <payload>, "message": "..." }
```

HTTP status codes:
- `200` — OK (reads, updates)
- `201` — Created (inserts)
- `401` — Unauthorized (missing/invalid token)
- `403` — Forbidden (wrong role)
- `404` — Resource not found
- `422` — Validation error (missing required fields)
- `500` — Server error (caught by Elysia's `.onError()`)

---

## Admin Dashboard (`public/dashboard.html`)

Single-page application using **Alpine.js** (CDN, no build step).

### State management

One `Alpine.data('app', () => ({ ... }))` object manages all state:

```
app.page          — current section ('overview'|'articles'|'episodes'|'slides'|'categories'|'settings')
app.articles[]    — loaded article list
app.episodes[]    — episodes for selected article
app.slides[]      — slides for selected episode
app.modal         — modal state { show, mode, type, data }
app.toast[]       — notification stack (auto-dismiss 3.2s)
app.token         — JWT/Bearer token from localStorage
```

### API communication

`apiFetch(path, options)` — wrapper that injects `Authorization: Bearer <token>` and `Content-Type: application/json` headers automatically.

### Block editor

The slide editor renders a dynamic list of content blocks. Each block has:
- Type dropdown (h1/h2/h3/p/quote/img)
- Textarea for content
- Delete button

On save, the entire `content[]` array is sent to `PUT /api/slides/:id`, replacing all existing blocks.

---

## Frontend ↔ Backend Integration (laya-spa)

The SPA at `laya-spa/` consumes this API. Replace mock functions in `laya-spa/src/api/content.js`:

```js
const BASE = 'http://localhost:3001/api'

export async function getArticle(slug) {
  const res = await fetch(`${BASE}/articles/${slug}`)
  return (await res.json()).data
}

export async function getEpisodes(articleId) {
  const res = await fetch(`${BASE}/articles/${articleId}/episodes`)
  return (await res.json()).data
}

export async function getSlides(episodeId) {
  const res = await fetch(`${BASE}/episodes/${episodeId}/slides`)
  return (await res.json()).data
}
```

CORS is open (`origin: true`) — suitable for local development.

---

## Migration History

| Date | Change |
|------|--------|
| 2026-05-23 | Initial Bun/Elysia backend replacing PHP 7.4 |
| 2026-05-23 | Admin login page + dashboard (Alpine.js) |
| 2026-05-23 | PostgreSQL migration (from MAMP MySQL 8889) |

### MySQL → PostgreSQL changes

- `mysql2` replaced by `postgres` (postgres.js)
- `AUTO_INCREMENT` → `SERIAL`
- `TINYINT(1)` → `SMALLINT` (keeps 0/1 values compatible)
- `ENUM(...)` → `VARCHAR CHECK (col IN (...))`
- `ON DUPLICATE KEY UPDATE` → `ON CONFLICT (...) DO UPDATE SET`
- `ON UPDATE CURRENT_TIMESTAMP` → PostgreSQL trigger per table
- Backtick identifiers → standard double-quote (or unquoted)
- `?` placeholder conversion handled in `db.ts` — routes unchanged
