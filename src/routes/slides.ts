import { Elysia } from 'elysia'
import { query, queryOne, run } from '../db'
import { requireAdmin } from '../auth'

function fmt(row: any) {
  return row ? { id: row.id, number: row.number, videoId: row.video_id, content: row.content ?? '' } : null
}

export const slidesRouter = new Elysia({ prefix: '/api/slides' })

  .get('/', async () => {
    const rows = await query<any>(
      `SELECT s.id, s.episode_id, s.number, s.video_id, s.content,
              e.title AS episode_title, e.number AS episode_number, e.series_id,
              sr.title AS series_title, sr.slug AS series_slug
       FROM slides s
       JOIN episodes e ON e.id = s.episode_id
       JOIN series sr ON sr.id = e.series_id
       ORDER BY sr.sort_order ASC, sr.id ASC, e.number ASC, s.number ASC`
    )
    return {
      success: true,
      data: rows.map(r => ({
        id: r.id, episode_id: r.episode_id, number: r.number,
        videoId: r.video_id, content: r.content ?? '',
        episode_title: r.episode_title, episode_number: r.episode_number,
        series_id: r.series_id, series_title: r.series_title, series_slug: r.series_slug,
      })),
    }
  })

  .get('/:id', async ({ params, set }) => {
    const row = await queryOne<any>('SELECT * FROM slides WHERE id = ? LIMIT 1', [params.id])
    if (!row) { set.status = 404; return { success: false, message: 'Slide not found' } }
    return { success: true, data: fmt(row) }
  })

  .put('/:id', async ({ params, body, headers, set }: any) => {
    await requireAdmin(headers)
    const allowed = ['number', 'video_id', 'content']
    const fields: string[] = []
    const values: unknown[] = []
    for (const k of allowed) {
      if (k in body) { fields.push(`${k} = ?`); values.push((body as any)[k]) }
    }
    if (!fields.length) { set.status = 422; return { success: false, message: 'Nothing to update' } }
    values.push(params.id)
    await run(`UPDATE slides SET ${fields.join(',')} WHERE id = ?`, values)
    const row = await queryOne<any>('SELECT * FROM slides WHERE id = ?', [params.id])
    return { success: true, data: fmt(row) }
  })

  .delete('/:id', async ({ params, headers, set }: any) => {
    await requireAdmin(headers)
    const r = await run('DELETE FROM slides WHERE id = ?', [params.id])
    if (!r.affectedRows) { set.status = 404; return { success: false, message: 'Slide not found' } }
    return { success: true, message: 'Slide deleted' }
  })
