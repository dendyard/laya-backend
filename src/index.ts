import { Elysia } from 'elysia'
import { cors } from '@elysiajs/cors'
import { staticPlugin } from '@elysiajs/static'
import { seriesRouter } from './routes/series'
import { episodesRouter } from './routes/episodes'
import { slidesRouter } from './routes/slides'
import { authRouter } from './routes/auth'
import { categoriesRouter } from './routes/categories'
import { settingsRouter } from './routes/settings'
import { heroBannersRouter, uploadRouter } from './routes/hero_banners'

const PORT = 3001

const app = new Elysia()
  .use(cors({ origin: true, credentials: true }))
  .use(staticPlugin({ assets: 'public', prefix: '/admin' }))

  // ── API routes ──────────────────────────────────────────────────────────
  .use(authRouter)
  .use(seriesRouter)
  .use(episodesRouter)
  .use(slidesRouter)
  .use(categoriesRouter)
  .use(settingsRouter)
  .use(heroBannersRouter)
  .use(uploadRouter)

  // ── API root ────────────────────────────────────────────────────────────
  .get('/api', () => ({
    success: true,
    name: 'Laya Backend API',
    version: '2.0.0',
    runtime: 'Bun ' + Bun.version,
    framework: 'Elysia',
    endpoints: [
      'GET  /api/series',
      'GET  /api/series/:id',
      'GET  /api/series/:id/episodes',
      'GET  /api/episodes/:id/slides',
      'GET  /api/categories',
      'GET  /api/settings',
      'POST /api/auth/login',
      'POST /api/auth/logout',
      'GET  /api/auth/session',
    ],
  }))

  // ── Redirect / → admin login ─────────────────────────────────────────────
  .get('/', ({ redirect }) => redirect('/admin/index.html'))

  // ── Global error handler ─────────────────────────────────────────────────
  .onError(({ error, set }) => {
    const err = error as any
    if (err?.status) {
      set.status = err.status
      return { success: false, message: err.message }
    }
    set.status = 500
    return { success: false, message: String(err?.message ?? 'Internal server error') }
  })

  .listen(PORT)

console.log(`\n🦊 Laya Backend (Bun + Elysia)`)
console.log(`   API    → http://localhost:${PORT}/api`)
console.log(`   Admin  → http://localhost:${PORT}/admin\n`)
