import { useEffect } from 'react'
import Icon from './Icon.jsx'

export function PageHeader({ title, subtitle, children }) {
  return (
    <div className="page-head">
      <div>
        <h3>{title}</h3>
        {subtitle && <p>{subtitle}</p>}
      </div>
      {children && <div className="actions">{children}</div>}
    </div>
  )
}

export function StatCard({ icon, label, value, delta, deltaDir = 'flat', tone = 'gold' }) {
  const tones = {
    gold:   { bg: 'var(--gold-soft)', fg: 'var(--gold-deep)' },
    green:  { bg: 'var(--green-soft)', fg: '#137a4d' },
    blue:   { bg: 'var(--blue-soft)', fg: 'var(--blue)' },
    amber:  { bg: 'var(--amber-soft)', fg: 'var(--amber)' },
    red:    { bg: 'var(--red-soft)', fg: 'var(--red)' },
    teal:   { bg: 'var(--teal-soft)', fg: 'var(--teal)' },
    purple: { bg: 'var(--purple-soft)', fg: 'var(--purple)' },
  }
  const t = tones[tone] || tones.gold
  return (
    <div className="stat">
      <div className="ico" style={{ background: t.bg, color: t.fg }}><Icon name={icon} size={20} /></div>
      <div className="lbl">{label}</div>
      <div className="val">{value}</div>
      {delta != null && (
        <span className={`delta ${deltaDir}`}>
          {deltaDir === 'up' && <Icon name="arrowUp" size={12} />}
          {deltaDir === 'down' && <Icon name="arrowDown" size={12} />}
          {delta}
        </span>
      )}
    </div>
  )
}

export function Badge({ tone = 'gray', children, noDot }) {
  return <span className={`badge ${tone}${noDot ? ' no-dot' : ''}`}>{children}</span>
}

export function Card({ title, sub, action, children, pad = false }) {
  return (
    <div className="card">
      {title && (
        <div className="card-head">
          <div>
            <h4>{title}</h4>
            {sub && <div className="sub">{sub}</div>}
          </div>
          {action}
        </div>
      )}
      <div className={pad ? 'card-pad' : ''}>{children}</div>
    </div>
  )
}

export function Modal({ title, onClose, children, footer, lg }) {
  useEffect(() => {
    const h = (e) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', h)
    return () => window.removeEventListener('keydown', h)
  }, [onClose])
  return (
    <div className="modal-overlay" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className={`modal ${lg ? 'lg' : ''}`}>
        <div className="modal-head">
          <h3>{title}</h3>
          <button className="icon-btn" style={{ width: 34, height: 34 }} onClick={onClose}><Icon name="close" size={16} /></button>
        </div>
        <div className="modal-body">{children}</div>
        {footer && <div className="modal-foot">{footer}</div>}
      </div>
    </div>
  )
}

export function Field({ label, children, full }) {
  return (
    <div className={`form-row ${full ? 'full' : ''}`}>
      {label && <label>{label}</label>}
      {children}
    </div>
  )
}

export function EmptyState({ icon = 'box', text = 'No records found' }) {
  return (
    <div className="empty">
      <Icon name={icon} size={40} />
      <div>{text}</div>
    </div>
  )
}

export function LogoPill({ name, color }) {
  const initials = name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase()
  return <div className="logo-pill" style={{ background: color || 'var(--forest)' }}>{initials}</div>
}

export function Toolbar({ search, onSearch, placeholder = 'Search…', children }) {
  return (
    <div className="toolbar">
      <div className="field-search">
        <Icon name="search" size={16} style={{ color: 'var(--text-3)' }} />
        <input value={search} onChange={(e) => onSearch(e.target.value)} placeholder={placeholder} />
      </div>
      {children}
    </div>
  )
}
