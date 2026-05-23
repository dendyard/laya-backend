import { Elysia } from 'elysia'
import { query, queryOne, run } from '../db'
import { requireAdmin } from '../auth'

function fmt(u: any) {
  const { password, api_token, ...safe } = u
  return safe
}

export const usersRouter = new Elysia({ prefix: '/api/users' })

  // List all users
  .get('/', async ({ headers }: any) => {
    await requireAdmin(headers)
    const rows = await query<any>(
      'SELECT * FROM users ORDER BY created_at DESC'
    )
    return { success: true, data: rows.map(fmt) }
  })

  // Get single user
  .get('/:id', async ({ params, headers, set }: any) => {
    await requireAdmin(headers)
    const row = await queryOne<any>('SELECT * FROM users WHERE id = ? LIMIT 1', [params.id])
    if (!row) { set.status = 404; return { success: false, message: 'User not found' } }
    return { success: true, data: fmt(row) }
  })

  // Create user
  .post('/', async ({ body, headers, set }: any) => {
    await requireAdmin(headers)
    const { name, email, password, role = 'user', is_premium = 0, premium_until = null } = body ?? {}
    if (!name || !email || !password) {
      set.status = 422; return { success: false, message: 'name, email, password required' }
    }
    const existing = await queryOne<any>('SELECT id FROM users WHERE email = ?', [email])
    if (existing) { set.status = 409; return { success: false, message: 'Email already in use' } }

    const hashed = await Bun.password.hash(password, { algorithm: 'bcrypt', cost: 10 })
    const r = await run(
      'INSERT INTO users (name,email,password,role,is_premium,premium_until) VALUES (?,?,?,?,?,?)',
      [name, email, hashed, role, is_premium, premium_until]
    )
    const user = await queryOne<any>('SELECT * FROM users WHERE id = ?', [r.insertId])
    set.status = 201
    return { success: true, data: fmt(user!) }
  })

  // Update user (name, email, role, is_premium, premium_until)
  .put('/:id', async ({ params, body, headers, set }: any) => {
    await requireAdmin(headers)
    const allowed = ['name', 'email', 'role', 'is_premium', 'premium_until']
    const fields: string[] = []
    const values: unknown[] = []
    for (const k of allowed) {
      if (k in body) { fields.push(`${k} = ?`); values.push((body as any)[k]) }
    }
    if (!fields.length) { set.status = 422; return { success: false, message: 'Nothing to update' } }

    // Check email uniqueness if being changed
    if ('email' in body) {
      const existing = await queryOne<any>('SELECT id FROM users WHERE email = ? AND id != ?', [body.email, params.id])
      if (existing) { set.status = 409; return { success: false, message: 'Email already in use' } }
    }

    values.push(params.id)
    await run(`UPDATE users SET ${fields.join(',')} WHERE id = ?`, values)
    const user = await queryOne<any>('SELECT * FROM users WHERE id = ?', [params.id])
    if (!user) { set.status = 404; return { success: false, message: 'User not found' } }
    return { success: true, data: fmt(user) }
  })

  // Change password
  .put('/:id/password', async ({ params, body, headers, set }: any) => {
    await requireAdmin(headers)
    const { password } = body ?? {}
    if (!password || String(password).length < 6) {
      set.status = 422; return { success: false, message: 'Password minimal 6 karakter' }
    }
    const hashed = await Bun.password.hash(password, { algorithm: 'bcrypt', cost: 10 })
    const r = await run('UPDATE users SET password = ? WHERE id = ?', [hashed, params.id])
    if (!r.affectedRows) { set.status = 404; return { success: false, message: 'User not found' } }
    return { success: true, message: 'Password updated' }
  })

  // Delete user
  .delete('/:id', async ({ params, headers, set }: any) => {
    await requireAdmin(headers)
    const r = await run('DELETE FROM users WHERE id = ?', [params.id])
    if (!r.affectedRows) { set.status = 404; return { success: false, message: 'User not found' } }
    return { success: true, message: 'User deleted' }
  })
