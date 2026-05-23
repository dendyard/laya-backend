import { query } from './db'

export interface AuthUser {
  id: number
  name: string
  email: string
  role: 'admin' | 'editor' | 'user'
  is_premium: number
}

export function extractToken(headers: Record<string, string | undefined>): string | null {
  const auth = headers['authorization'] ?? ''
  const match = auth.match(/^Bearer\s+(.+)$/i)
  return match?.[1] ?? null
}

export async function getUserFromToken(token: string): Promise<AuthUser | null> {
  const rows = await query<AuthUser>(
    'SELECT id, name, email, role, is_premium FROM users WHERE api_token = ? LIMIT 1',
    [token]
  )
  return rows[0] ?? null
}

export async function requireAuth(headers: Record<string, string | undefined>): Promise<AuthUser> {
  const token = extractToken(headers)
  if (!token) throw { status: 401, message: 'Unauthorized' }
  const user = await getUserFromToken(token)
  if (!user) throw { status: 401, message: 'Invalid token' }
  return user
}

export async function requireAdmin(headers: Record<string, string | undefined>): Promise<AuthUser> {
  const user = await requireAuth(headers)
  if (!['admin', 'editor'].includes(user.role)) throw { status: 403, message: 'Forbidden' }
  return user
}
