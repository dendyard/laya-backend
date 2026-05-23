import { Elysia } from 'elysia'
import { query, queryOne, run } from '../db'
import { requireAdmin } from '../auth'

export const seriesRouter = new Elysia({ prefix: '/api/series' })

  .get('/', async () => {
    const rows = await query(
      `SELECT s.*, c.name AS category_name, c.slug AS category_slug
       FROM series s
       LEFT JOIN categories c ON c.id = s.category_id
       ORDER BY s.sort_order ASC, s.created_at DESC`
    )
    return { success: true, data: rows }
  })

  .post('/', async ({ body, headers, set }: any) => {
    await requireAdmin(headers)
    const { slug, title, subtitle, description, hero_image, card_image, category_id, is_published = 0, sort_order = 0 } = body ?? {}
    if (!slug || !title) { set.status = 422; return { success: false, message: 'slug and title required' } }
    const r = await run(
      'INSERT INTO series (slug,title,subtitle,description,hero_image,card_image,category_id,is_published,sort_order) VALUES (?,?,?,?,?,?,?,?,?)',
      [slug, title, subtitle ?? null, description ?? null, hero_image ?? null, card_image ?? null, category_id ?? null, is_published, sort_order]
    )
    const series = await queryOne(
      'SELECT s.*, c.name AS category_name, c.slug AS category_slug FROM series s LEFT JOIN categories c ON c.id = s.category_id WHERE s.id = ?',
      [r.insertId]
    )
    set.status = 201
    return { success: true, data: series }
  })

  .get('/:id', async ({ params, set }) => {
    const field = /^\d+$/.test(params.id) ? 's.id' : 's.slug'
    const row = await queryOne(
      `SELECT s.*, c.name AS category_name, c.slug AS category_slug
       FROM series s LEFT JOIN categories c ON c.id = s.category_id
       WHERE ${field} = ? LIMIT 1`,
      [params.id]
    )
    if (!row) { set.status = 404; return { success: false, message: 'Series not found' } }
    return { success: true, data: row }
  })

  .put('/:id', async ({ params, body, headers, set }: any) => {
    await requireAdmin(headers)
    const allowed = ['slug','title','subtitle','description','hero_image','card_image','category_id','is_published','sort_order']
    const fields: string[] = []
    const values: unknown[] = []
    for (const k of allowed) {
      if (k in body) { fields.push(`${k} = ?`); values.push((body as any)[k]) }
    }
    if (!fields.length) { set.status = 422; return { success: false, message: 'Nothing to update' } }
    values.push(params.id)
    await run(`UPDATE series SET ${fields.join(',')} WHERE id = ?`, values)
    const series = await queryOne(
      'SELECT s.*, c.name AS category_name, c.slug AS category_slug FROM series s LEFT JOIN categories c ON c.id = s.category_id WHERE s.id = ?',
      [params.id]
    )
    return { success: true, data: series }
  })

  .delete('/:id', async ({ params, headers, set }: any) => {
    await requireAdmin(headers)
    const r = await run('DELETE FROM series WHERE id = ?', [params.id])
    if (!r.affectedRows) { set.status = 404; return { success: false, message: 'Series not found' } }
    return { success: true, message: 'Series deleted' }
  })

  .get('/:id/episodes', async ({ params }) => {
    const field = /^\d+$/.test(params.id) ? 's.id' : 's.slug'
    const series = await queryOne<any>(`SELECT id FROM series s WHERE ${field} = ?`, [params.id])
    if (!series) return { success: true, data: [] }
    const rows = await query('SELECT * FROM episodes WHERE series_id = ? ORDER BY number ASC', [series.id])
    return { success: true, data: rows }
  })

  .post('/:id/episodes', async ({ params, body, headers, set }: any) => {
    await requireAdmin(headers)
    const { title, number = 1, publish_date, is_published = 0, is_locked = 1 } = body ?? {}
    if (!title) { set.status = 422; return { success: false, message: 'title required' } }
    const r = await run(
      'INSERT INTO episodes (series_id,number,title,publish_date,is_published,is_locked) VALUES (?,?,?,?,?,?)',
      [params.id, number, title, publish_date ?? null, is_published, is_locked]
    )
    const ep = await queryOne('SELECT * FROM episodes WHERE id = ?', [r.insertId])
    set.status = 201
    return { success: true, data: ep }
  })
