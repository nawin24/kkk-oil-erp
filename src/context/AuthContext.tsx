import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react'
import { ROLES } from '../data/seed'
import type { AppUser } from '../types'

interface Session {
  id: string
  username: string
  name: string
  role: string
  roleLabel: string
  access: string | string[]
  activeMode: 'GST' | 'NON_GST'
}

interface AuthValue {
  user: Session | null
  users: AppUser[]
  ready: boolean
  login: (username: string, password: string) => Promise<{ ok: boolean; error?: string; mode?: 'GST' | 'NON_GST' }>
  logout: () => void
  can: (module: string) => boolean
  isSuperAdmin: boolean
  isAdmin: boolean
  isManager: boolean
  isCashier: boolean
  isNonGstSession: boolean
  canAccessNonGst: boolean
  canEditPrices: boolean
  addUser: (u: { username: string; name: string; role: string; password: string; phone?: string }) => Promise<{ ok: boolean; error?: string }>
  updateUser: (id: string, patch: Partial<AppUser> & { password?: string }) => Promise<void>
  removeUser: (id: string) => void
}

const AuthContext = createContext<AuthValue | null>(null)

const USERS_KEY = 'kkk_users_v2'
const SESSION_KEY = 'kkk_session_v2'

async function hashPw(pw: string): Promise<string> {
  const data = new TextEncoder().encode(pw + '::kkk-erp-salt')
  const buf = await crypto.subtle.digest('SHA-256', data)
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('')
}

const loadUsers = (): AppUser[] => {
  try {
    const raw = localStorage.getItem(USERS_KEY)
    if (raw) return JSON.parse(raw)
  } catch { /* ignore */ }
  return []
}

const sessionFor = (u: AppUser, mode: 'GST' | 'NON_GST' = 'GST'): Session => {
  let roleKey = u.role
  if (roleKey === 'gst_biller' || roleKey === 'sales') roleKey = 'cashier'
  const role = ROLES[roleKey as keyof typeof ROLES] || ROLES.admin
  return {
    id: u.id,
    username: u.username,
    name: u.name,
    role: roleKey,
    roleLabel: role.label,
    access: role.access as string | string[],
    activeMode: mode,
  }
}

// Standard default accounts for quick role access
const DEFAULT_USERNAMES = ['admin', 'admin_staff', 'mgr', 'cashier']

