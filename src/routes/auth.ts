import { Elysia } from 'elysia'
import { query, queryOne, run } from '../db'
import { extractToken, requireAuth } from '../auth'

export const authRouter = new Elysia({ prefix: '/api/auth' })

  .post('/login', async ({ body, set }: any) => {
    const { email, password } = body ?? {}
    if (!email || !password) {
      set.status = 422
      return { success: false, message: 'Email and password required' }
    }
    const user = await queryOne<any>('SELECT * FROM users WHERE email = ? LIMIT 1', [email])
    if (!user) {
      set.status = 401
      return { success: false, message: 'Invalid credentials' }
    }
    const valid = await Bun.password.verify(password, user.password)
    if (!valid) {
      set.status = 401
      return { success: false, message: 'Invalid credentials' }
    }
    const token = Buffer.from(crypto.getRandomValues(new Uint8Array(32))).toString('hex')
    await run('UPDATE users SET api_token = ? WHERE id = ?', [token, user.id])
    return {
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: { id: user.id, name: user.name, email: user.email, role: user.role, is_premium: !!user.is_premium },
      },
    }
  })

  .post('/logout', async ({ headers, set }: any) => {
    const user = await requireAuth(headers)
    await run('UPDATE users SET api_token = NULL WHERE id = ?', [user.id])
    return { success: true, message: 'Logged out' }
  })

  .get('/session', async ({ headers }: any) => {
    const token = extractToken(headers)
    if (!token) return { success: true, data: { authenticated: false, user: null } }
    const user = await queryOne<any>(
      'SELECT id, name, email, role, is_premium, premium_until FROM users WHERE api_token = ? LIMIT 1',
      [token]
    )
    if (!user) return { success: true, data: { authenticated: false, user: null } }
    return {
      success: true,
      data: {
        authenticated: true,
        user: { id: user.id, name: user.name, email: user.email, role: user.role, is_premium: !!user.is_premium, premium_until: user.premium_until },
      },
    }
  })
