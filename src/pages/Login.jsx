import { useState } from 'react'
import { useAuth } from '../context/AuthContext.jsx'
import { ROLES } from '../data/seed.js'
import Icon from '../components/Icon.jsx'

const ROLE_LIST = Object.entries(ROLES).map(([key, v]) => ({ key, ...v }))

export default function Login() {
  const { login } = useAuth()
  const [role, setRole] = useState('admin')

  const submit = (e) => {
    e.preventDefault()
    login(role)
  }

  return (
    <div className="login-wrap">
      <div className="login-art">
        <div className="sb-brand" style={{ border: 'none', padding: 0 }}>
          <div className="sb-logo" style={{ width: 46, height: 46, fontSize: 18 }}>KKK</div>
          <div>
            <h1 style={{ color: '#fff', fontSize: 17 }}>KKK Oil Factory</h1>
            <span style={{ color: '#8fa298' }}>Dharmapuri · Tamil Nadu</span>
          </div>
        </div>
        <div>
          <h2>Run your entire oil factory from one clean dashboard.</h2>
          <p>Purchase, production, inventory, sales, billing, logistics and reports — for KKK Gold and every brand you handle. நம் தொழிற்சாலை, ஒரே இடத்தில்.</p>
        </div>
        <div style={{ display: 'flex', gap: 26, position: 'relative', zIndex: 1 }}>
          {[['20+', 'Products'], ['4', 'Brands'], ['10', 'Dealers'], ['₹10L+', 'Monthly sales']].map(([n, l]) => (
            <div key={l}>
              <div style={{ fontSize: 24, fontWeight: 800, color: '#e3a92e' }}>{n}</div>
              <div style={{ fontSize: 12, color: '#a9bcb1' }}>{l}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="login-form-side">
        <form className="login-card" onSubmit={submit}>
          <h3>Welcome back 👋</h3>
          <p className="lead">Sign in to the KKK ERP. Pick a role to preview its access.</p>

          <div className="field">
            <label>Email</label>
            <input type="email" defaultValue="owner@kkkoil.in" />
          </div>
          <div className="field">
            <label>Password</label>
            <input type="password" defaultValue="demo1234" />
          </div>

          <label style={{ fontSize: 12.5, fontWeight: 600, display: 'block', marginBottom: 8 }}>Login as</label>
          <div className="role-pick">
            {ROLE_LIST.map((r) => (
              <button type="button" key={r.key} className={`role-opt ${role === r.key ? 'active' : ''}`} onClick={() => setRole(r.key)}>
                {r.label}
                <small>{r.access === '*' ? 'Full access' : `${r.access.length} modules`}</small>
              </button>
            ))}
          </div>

          <button type="submit" className="btn btn-gold" style={{ width: '100%', justifyContent: 'center', padding: 12, marginTop: 6 }}>
            <Icon name="logout" size={16} /> Sign in to dashboard
          </button>
          <p className="tiny" style={{ textAlign: 'center', marginTop: 14 }}>Demo build · role-based access · data stored locally</p>
        </form>
      </div>
    </div>
  )
}
