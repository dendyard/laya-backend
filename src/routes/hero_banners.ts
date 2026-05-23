import { Elysia } from 'elysia'
import { query, queryOne, run } from '../db'
import { requireAdmin } from '../auth'
import { join } from 'path'

function origin(req: Request) {
  const u = new URL(req.url)
  return `${u.protocol}//${u.host}`
}

function fmt(r: any, base: string) {
  const imageUrl = r.image_url?.startsWith('/') ? `${base}${r.image_url}` : r.image_url
  return {
    id: r.id, title: r.title ?? '', description: r.description ?? '', image_url: imageUrl,
    series_id: r.series_id, episode_id: r.episode_id,
    series_title: r.series_title ?? null, episode_title: r.episode_title ?? null,
    is_active: r.is_active, sort_order: r.sort_order,
    created_at: r.created_at,
  }
}

const JOIN_SQL = `
  SELECT h.*, s.title AS series_title, e.title AS episode_title
  FROM hero_banners h
  LEFT JOIN series s ON s.id = h.series_id
  LEFT JOIN episodes e ON e.id = h.episode_id`

export const heroBannersRouter = new Elysia({ prefix: '/api/hero-banners' })

  .get('/', async ({ request }: any) => {
    const rows = await query<any>(`${JOIN_SQL} ORDER BY h.sort_order ASC, h.id ASC`)
    const base = origin(request)
    return { success: true, data: rows.map(r => fmt(r, base)) }
  })

  .get('/:id', async ({ params, request, set }: any) => {
    const row = await queryOne<any>(`${JOIN_SQL} WHERE h.id = ? LIMIT 1`, [params.id])
    if (!row) { set.status = 404; return { success: false, message: 'Hero banner not found' } }
    return { success: true, data: fmt(row, origin(request)) }
  })

  .post('/', async ({ body, headers, request, set }: any) => {
    await requireAdmin(headers)
    const { title, description, image_url, series_id, episode_id, is_active = 1, sort_order = 0 } = body ?? {}
    if (!image_url) { set.status = 422; return { success: false, message: 'image_url required' } }
    const r = await run(
      'INSERT INTO hero_banners (title,description,image_url,series_id,episode_id,is_active,sort_order) VALUES (?,?,?,?,?,?,?)',
      [title ?? null, description ?? null, image_url, series_id ?? null, episode_id ?? null, is_active, sort_order]
    )
    const row = await queryOne<any>(`${JOIN_SQL} WHERE h.id = ?`, [r.insertId])
    set.status = 201
    return { success: true, data: fmt(row!, origin(request)) }
  })

  .put('/:id', async ({ params, body, headers, request, set }: any) => {
    await requireAdmin(headers)
    const allowed = ['title', 'description', 'image_url', 'series_id', 'episode_id', 'is_active', 'sort_order']
    const fields: string[] = []
    const values: unknown[] = []
    for (const k of allowed) {
      if (k in body) { fields.push(`${k} = ?`); values.push((body as any)[k]) }
    }
    if (!fields.length) { set.status = 422; return { success: false, message: 'Nothing to update' } }
    values.push(params.id)
    await run(`UPDATE hero_banners SET ${fields.join(',')} WHERE id = ?`, values)
    const row = await queryOne<any>(`${JOIN_SQL} WHERE h.id = ?`, [params.id])
    return { success: true, data: fmt(row!, origin(request)) }
  })

  .delete('/:id', async ({ params, headers, set }: any) => {
    await requireAdmin(headers)
    const r = await run('DELETE FROM hero_banners WHERE id = ?', [params.id])
    if (!r.affectedRows) { set.status = 404; return { success: false, message: 'Hero banner not found' } }
    return { success: true, message: 'Hero banner deleted' }
  })

export const uploadRouter = new Elysia({ prefix: '/api/upload' })

  .post('/', async ({ request, headers, set }: any) => {
    await requireAdmin(headers)
    let formData: FormData
    try { formData = await request.formData() }
    catch { set.status = 400; return { success: false, message: 'Invalid multipart data' } }

    const file = formData.get('file') as File | null
    if (!file || typeof file === 'string') {
      set.status = 422; return { success: false, message: 'file field required' }
    }

    const ext = file.name.split('.').pop()?.toLowerCase() ?? 'jpg'
    const allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp3', 'aac', 'm4a', 'ogg']
    if (!allowed.includes(ext)) {
      set.status = 422; return { success: false, message: 'Only jpg, png, webp, gif, mp3, aac, m4a, ogg allowed' }
    }

    const filename = `${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`
    const dest = join(import.meta.dir, '../../public/uploads', filename)
    await Bun.write(dest, await file.arrayBuffer())

    const base = origin(request)
    return { success: true, url: `${base}/admin/uploads/${filename}` }
  })
