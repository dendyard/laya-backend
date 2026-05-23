# CLAUDE.md — Laya Backend

Instructions for Claude Code when working in this project.

## Stack

- **Runtime**: Bun 1.3.14 (`~/.bun/bin/bun`)
- **Framework**: Elysia (TypeScript)
- **Database**: PostgreSQL on `127.0.0.1:5432`, database `laya_db`
- **PG user**: `dendyardanygmail.com` (macOS username), no password
- **Admin UI**: Alpine.js (CDN), custom CSS — no build step

## Starting the server

```bash
~/.bun/bin/bun dev      # hot reload (development)
~/.bun/bin/bun start    # production
```

Server listens on **port 3001**.

- Admin login: `http://localhost:3001/admin`
- API root:    `http://localhost:3001/api`

After making source changes, restart with:
```bash
pkill -f "bun.*index.ts" && ~/.bun/bin/bun run src/index.ts > /tmp/laya-server.log 2>&1 &
```

## Project layout

```
src/
  index.ts          # Elysia app + plugin wiring + error handler
  db.ts             # postgres.js pool + query/queryOne/run helpers
  auth.ts           # extractToken / requireAuth / requireAdmin
  routes/
    articles.ts     # /api/articles
    episodes.ts     # /api/episodes
    slides.ts       # /api/slides
    categories.ts   # /api/categories
    settings.ts     # /api/settings
    auth.ts         # /api/auth/login|logout|session
public/
  index.html        # Login page (static, served at /admin)
  dashboard.html    # CRUD dashboard (Alpine.js)
database/
  schema.pg.sql     # PostgreSQL DDL (run once)
  seed.pg.sql       # Seed data
docs/
  API.md            # Endpoint reference
  IMPLEMENTATION.md # Architecture & design decisions
```

## Database helpers (`src/db.ts`)

Three helpers — keep using them for all DB access:

```ts
query<T>(sql, params?)      // returns T[]
queryOne<T>(sql, params?)   // returns T | null
run(sql, params?)           // returns { insertId, affectedRows }
```

**Use `?` placeholders** — the helpers auto-convert to `$1, $2, ...` for PostgreSQL.

`run()` auto-appends `RETURNING id` to INSERT statements, so `insertId` is always populated after an INSERT.

## Adding a new route

1. Create `src/routes/myroute.ts` exporting a `new Elysia({ prefix: '/api/...' })`
2. Import and `.use(myRouter)` in `src/index.ts`
3. Use `query / queryOne / run` from `../db`
4. Protect write routes with `await requireAdmin(headers)`

## Database migrations

Apply changes directly to the running PostgreSQL:

```bash
~/.bun/bin/bun -e "
import postgres from 'postgres'
const sql = postgres({ host:'127.0.0.1', port:5432, database:'laya_db', username:'dendyardanygmail.com', password:'' })
await sql.unsafe('ALTER TABLE ...')
await sql.end()
"
```

Or re-apply schema from scratch:
```bash
# Drop and recreate (destructive!)
~/.bun/bin/bun -e "
import postgres from 'postgres'
const admin = postgres({ host:'127.0.0.1', port:5432, database:'postgres', username:'dendyardanygmail.com', password:'' })
await admin\`DROP DATABASE IF EXISTS laya_db\`
await admin\`CREATE DATABASE laya_db\`
await admin.end()
"
# Then apply schema + seed (see README)
```

## Auth

Bearer token stored in `users.api_token` column (64-char hex, no JWT).

- `requireAuth(headers)` — throws 401 if no/invalid token
- `requireAdmin(headers)` — throws 403 if role is not admin/editor

Password hashing uses `Bun.password.verify()` (bcrypt compatible).

## Known gotchas

- **`?` vs `$n`**: Route files use `?` style — the `toPositional()` helper in `db.ts` converts them. Never use `$1` directly in route SQL strings.
- **IN clause**: Works fine — `WHERE id IN (?,?,?)` is converted to `WHERE id IN ($1,$2,$3)`.
- **`ON CONFLICT`**: PostgreSQL syntax, not `ON DUPLICATE KEY UPDATE`. Settings route uses `ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value`.
- **`updated_at`**: Automatically maintained by triggers in PostgreSQL (not application-level).
- **Static file caching**: Elysia caches static files at startup. Restart the server after editing `public/*.html`.
- **Admin dashboard path**: Must access `/admin/index.html` or `/admin/dashboard.html` — the bare `/admin` path also works.

## Testing endpoints

```bash
# Login
curl -s -X POST http://localhost:3001/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@laya.id","password":"admin123"}'

# List articles
curl -s http://localhost:3001/api/articles

# Create article (with token)
curl -s -X POST http://localhost:3001/api/articles \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <token>' \
  -d '{"slug":"new-article","title":"New Article"}'
```
