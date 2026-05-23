import { Elysia } from 'elysia'
import { query, run } from '../db'
import { requireAdmin } from '../auth'

export const settingsRouter = new Elysia({ prefix: '/api/settings' })

  .get('/', async () => {
    const rows = await query<{ key: string; value: string }>('SELECT key, value FROM settings ORDER BY key ASC')
    const map = Object.fromEntries(rows.map(r => [r.key, r.value]))
    return { success: true, data: map }
  })

  .post('/', async ({ body, headers, set }: any) => {
    await requireAdmin(headers)
    if (!body || typeof body !== 'object') {
      set.status = 422
      return { success: false, message: 'No settings provided' }
    }
    for (const [key, value] of Object.entries(body)) {
      await run('INSERT INTO settings (key, value) VALUES (?,?) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value', [key, value])
    }
    const rows = await query<{ key: string; value: string }>('SELECT key, value FROM settings ORDER BY key ASC')
    const map = Object.fromEntries(rows.map(r => [r.key, r.value]))
    return { success: true, data: map }
  })
