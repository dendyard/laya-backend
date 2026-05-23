import { Elysia } from 'elysia'
import { query, queryOne, run } from '../db'
import { requireAdmin } from '../auth'

function fmtEpisode(ep: any, base: string) {
  if (!ep) return ep
  const abs = (v: string | null) => v?.startsWith('/') ? `${base}${v}` : (v ?? null)
  return { ...ep, musik_bg: abs(ep.musik_bg), card_image: abs(ep.card_image) }
}

export const episodesRouter = new Elysia({ prefix: '/api/episodes' })

  .get('/', async ({ request }: any) => {
    const rows = await query<any>(
      `SELECT e.*, s.title AS series_title, s.slug AS series_slug
       FROM episodes e
       JOIN series s ON s.id = e.series_id
       ORDER BY s.sort_order ASC, s.id ASC, e.number ASC`
    )
    const base = new URL(request.url).origin
    return { success: true, data: rows.map((r: any) => fmtEpisode(r, base)) }
  })

  // Latest published episode per series (public feed)
  .get('/latest', async ({ query: qs, request }: any) => {
    const limit = Math.min(Math.max(parseInt(qs?.limit) || 10, 1), 50)
    const base  = new URL(request.url).origin

    // DISTINCT ON: ambil episode dengan number tertinggi dari tiap series yang published
    const rows = await query<any>(
      `SELECT DISTINCT ON (e.series_id)
          e.id, e.series_id, e.number, e.title, e.publish_date,
          e.is_locked, e.musik_bg, e.card_image, e.created_at,
          s.title  AS series_title,
          s.slug   AS series_slug,
          s.subtitle AS series_subtitle,
          s.hero_image, s.card_image
       FROM episodes e
       JOIN series s ON s.id = e.series_id
       WHERE e.is_published = 1
         AND s.is_published = 1
       ORDER BY e.series_id, e.number DESC
       LIMIT ?`,
      [limit]
    )

    return {
      success: true,
      data: rows.map((r: any) => ({
        id:               r.id,
        number:           r.number,
        title:            r.title,
        publish_date:     r.publish_date,
        is_locked:        r.is_locked,
        musik_bg:         r.musik_bg?.startsWith('/') ? `${base}${r.musik_bg}` : (r.musik_bg ?? null),
        card_image:       r.card_image?.startsWith('/') ? `${base}${r.card_image}` : (r.card_image ?? null),
        created_at:       r.created_at,
        series: {
          id:         r.series_id,
          title:      r.series_title,
          slug:       r.series_slug,
          subtitle:   r.series_subtitle,
          hero_image: r.hero_image?.startsWith('/') ? `${base}${r.hero_image}` : (r.hero_image ?? null),
          card_image: r.card_image?.startsWith('/') ? `${base}${r.card_image}` : (r.card_image ?? null),
        },
      })),
    }
  })

  .get('/:id', async ({ params, request, set }: any) => {
    const row = await queryOne<any>('SELECT * FROM episodes WHERE id = ? LIMIT 1', [params.id])
    if (!row) { set.status = 404; return { success: false, message: 'Episode not found' } }
    return { success: true, data: fmtEpisode(row, new URL(request.url).origin) }
  })

  .put('/:id', async ({ params, body, headers, request, set }: any) => {
    await requireAdmin(headers)
    const allowed = ['number','title','publish_date','is_published','is_locked','musik_bg','card_image']
    const fields: string[] = []
    const values: unknown[] = []
    for (const k of allowed) {
      if (k in body) { fields.push(`${k} = ?`); values.push((body as any)[k]) }
    }
    if (!fields.length) { set.status = 422; return { success: false, message: 'Nothing to update' } }
    values.push(params.id)
    await run(`UPDATE episodes SET ${fields.join(',')} WHERE id = ?`, values)
    const ep = await queryOne<any>('SELECT * FROM episodes WHERE id = ?', [params.id])
    return { success: true, data: fmtEpisode(ep, new URL(request.url).origin) }
  })

  .delete('/:id', async ({ params, headers, set }: any) => {
    await requireAdmin(headers)
    const r = await run('DELETE FROM episodes WHERE id = ?', [params.id])
    if (!r.affectedRows) { set.status = 404; return { success: false, message: 'Episode not found' } }
    return { success: true, message: 'Episode deleted' }
  })

  .get('/:id/slides', async ({ params }) => {
    const slides = await query<any>('SELECT * FROM slides WHERE episode_id = ? ORDER BY number ASC', [params.id])
    return {
      success: true,
      data: slides.map((s: any) => ({
        id: s.id, number: s.number, videoId: s.video_id, content: s.content ?? '',
      })),
    }
  })

  .post('/:id/slides', async ({ params, body, headers, set }: any) => {
    await requireAdmin(headers)
    const { number = 1, video_id, content = '' } = body ?? {}
    const r = await run(
      'INSERT INTO slides (episode_id,number,video_id,content) VALUES (?,?,?,?)',
      [params.id, number, video_id ?? null, content]
    )
    const slide = await queryOne<any>('SELECT * FROM slides WHERE id = ?', [r.insertId])
    set.status = 201
    return { success: true, data: { id: slide!.id, number: slide!.number, videoId: slide!.video_id, content: slide!.content ?? '' } }
  })