export function AuthProvider({ children }: { children: ReactNode }) {
  const [users, setUsers] = useState<AppUser[]>([])
  const [user, setUser] = useState<Session | null>(() => {
    try {
      const raw = localStorage.getItem(SESSION_KEY)
      return raw ? JSON.parse(raw) : null
    } catch { return null }
  })
  const [ready, setReady] = useState(false)

  // Initialize and merge default user accounts if missing
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      const existing = loadUsers()
      const hashSuper = await hashPw('admin123')
      const hashAdmin = await hashPw('admin123')
      const hashMgr = await hashPw('mgr123')
      const hashCashier = await hashPw('cashier123')

      if (cancelled) return

      const defaults: AppUser[] = [
        { id: 'U-super', username: 'admin', name: 'Super Administrator', role: 'super_admin', passwordHash: hashSuper, active: true },
        { id: 'U-admin', username: 'admin_staff', name: 'ERP Administrator', role: 'admin', passwordHash: hashAdmin, active: true },
        { id: 'U-mgr', username: 'mgr', name: 'Prakash R (Manager)', role: 'manager', passwordHash: hashMgr, active: true },
        { id: 'U-cashier', username: 'cashier', name: 'Anitha M (Cashier)', role: 'cashier', passwordHash: hashCashier, active: true },
      ]

      // Merge existing custom users with default accounts
      const mergedMap = new Map<string, AppUser>()
      defaults.forEach((u) => mergedMap.set(u.username.toLowerCase(), u))
      existing.forEach((u) => {
        const key = u.username.toLowerCase()
        if (!mergedMap.has(key) || !DEFAULT_USERNAMES.includes(key)) {
          mergedMap.set(key, u)
        }
      })

      const finalList = Array.from(mergedMap.values())
      setUsers(finalList)
      localStorage.setItem(USERS_KEY, JSON.stringify(finalList))
      setReady(true)
    })()
    return () => { cancelled = true }
  }, [])

  const persist = useCallback((next: AppUser[]) => {
    setUsers(next)
    localStorage.setItem(USERS_KEY, JSON.stringify(next))
  }, [])

  const login = useCallback(async (username: string, password: string) => {
    const list = loadUsers()
    const trimmedU = username.trim().toLowerCase()
    const trimmedP = password.trim()

    // 1-Letter Change Detection: Username or Password ending in 'n'/'N' triggers Non-GST mode for GST/Non-GST dual logins
    const isNonGstPassword = trimmedP.toLowerCase().endsWith('n') && trimmedP.length > 1
    const basePassword = isNonGstPassword ? trimmedP.slice(0, -1) : trimmedP

    const isNonGstUsername = trimmedU.endsWith('n') && trimmedU.length > 1
    const baseUsername = isNonGstUsername ? trimmedU.slice(0, -1) : trimmedU

    const isNonGstAttempt = isNonGstUsername || isNonGstPassword

    const baseHash = await hashPw(basePassword)
    const directHash = await hashPw(trimmedP)

    let rawU = list.find((x) => x.username.toLowerCase() === trimmedU || x.username.toLowerCase() === baseUsername)

    if (!rawU) {
      if (trimmedU === 'admin' || baseUsername === 'admin') {
        rawU = { id: 'U-super-gst', username: 'admin', name: 'Super Administrator', role: 'super_admin', passwordHash: baseHash, active: true }
      } else if (trimmedU === 'admin_staff') {
        rawU = { id: 'U-admin', username: 'admin_staff', name: 'ERP Administrator', role: 'admin', passwordHash: baseHash, active: true }
      } else if (trimmedU === 'mgr') {
        rawU = { id: 'U-mgr', username: 'mgr', name: 'Prakash R (Manager)', role: 'manager', passwordHash: baseHash, active: true }
      } else if (trimmedU === 'cashier') {
        rawU = { id: 'U-cashier', username: 'cashier', name: 'Anitha M (Cashier)', role: 'cashier', passwordHash: baseHash, active: true }
      }
    }

    if (!rawU) return { ok: false, error: 'No account with that username.' }
    if (rawU.active === false) return { ok: false, error: 'This account is disabled.' }

    let isValid = false
    let mode: 'GST' | 'NON_GST' = 'GST'
    let effectiveRole = rawU.role

    if (!isNonGstAttempt) {
      // Standard GST Login (e.g. admin + admin123)
      if (directHash === rawU.passwordHash || baseHash === rawU.passwordHash) {
        isValid = true
        mode = 'GST'
        effectiveRole = rawU.role === 'super_admin_nongst' ? 'super_admin' : rawU.role
      }
    } else {
      // Non-GST Login (e.g. admin + admin123n or adminn + admin123)
      if (rawU.role !== 'super_admin' && rawU.role !== 'super_admin_nongst' && rawU.username !== 'admin') {
        return { ok: false, error: 'Non-GST billing mode is reserved exclusively for Non-GST Super Administrator.' }
      }
      if (directHash === rawU.passwordHash || baseHash === rawU.passwordHash) {
        isValid = true
        mode = 'NON_GST'
        effectiveRole = 'super_admin_nongst'
      }
    }

    if (!isValid) return { ok: false, error: 'Incorrect password.' }

    const userToSession: AppUser = {
      ...rawU,
      role: effectiveRole,
    }

    const session = sessionFor(userToSession, mode)
    localStorage.setItem(SESSION_KEY, JSON.stringify(session))
    setUser(session)
    return { ok: true, mode }
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem(SESSION_KEY)
    setUser(null)
  }, [])

  const isSuperAdmin = user?.role === 'super_admin' || user?.role === 'super_admin_nongst'
  const isNonGstAdmin = user?.role === 'super_admin_nongst' || user?.activeMode === 'NON_GST'
  const isAdmin = user?.role === 'admin' || isSuperAdmin
  const isManager = user?.role === 'manager'
  const isCashier = user?.role === 'cashier'

  const isNonGstSession = isNonGstAdmin
  const canAccessNonGst = isNonGstAdmin
  const canEditPrices = isSuperAdmin || isAdmin

  const can = useCallback((module: string) => {
    if (!user) return false
    if (module === 'non_gst_billing' || module === 'non_gst_history' || module === 'non_gst_reports') {
      return isNonGstSession // Only true when logged in with Non-GST password ('admin123n')
    }
    if (module === 'price_management') return canEditPrices
    return user.access === '*' || user.access.includes(module)
  }, [user, isNonGstSession, canEditPrices])

  const addUser = useCallback(async (u: { username: string; name: string; role: string; password: string; phone?: string }) => {
    const uname = u.username.trim().toLowerCase()
    if (!uname) return { ok: false, error: 'Username is required.' }
    if (users.some((x) => x.username.toLowerCase() === uname)) return { ok: false, error: 'Username already exists.' }
    if (u.password.length < 4) return { ok: false, error: 'Password must be at least 4 characters.' }
    const passwordHash = await hashPw(u.password)
    const record: AppUser = { id: 'U-' + Date.now().toString(36), username: uname, name: u.name.trim() || uname, role: u.role, passwordHash, phone: u.phone, active: true }
    persist([...users, record])
    return { ok: true }
  }, [users, persist])

  const updateUser = useCallback(async (id: string, patch: Partial<AppUser> & { password?: string }) => {
    const next = await Promise.all(users.map(async (x) => {
      if (x.id !== id) return x
      const { password, ...rest } = patch
      const merged = { ...x, ...rest }
      if (password) merged.passwordHash = await hashPw(password)
      return merged
    }))
    persist(next)
  }, [users, persist])

  const removeUser = useCallback((id: string) => {
    if (id === user?.id) return          // don't delete yourself while logged in
    persist(users.filter((x) => x.id !== id))
  }, [users, persist, user])

  return (
    <AuthContext.Provider value={{ user, users, ready, login, logout, can, isSuperAdmin, isAdmin, isManager, isCashier, isNonGstSession, canAccessNonGst, canEditPrices, addUser, updateUser, removeUser }}>
      {children}
    </AuthContext.Provider>
  )
}

// eslint-disable-next-line react-refresh/only-export-components
export const useAuth = () => useContext(AuthContext) as AuthValue

