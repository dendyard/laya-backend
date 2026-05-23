import postgres from 'postgres'

export const pg = postgres({
  host:     '127.0.0.1',
  port:     5432,
  database: 'laya_db',
  username: 'dendyardanygmail.com',
  password: '',
  max:      10,
})

/** Convert MySQL-style ? placeholders to PostgreSQL $1,$2,... */
function toPositional(sql: string, params: unknown[]): [string, unknown[]] {
  let i = 0
  return [sql.replace(/\?/g, () => `$${++i}`), params]
}

export async function query<T = Record<string, unknown>>(sql: string, params: unknown[] = []): Promise<T[]> {
  const [pSql, pParams] = toPositional(sql, params)
  return pg.unsafe(pSql, pParams as any[]) as unknown as T[]
}

export async function queryOne<T = Record<string, unknown>>(sql: string, params: unknown[] = []): Promise<T | null> {
  const rows = await query<T>(sql, params)
  return rows[0] ?? null
}

export async function run(sql: string, params: unknown[] = []) {
  const isInsert = /^\s*INSERT/i.test(sql)
  const finalSql = isInsert && !/RETURNING/i.test(sql) ? sql + ' RETURNING id' : sql
  const [pSql, pParams] = toPositional(finalSql, params)
  const result = await pg.unsafe(pSql, pParams as any[])
  return {
    insertId:     isInsert ? (Number((result[0] as any)?.id) || null) : null,
    affectedRows: Number(result.count),
  }
}
