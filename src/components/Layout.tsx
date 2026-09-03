import { useState } from 'react'
import { NavLink, useLocation } from 'react-router-dom'
import Icon from './Icon'
import { Modal } from './ui'
import { useAuth } from '../context/AuthContext'
import { useData } from '../context/DataContext'

const NAV = [
  { section: 'Main' },
  { to: '/', label: 'Dashboard', icon: 'dashboard', module: 'dashboard', end: true },

  { section: 'GST Billing & Operations' },
  { to: '/gst-billing', label: 'GST Billing Voucher', icon: 'rupee', module: 'billing' },
  { to: '/gst-history', label: 'GST Invoices History', icon: 'billing', module: 'billing' },
  { to: '/products', label: 'Product Master', icon: 'products', module: 'products' },
  { to: '/price-management', label: 'Price Management', icon: 'edit', module: 'price_management' },
  { to: '/price-history', label: 'Price History', icon: 'reports', module: 'price_history' },
  { to: '/inventory', label: 'Inventory', icon: 'inventory', module: 'inventory' },
  { to: '/purchase', label: 'Purchase', icon: 'purchase', module: 'purchase' },
  { to: '/production', label: 'Production', icon: 'production', module: 'production' },
  { section: 'Non-GST Billing (Super Admin)' },
  { to: '/non-gst-billing', label: 'Non-GST Billing Voucher', icon: 'rupee', module: 'non_gst_billing' },
  { to: '/non-gst-history', label: 'Non-GST History', icon: 'doc', module: 'non_gst_billing' },

  { section: 'People & Settings' },
  { to: '/customers', label: 'Customers', icon: 'customers', module: 'customers' },
  { to: '/suppliers', label: 'Suppliers', icon: 'suppliers', module: 'suppliers' },
  { to: '/reports', label: 'Reports', icon: 'reports', module: 'reports' },
  { to: '/settings', label: 'Settings', icon: 'settings', module: 'settings' },
]

const TITLES: Record<string, string> = {
  '/': 'Dashboard',
  '/products': 'Product Master',
  '/price-management': 'Price Management',
  '/price-history': 'Price History',
  '/brands': 'Brands',
  '/gst-billing': 'GST ERP Billing Voucher',
  '/erp-billing': 'GST ERP Billing Voucher',
  '/gst-history': 'GST Invoices History',
  '/billing-history': 'GST Invoices History',
  '/non-gst-billing': 'Non-GST Billing Voucher (Super Admin)',
  '/non-gst-history': 'Non-GST History (Super Admin)',
  '/inventory': 'Inventory',
  '/purchase': 'Purchase',
  '/production': 'Production',
  '/sales': 'Sales Orders',
  '/logistics': 'Logistics',
  '/customers': 'Customers',
  '/suppliers': 'Suppliers',
  '/reports': 'Reports & Analytics',
  '/settings': 'Settings',
}

function Sidebar({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { can, isCashier, isSuperAdmin } = useAuth()
  const { company } = useData()
  const name = company?.name || 'KKK Oil Factory'
  const logo = name.split(' ').map((w: string) => w[0]).slice(0, 3).join('').toUpperCase()

  return (
    <>
      {open && <div className="sb-backdrop" onClick={onClose} />}
      <aside className={`sidebar ${open ? 'open' : ''}`}>
        <div className="sb-brand">
          <div className="sb-logo">{logo}</div>
          <div>
            <h1>{name}</h1>
            <span>{company?.state || 'Tamil Nadu'} · ERP</span>
          </div>
        </div>
        <nav className="sb-nav">
          {NAV.map((item, i) => {
            if (item.section === 'Non-GST Billing (Super Admin)' && !can('non_gst_billing')) return null
            if (item.section) return <div className="sb-section" key={`s${i}`}>{item.section}</div>

            // Strict Role Hiding
            if (item.module === 'non_gst_billing' && !can('non_gst_billing')) return null
            if (item.module === 'price_management' && !can('price_management')) return null
            if (isCashier && !['billing', 'inventory', 'customers'].includes(item.module)) return null
            if (!can(item.module)) return null

            return (
              <NavLink key={item.to} to={item.to} end={item.end} className="sb-link" onClick={onClose}>
                <Icon name={item.icon} className="sb-ico" />
                {item.label}
              </NavLink>
            )
          })}
        </nav>
        <div className="sb-foot">v2.0 Professional ERP · © {new Date().getFullYear()} KKK Oils</div>
      </aside>
    </>
  )
}

function Topbar({ onMenu }: { onMenu: () => void }) {
  const { user, isSuperAdmin, isNonGstSession, logout } = useAuth()
  const { metrics, company } = useData()
  const loc = useLocation()
  const alerts = metrics.lowStock.length + metrics.lowRaw.length + metrics.pendingDispatch.length

  return (
    <header className="topbar">
      <button className="icon-btn menu-btn" onClick={onMenu}><Icon name="menu" size={18} /></button>
      <div>
        <h2>{TITLES[loc.pathname] || 'ERP Dashboard'}</h2>
        <div className="crumb">{company?.name || 'KKK Oils'} · {new Date().toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'long' })}</div>
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
          <div className="avatar">{(user?.name || 'User').split(' ').map((w: string) => w[0]).slice(0, 2).join('')}</div>
          <div>
            <div className="nm">{user?.name}</div>
            <div className="rl">{isNonGstSession ? 'Super Admin (Non-GST)' : user?.roleLabel}</div>
          </div>
        </div>
      </div>
    </header>
  )
}

export default function Layout({ children }: { children: React.ReactNode }) {
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

