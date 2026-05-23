# Laya Backend — API Reference

Base URL: `http://localhost:3001/api`

All responses are JSON with the envelope:

```json
{ "success": true, "message": "OK", "data": <payload> }
{ "success": false, "message": "Error description" }
```

---

## Authentication

Token-based. After login, pass the token in every protected request:

```
Authorization: Bearer <token>
```

Protected routes are marked **🔒 Auth required**.

---

## Endpoints

### Articles

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/articles` | — | List all published articles |
| GET | `/articles/{id\|slug}` | — | Get single article |
| POST | `/articles` | 🔒 Admin | Create article |
| PUT | `/articles/{id}` | 🔒 Admin | Update article |
| DELETE | `/articles/{id}` | 🔒 Admin | Delete article |

**GET /articles**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "slug": "tato-dayak",
      "title": "Tato Dayak Terakhir",
      "subtitle": "Bagian 1, Mengenal Pak Ding",
      "description": "...",
      "hero_image": "/assets/tato-dayak1.png",
      "card_image": "/assets/tato-dayak1.png",
      "category_id": 1,
      "category_name": "Laya Series",
      "category_slug": "laya-series",
      "is_published": 1,
      "sort_order": 1,
      "created_at": "2026-05-23 00:00:00",
      "updated_at": "2026-05-23 00:00:00"
    }
  ]
}
```

**POST /articles** body:
```json
{
  "slug": "artikel-baru",
  "title": "Judul Artikel",
  "subtitle": "Subjudul opsional",
  "description": "Deskripsi serial...",
  "hero_image": "/assets/hero.png",
  "card_image": "/assets/card.png",
  "category_id": 1,
  "is_published": 0,
  "sort_order": 2
}
```

---

### Episodes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/articles/{id}/episodes` | — | List episodes for an article |
| POST | `/articles/{id}/episodes` | 🔒 Admin | Create episode |
| GET | `/episodes/{id}` | — | Get single episode |
| PUT | `/episodes/{id}` | 🔒 Admin | Update episode |
| DELETE | `/episodes/{id}` | 🔒 Admin | Delete episode |

**GET /articles/1/episodes**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "article_id": 1,
      "number": 1,
      "title": "Mengenal Pak Ding",
      "publish_date": "1 Juni 2026",
      "is_published": 1,
      "is_locked": 0
    },
    {
      "id": 2,
      "article_id": 1,
      "number": 2,
      "title": "Membaca Bahasa Visual dalam Tato Dayak",
      "publish_date": "Akan Datang",
      "is_published": 0,
      "is_locked": 1
    }
  ]
}
```

**POST /articles/1/episodes** body:
```json
{
  "number": 3,
  "title": "Judul Episode",
  "publish_date": "1 Juli 2026",
  "is_published": 0,
  "is_locked": 1
}
```

---

### Slides

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/episodes/{id}/slides` | — | List slides (with content) for an episode |
| POST | `/episodes/{id}/slides` | 🔒 Admin | Create slide |
| GET | `/slides/{id}` | — | Get single slide with content |
| PUT | `/slides/{id}` | 🔒 Admin | Update slide (and optionally replace content) |
| DELETE | `/slides/{id}` | 🔒 Admin | Delete slide |
| GET | `/slides/{id}/contents` | — | List content blocks |
| POST | `/slides/{id}/contents` | 🔒 Admin | Append content blocks |

**GET /episodes/1/slides**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "number": 1,
      "videoId": "1931697",
      "content": [
        { "id": 1, "type": "h1", "text": "Profil Pak Ding", "order_index": 0 },
        { "id": 2, "type": "p",  "text": "PERKENALKAN, ia adalah...", "order_index": 1 }
      ]
    }
  ]
}
```

**POST /episodes/1/slides** body:
```json
{
  "number": 10,
  "video_id": "1234567",
  "content": [
    { "type": "h1", "text": "Judul Slide" },
    { "type": "p",  "text": "Paragraf pertama..." }
  ]
}
```

**PUT /slides/1** — send only the fields you want to change:
```json
{
  "video_id": "9999999",
  "content": [
    { "type": "p", "text": "Teks baru..." }
  ]
}
```
> Sending `content` replaces all existing content blocks for that slide.

---

### Categories

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/categories` | — | List all categories |
| GET | `/categories/{id\|slug}` | — | Get single category |
| POST | `/categories` | 🔒 Admin | Create category |
| PUT | `/categories/{id}` | 🔒 Admin | Update category |
| DELETE | `/categories/{id}` | 🔒 Admin | Delete category |

---

### Settings

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/settings` | — | Get all settings as key-value object |
| POST | `/settings` | 🔒 Admin | Upsert one or many settings |

**GET /settings**
```json
{
  "success": true,
  "data": {
    "app_name": "Laya",
    "app_version": "1.0.0",
    "premium_price_monthly": "69000",
    "premium_price_yearly": "599000",
    "premium_currency": "IDR",
    "maintenance_mode": "0"
  }
}
```

**POST /settings** body:
```json
{
  "maintenance_mode": "1",
  "premium_price_monthly": "79000"
}
```

---

### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/login` | — | Login and receive token |
| POST | `/auth/logout` | 🔒 | Invalidate token |
| GET | `/auth/session` | — | Check current session |

**POST /auth/login** body:
```json
{ "email": "admin@laya.id", "password": "admin123" }
```
Response:
```json
{
  "success": true,
  "data": {
    "token": "abc123...",
    "user": { "id": 1, "name": "Admin Laya", "email": "admin@laya.id", "role": "admin", "is_premium": true }
  }
}
```

**GET /auth/session**
```json
{
  "success": true,
  "data": {
    "authenticated": true,
    "user": { "id": 1, "name": "Admin Laya", "role": "admin", "is_premium": true, "premium_until": null }
  }
}
```

---

## Error codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 204 | No content |
| 400 | Bad request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not found |
| 405 | Method not allowed |
| 422 | Validation error |
| 500 | Server error |
