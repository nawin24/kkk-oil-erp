import { createContext, useContext, useState } from 'react'
import { USERS, ROLES } from '../data/seed.js'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('kkk_user')
    return saved ? JSON.parse(saved) : null
  })

  const login = (roleKey) => {
    const u = USERS.find((x) => x.role === roleKey) || USERS[0]
    const session = { ...u, roleLabel: ROLES[u.role].label, access: ROLES[u.role].access }
    localStorage.setItem('kkk_user', JSON.stringify(session))
    setUser(session)
    return session
  }

  const logout = () => {
    localStorage.removeItem('kkk_user')
    setUser(null)
  }

  const can = (module) => {
    if (!user) return false
    return user.access === '*' || user.access.includes(module)
  }

  return (
    <AuthContext.Provider value={{ user, login, logout, can }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
