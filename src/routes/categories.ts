import { Elysia } from 'elysia'
import { query, queryOne, run } from '../db'
import { requireAdmin } from '../auth'

export const categoriesRouter = new Elysia({ prefix: '/api/categories' })

  .get('/', async () => {
    const rows = await query('SELECT * FROM categories ORDER BY name ASC')
    return { success: true, data: rows }
  })

  .get('/:id', async ({ params, set }) => {
    const field = /^\d+$/.test(params.id) ? 'id' : 'slug'
    const row = await queryOne(`SELECT * FROM categories WHERE ${field} = ? LIMIT 1`, [params.id])
    if (!row) { set.status = 404; return { success: false, message: 'Category not found' } }
    return { success: true, data: row }
  })

  .post('/', async ({ body, headers, set }: any) => {
    await requireAdmin(headers)
    const { name, slug } = body ?? {}
    if (!name || !slug) { set.status = 422; return { success: false, message: 'name and slug required' } }
    const r = await run('INSERT INTO categories (name, slug) VALUES (?,?)', [name, slug])
    const cat = await queryOne('SELECT * FROM categories WHERE id = ?', [r.insertId])
    set.status = 201
    return { success: true, data: cat }
  })

  .put('/:id', async ({ params, body, headers, set }: any) => {
    await requireAdmin(headers)
    const fields: string[] = []
    const values: unknown[] = []
    for (const k of ['name','slug']) {
      if (k in body) { fields.push(`${k} = ?`); values.push((body as any)[k]) }
    }
    if (!fields.length) { set.status = 422; return { success: false, message: 'Nothing to update' } }
    values.push(params.id)
    await run(`UPDATE categories SET ${fields.join(',')} WHERE id = ?`, values)
    const cat = await queryOne('SELECT * FROM categories WHERE id = ?', [params.id])
    return { success: true, data: cat }
  })

  .delete('/:id', async ({ params, headers, set }: any) => {
    await requireAdmin(headers)
    const r = await run('DELETE FROM categories WHERE id = ?', [params.id])
    if (!r.affectedRows) { set.status = 404; return { success: false, message: 'Category not found' } }
    return { success: true, message: 'Category deleted' }
  })
