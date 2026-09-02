import { useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { useData } from '../context/DataContext'
import Icon from '../components/Icon'

export default function Login() {
  const { login, ready } = useAuth()
  const { company } = useData()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  const submit = async (e: any) => {
    e?.preventDefault()
    setError('')
    setBusy(true)
    const res = await login(username, password)
    setBusy(false)
    if (!res.ok) setError(res.error || 'Login failed.')
  }

  const quickLogin = async (u: string, p: string) => {
    setUsername(u)
    setPassword(p)
    setError('')
    setBusy(true)
    const res = await login(u, p)
    setBusy(false)
    if (!res.ok) setError(res.error || 'Login failed.')
  }

  const initials = (company?.name || 'KKK Oil Factory').split(' ').map((w: string) => w[0]).slice(0, 3).join('').toUpperCase()

  return (
    <div className="login-wrap">
      <div className="login-art">
        <div className="sb-brand" style={{ border: 'none', padding: 0 }}>
          <div className="sb-logo" style={{ width: 46, height: 46, fontSize: 16 }}>{initials}</div>
          <div>
            <h1 style={{ color: '#fff', fontSize: 17 }}>{company?.name || 'KKK Oil Factory'}</h1>
            <span style={{ color: '#8fa298' }}>{company?.state || 'Tamil Nadu'} · Billing &amp; ERP System</span>
          </div>
        </div>
        <div>
          <h2>Run your entire ERP business from one professional platform.</h2>
          <p>AWR pricing model (Agency, Wholesale, Retail), effective date pricing, role-based navigation, and official billing vouchers.</p>
        </div>
        <div style={{ display: 'flex', gap: 26, position: 'relative', zIndex: 1 }}>
          {[['AWR', '3 Pricing Rates'], ['ERP', 'Voucher Billing'], ['4', 'Primary Roles']].map(([n, l]) => (
            <div key={l}>
              <div style={{ fontSize: 20, fontWeight: 800, color: '#e3a92e' }}>{n}</div>
              <div style={{ fontSize: 12, color: '#a9bcb1' }}>{l}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="login-form-side">
        <form className="login-card" onSubmit={submit}>
          <h3>Sign in 👋</h3>
          <p className="lead">Enter your staff credentials or select a role account below.</p>

          <div className="field">
            <label>Username</label>
            <input autoFocus autoCapitalize="none" autoComplete="username" value={username} onChange={(e) => setUsername(e.target.value)} placeholder="e.g. admin" />
          </div>
          <div className="field">
            <label>Password</label>
            <input type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" />
          </div>

          {error && (
            <div style={{ background: 'var(--red-soft)', color: 'var(--red)', fontSize: 13, fontWeight: 600, padding: '9px 12px', borderRadius: 8, marginBottom: 12 }}>
              {error}
            </div>
          )}

          <button type="submit" disabled={busy || !ready} className="btn btn-gold" style={{ width: '100%', justifyContent: 'center', padding: 12, marginTop: 2 }}>
            <Icon name="logout" size={16} /> {busy ? 'Signing in…' : 'Sign in'}
          </button>

          {/* Quick Role Tester Shortcuts */}
          <div style={{ marginTop: 20, paddingTop: 16, borderTop: '1px solid var(--border)' }}>
            <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--text-3)', marginBottom: 8, textAlign: 'center' }}>
              Quick Role Test Logins
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
              <button type="button" className="btn btn-sm btn-gold" onClick={() => quickLogin('admin', 'admin123')} style={{ fontSize: 11, justifyContent: 'center' }}>
                👑 Super Admin
              </button>
              <button type="button" className="btn btn-sm" onClick={() => quickLogin('admin_staff', 'admin123')} style={{ fontSize: 11, justifyContent: 'center' }}>
                🛡️ Admin
              </button>
              <button type="button" className="btn btn-sm" onClick={() => quickLogin('mgr', 'mgr123')} style={{ fontSize: 11, justifyContent: 'center' }}>
                📊 Manager
              </button>
              <button type="button" className="btn btn-sm" onClick={() => quickLogin('cashier', 'cashier123')} style={{ fontSize: 11, justifyContent: 'center' }}>
                💳 Cashier ERP Billing
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  )
}

