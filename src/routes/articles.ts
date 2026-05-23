import { Elysia } from 'elysia'
import { query, queryOne, run } from '../db'
import { requireAdmin } from '../auth'

export const articlesRouter = new Elysia({ prefix: '/api/articles' })

  .get('/', async () => {
    const rows = await query(
      `SELECT a.*, c.name AS category_name, c.slug AS category_slug
       FROM articles a
       LEFT JOIN categories c ON c.id = a.category_id
       ORDER BY a.sort_order ASC, a.created_at DESC`
    )
    return { success: true, data: rows }
  })

  .post('/', async ({ body, headers, set }: any) => {
    await requireAdmin(headers)
    const { slug, title, subtitle, description, hero_image, card_image, category_id, is_published = 0, sort_order = 0 } = body ?? {}
    if (!slug || !title) { set.status = 422; return { success: false, message: 'slug and title required' } }
    const r = await run(
      'INSERT INTO articles (slug,title,subtitle,description,hero_image,card_image,category_id,is_published,sort_order) VALUES (?,?,?,?,?,?,?,?,?)',
      [slug, title, subtitle ?? null, description ?? null, hero_image ?? null, card_image ?? null, category_id ?? null, is_published, sort_order]
    )
    const article = await queryOne(
      'SELECT a.*, c.name AS category_name, c.slug AS category_slug FROM articles a LEFT JOIN categories c ON c.id = a.category_id WHERE a.id = ?',
      [r.insertId]
    )
    set.status = 201
    return { success: true, data: article }
  })

  .get('/:id', async ({ params, set }) => {
    const field = /^\d+$/.test(params.id) ? 'a.id' : 'a.slug'
    const row = await queryOne(
      `SELECT a.*, c.name AS category_name, c.slug AS category_slug
       FROM articles a LEFT JOIN categories c ON c.id = a.category_id
       WHERE ${field} = ? LIMIT 1`,
      [params.id]
    )
    if (!row) { set.status = 404; return { success: false, message: 'Article not found' } }
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
    await run(`UPDATE articles SET ${fields.join(',')} WHERE id = ?`, values)
    const article = await queryOne(
      'SELECT a.*, c.name AS category_name, c.slug AS category_slug FROM articles a LEFT JOIN categories c ON c.id = a.category_id WHERE a.id = ?',
      [params.id]
    )
    return { success: true, data: article }
  })

  .delete('/:id', async ({ params, headers, set }: any) => {
    await requireAdmin(headers)
    const r = await run('DELETE FROM articles WHERE id = ?', [params.id])
    if (!r.affectedRows) { set.status = 404; return { success: false, message: 'Article not found' } }
    return { success: true, message: 'Article deleted' }
  })

  .get('/:id/episodes', async ({ params }) => {
    const field = /^\d+$/.test(params.id) ? 'a.id' : 'a.slug'
    const article = await queryOne<any>(`SELECT id FROM articles a WHERE ${field} = ?`, [params.id])
    if (!article) return { success: true, data: [] }
    const rows = await query('SELECT * FROM episodes WHERE article_id = ? ORDER BY number ASC', [article.id])
    return { success: true, data: rows }
  })

  .post('/:id/episodes', async ({ params, body, headers, set }: any) => {
    await requireAdmin(headers)
    const { title, number = 1, publish_date, is_published = 0, is_locked = 1 } = body ?? {}
    if (!title) { set.status = 422; return { success: false, message: 'title required' } }
    const r = await run(
      'INSERT INTO episodes (article_id,number,title,publish_date,is_published,is_locked) VALUES (?,?,?,?,?,?)',
      [params.id, number, title, publish_date ?? null, is_published, is_locked]
    )
    const ep = await queryOne('SELECT * FROM episodes WHERE id = ?', [r.insertId])
    set.status = 201
    return { success: true, data: ep }
  })
