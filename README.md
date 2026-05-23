# Laya Backend

REST API + Admin Dashboard untuk aplikasi **Laya** — platform konten premium berbasis episode dan slide (reels reader).

## Tech Stack

- **Bun 1.3+** — JavaScript runtime & package manager
- **Elysia** — Web framework untuk Bun
- **PostgreSQL** — Database (port 5432)
- **Alpine.js + Custom CSS** — Admin dashboard UI

## Struktur Proyek

```
laya-backend/
├── src/
│   ├── index.ts            # Entry point Elysia app
│   ├── db.ts               # PostgreSQL pool & query helpers
│   ├── auth.ts             # Token auth helpers
│   └── routes/
│       ├── articles.ts
│       ├── episodes.ts
│       ├── slides.ts
│       ├── auth.ts
│       ├── categories.ts
│       └── settings.ts
├── public/
│   ├── index.html          # Login page
│   └── dashboard.html      # Admin dashboard (CRUD)
├── database/
│   ├── schema.pg.sql       # PostgreSQL DDL
│   └── seed.pg.sql         # Data awal
├── docs/
│   ├── API.md              # Dokumentasi endpoint
│   └── IMPLEMENTATION.md   # Arsitektur & keputusan teknis
└── CLAUDE.md               # Instruksi untuk Claude Code
```

## Instalasi

### 1. Install Bun

```bash
curl -fsSL https://bun.sh/install | bash
```

### 2. Install dependencies

```bash
bun install
```

### 3. Setup Database (PostgreSQL)

Pastikan PostgreSQL berjalan di port 5432, lalu buat database dan apply schema:

```bash
# Buat database
bun -e "
import postgres from 'postgres'
const sql = postgres({ host:'127.0.0.1', port:5432, database:'postgres', username:\$(whoami), password:'' })
await sql\`CREATE DATABASE laya_db\`
await sql.end()
"

# Apply schema
bun -e "
import postgres from 'postgres'
import { readFileSync } from 'fs'
const sql = postgres({ host:'127.0.0.1', port:5432, database:'laya_db', username:\$(whoami), password:'' })
const schema = readFileSync('database/schema.pg.sql','utf8').replace(/^CREATE DATABASE.*$/m,'').replace(/^\\\\connect.*$/m,'')
await sql.unsafe(schema)
await sql.end()
"

# Apply seed data
bun -e "
import postgres from 'postgres'
import { readFileSync } from 'fs'
const sql = postgres({ host:'127.0.0.1', port:5432, database:'laya_db', username:\$(whoami), password:'' })
const seed = readFileSync('database/seed.pg.sql','utf8').replace(/^\\\\connect.*$/m,'')
await sql.unsafe(seed)
await sql.end()
"
```

### 4. Konfigurasi koneksi database

Edit `src/db.ts` dan sesuaikan `username` dengan username macOS Anda:

```ts
export const pg = postgres({
  host: '127.0.0.1',
  port: 5432,
  database: 'laya_db',
  username: 'your-username', // ← ganti ini
  password: '',
})
```

### 5. Jalankan Server

```bash
# Development (hot reload)
bun dev

# Production
bun start
```

Server berjalan di **`http://localhost:3001`**

## URL

| URL | Keterangan |
|-----|-----------|
| `http://localhost:3001/admin` | Login page admin |
| `http://localhost:3001/admin/dashboard.html` | Dashboard CRUD |
| `http://localhost:3001/api` | API root + endpoint list |

## Admin Login

- Email: `admin@laya.id`
- Password: `admin123`

## API

Dokumentasi lengkap di [`docs/API.md`](docs/API.md).  
Detail arsitektur di [`docs/IMPLEMENTATION.md`](docs/IMPLEMENTATION.md).

### Quick reference

| Method | Endpoint | Keterangan |
|--------|----------|-----------|
| GET | `/api/articles` | Daftar artikel |
| GET | `/api/articles/:id` | Detail artikel (id atau slug) |
| GET | `/api/articles/:id/episodes` | Daftar episode |
| POST | `/api/articles/:id/episodes` | Buat episode baru 🔒 |
| GET | `/api/episodes/:id/slides` | Slides + konten |
| POST | `/api/episodes/:id/slides` | Buat slide baru 🔒 |
| GET | `/api/categories` | Daftar kategori |
| GET | `/api/settings` | Konfigurasi app |
| POST | `/api/auth/login` | Login, dapat token |
| GET | `/api/auth/session` | Cek sesi aktif |

🔒 = butuh `Authorization: Bearer <token>`

## Database Schema

```
categories ──→ articles ──→ episodes ──→ slides ──→ slide_contents
users  (auth via api_token)
settings  (key-value store)
```

## Integrasi ke laya-spa

Edit `laya-spa/src/api/content.js`:

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
