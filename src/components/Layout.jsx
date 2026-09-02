import { useState } from 'react'
import { NavLink, useLocation } from 'react-router-dom'
import Icon from './Icon.jsx'
import { useAuth } from '../context/AuthContext.jsx'
import { useData } from '../context/DataContext.jsx'

const NAV = [
  { section: 'Main' },
  { to: '/', label: 'Dashboard', icon: 'dashboard', module: 'dashboard', end: true },
  { section: 'Catalog' },
  { to: '/brands', label: 'Brands', icon: 'brands', module: 'brands' },
  { to: '/products', label: 'Products', icon: 'products', module: 'products' },
  { section: 'Operations' },
  { to: '/purchase', label: 'Purchase', icon: 'purchase', module: 'purchase' },
  { to: '/inventory', label: 'Inventory', icon: 'inventory', module: 'inventory' },
  { to: '/production', label: 'Production', icon: 'production', module: 'production' },
  { to: '/sales', label: 'Sales', icon: 'sales', module: 'sales' },
  { to: '/logistics', label: 'Logistics', icon: 'logistics', module: 'logistics' },
  { section: 'Finance & People' },
  { to: '/billing', label: 'Billing', icon: 'billing', module: 'billing' },
  { to: '/customers', label: 'Customers', icon: 'customers', module: 'customers' },
  { to: '/suppliers', label: 'Suppliers', icon: 'suppliers', module: 'suppliers' },
  { section: 'Insights' },
  { to: '/reports', label: 'Reports', icon: 'reports', module: 'reports' },
  { to: '/settings', label: 'Settings', icon: 'settings', module: 'settings' },
]

const TITLES = {
  '/': 'Dashboard', '/brands': 'Brands', '/products': 'Products', '/purchase': 'Purchase',
  '/inventory': 'Inventory', '/production': 'Production', '/sales': 'Sales', '/logistics': 'Logistics',
  '/billing': 'Billing & Accounts', '/customers': 'Customers', '/suppliers': 'Suppliers',
  '/reports': 'Reports & Analytics', '/settings': 'Settings',
}

function Sidebar({ open, onClose }) {
  const { can } = useAuth()
  return (
    <>
      {open && <div className="sb-backdrop" onClick={onClose} />}
      <aside className={`sidebar ${open ? 'open' : ''}`}>
        <div className="sb-brand">
          <div className="sb-logo">KKK</div>
          <div>
            <h1>KKK Oil Factory</h1>
            <span>Dharmapuri · ERP</span>
          </div>
        </div>
        <nav className="sb-nav">
          {NAV.map((item, i) => {
            if (item.section) return <div className="sb-section" key={`s${i}`}>{item.section}</div>
            if (item.module !== 'settings' && item.module !== 'dashboard' && !can(item.module)) return null
            return (
              <NavLink key={item.to} to={item.to} end={item.end} className="sb-link" onClick={onClose}>
                <Icon name={item.icon} className="sb-ico" />
                {item.label}
              </NavLink>
            )
          })}
        </nav>
        <div className="sb-foot">v1.0 MVP · © {new Date().getFullYear()} KKK Oils</div>
      </aside>
    </>
  )
}

function Topbar({ onMenu }) {
  const { user, logout } = useAuth()
  const { metrics } = useData()
  const loc = useLocation()
  const alerts = metrics.lowStock.length + metrics.lowRaw.length + metrics.pendingDispatch.length
  return (
    <header className="topbar">
      <button className="icon-btn menu-btn" onClick={onMenu}><Icon name="menu" size={18} /></button>
      <div>
        <h2>{TITLES[loc.pathname] || 'Dashboard'}</h2>
        <div className="crumb">KKK Oils · {new Date().toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'long' })}</div>
      </div>
      <div className="search">
        <Icon name="search" size={16} />
        <input placeholder="Search orders, products, customers…" />
      </div>
      <div className="top-actions">
        <button className="icon-btn" title={`${alerts} alerts`}>
          <Icon name="bell" size={18} />
          {alerts > 0 && <span className="dot-badge" />}
        </button>
        <div className="user-chip" onClick={logout} title="Click to log out" style={{ cursor: 'pointer' }}>
          <div className="avatar">{user.name.split(' ').map((w) => w[0]).slice(0, 2).join('')}</div>
          <div>
            <div className="nm">{user.name}</div>
            <div className="rl">{user.roleLabel}</div>
          </div>
        </div>
      </div>
    </header>
  )
}

export default function Layout({ children }) {
  const [open, setOpen] = useState(false)
  return (
    <div className="app-shell">
      <Sidebar open={open} onClose={() => setOpen(false)} />
      <div className="main-area">
        <Topbar onMenu={() => setOpen(true)} />
        {children}
      </div>
    </div>
  )
}
