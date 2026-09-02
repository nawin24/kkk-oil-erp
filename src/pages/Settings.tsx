import { useState } from 'react'
import { useData } from '../context/DataContext'
import { useAuth } from '../context/AuthContext'
import { PageHeader, Card, Badge, Modal, Field } from '../components/ui'
import Icon from '../components/Icon'
import { ROLES } from '../data/seed'
import { isFirebaseConfigured } from '../firebase/config'
import type { Company } from '../types'

const ROLE_KEYS = Object.keys(ROLES)

export default function Settings() {
  const { company, saveCompany, resetDemo, resetEmpty, seedToFirestore, demoMode } = useData()
  const { user, users, addUser, updateUser, removeUser } = useAuth()

  const [form, setForm] = useState<Company>(company)
  const [savedMsg, setSavedMsg] = useState('')
  const [seedMsg, setSeedMsg] = useState('')
  const [seeding, setSeeding] = useState(false)

  const [staff, setStaff] = useState<any>(null)   // add/edit staff modal
  const [staffErr, setStaffErr] = useState('')

  const set = (k: keyof Company, v: string) => setForm((f) => ({ ...f, [k]: v }))
  const setBank = (k: string, v: string) => setForm((f) => ({ ...f, bank: { ...(f.bank || { name: '', acc: '', ifsc: '' }), [k]: v } }))

  const saveProfile = (e: any) => {
    e.preventDefault()
    saveCompany(form)
    setSavedMsg('✅ Company profile saved. It now appears on invoices and the sidebar.')
    setTimeout(() => setSavedMsg(''), 4000)
  }

  const runSeed = async () => {
    setSeeding(true); setSeedMsg('')
    try { await seedToFirestore(); setSeedMsg('✅ Sample data pushed to Firestore.') }
    catch (e) { setSeedMsg('⚠️ ' + (e instanceof Error ? e.message : 'Seeding failed.')) }
    finally { setSeeding(false) }
  }

  const saveStaff = async (e: any) => {
    e.preventDefault()
    setStaffErr('')
    const f = new FormData(e.target)
    const name = String(f.get('name') || '')
    const role = String(f.get('role') || 'sales')
    const password = String(f.get('password') || '')
    if (staff.id) {
      await updateUser(staff.id, { name, role, ...(password ? { password } : {}) })
      setStaff(null)
    } else {
      const username = String(f.get('username') || '')
      const res = await addUser({ username, name, role, password })
      if (!res.ok) { setStaffErr(res.error || 'Could not add staff.'); return }
      setStaff(null)
    }
  }

  return (
    <div className="page">
      <PageHeader title="Settings" subtitle="Company profile, staff logins, roles and data management." />

      <div className="grid-2 mb-16">
        {/* -------- Editable company profile -------- */}
        <Card title="Company Profile" sub="Printed on every tax invoice">
          <form className="card-pad" onSubmit={saveProfile}>
            <div className="form-grid">
              <Field label="Business Name" full><input className="inp" value={form.name} onChange={(e) => set('name', e.target.value)} required /></Field>
              <Field label="GSTIN"><input className="inp" value={form.gstin} onChange={(e) => set('gstin', e.target.value.toUpperCase())} placeholder="33ABCDE1234F1Z5" /></Field>
              <Field label="State"><input className="inp" value={form.state} onChange={(e) => set('state', e.target.value)} /></Field>
              <Field label="GST State Code"><input className="inp" value={form.stateCode} onChange={(e) => set('stateCode', e.target.value)} placeholder="33" /></Field>
              <Field label="FSSAI No."><input className="inp" value={form.fssai || ''} onChange={(e) => set('fssai', e.target.value)} /></Field>
              <Field label="Address" full><input className="inp" value={form.address} onChange={(e) => set('address', e.target.value)} /></Field>
              <Field label="Phone"><input className="inp" value={form.phone} onChange={(e) => set('phone', e.target.value)} /></Field>
              <Field label="Email"><input className="inp" value={form.email} onChange={(e) => set('email', e.target.value)} /></Field>
              <Field label="Bank Name"><input className="inp" value={form.bank?.name || ''} onChange={(e) => setBank('name', e.target.value)} /></Field>
              <Field label="A/C Number"><input className="inp" value={form.bank?.acc || ''} onChange={(e) => setBank('acc', e.target.value)} /></Field>
              <Field label="IFSC"><input className="inp" value={form.bank?.ifsc || ''} onChange={(e) => setBank('ifsc', e.target.value.toUpperCase())} /></Field>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 8 }}>
              <button className="btn btn-primary" type="submit"><Icon name="check" size={15} /> Save profile</button>
              {savedMsg && <span className="tiny" style={{ color: 'var(--green)' }}>{savedMsg}</span>}
            </div>
          </form>
        </Card>

        <Card title="Your Session" sub="Current login">
          <div className="card-pad">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
              <div className="avatar" style={{ width: 46, height: 46, fontSize: 16 }}>{user.name.split(' ').map((w: string) => w[0]).slice(0, 2).join('')}</div>
              <div>
                <div style={{ fontWeight: 700 }}>{user.name}</div>
                <div className="tiny">@{user.username}</div>
              </div>
            </div>
            <div className="kv"><span className="k">Role</span><span className="v"><Badge tone="gold" noDot>{user.roleLabel}</Badge></span></div>
            <div className="kv"><span className="k">Access</span><span className="v">{user.access === '*' ? 'All modules' : `${user.access.length} modules`}</span></div>
            <div className="kv"><span className="k">Storage</span><span className="v">{isFirebaseConfigured ? 'Cloud Firestore' : 'This browser (local)'}</span></div>
          </div>
        </Card>
      </div>

      {/* -------- Staff logins -------- */}
      <Card title="Staff Logins" sub="Who can sign in — and what they can see"
        action={<button className="btn btn-gold btn-sm" onClick={() => { setStaffErr(''); setStaff({ role: 'cashier' }) }}><Icon name="plus" size={14} /> Add staff / cashier</button>}>
        <div className="table-wrap">
          <table className="tbl">
            <thead><tr><th>Username</th><th>Name</th><th>Role</th><th>Access</th><th></th></tr></thead>
            <tbody>
              {users.map((u: any) => {
                const r = ROLES[u.role as keyof typeof ROLES]
                return (
                  <tr key={u.id}>
                    <td className="cell-strong">@{u.username}</td>
                    <td>{u.name}{u.id === user.id && <span className="tiny" style={{ color: 'var(--green)' }}> · you</span>}</td>
                    <td><Badge tone="gold" noDot>{r?.label || u.role}</Badge></td>
                    <td className="muted">{r?.access === '*' ? 'All modules' : `${(r?.access as string[])?.length || 0} modules`}</td>
                    <td><div className="row-actions">
                      <button title="Edit / reset password" onClick={() => { setStaffErr(''); setStaff(u) }}><Icon name="edit" size={15} /></button>
                      {u.id !== user.id && <button className="del" title="Remove" onClick={() => window.confirm(`Remove staff @${u.username}?`) && removeUser(u.id)}><Icon name="trash" size={15} /></button>}
                    </div></td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </Card>

      <div className="grid-2" style={{ marginTop: 16 }}>
        <Card title="Notifications & Alerts" sub="Automatic triggers">
          <div className="card-pad">
            {['Low stock alert', 'Pending payment reminder', 'Pending dispatch', 'Production delay', 'Supplier due', 'Credit limit exceeded', 'Expiry nearing', 'Daily sales summary'].map((a) => (
              <label key={a} className="alert-row" style={{ cursor: 'pointer' }}>
                <div className="alert-ico" style={{ background: 'var(--gold-soft)', color: 'var(--gold-deep)' }}><Icon name="bell" size={15} /></div>
                <span style={{ flex: 1, fontSize: 13, fontWeight: 500 }}>{a}</span>
                <input type="checkbox" defaultChecked />
              </label>
            ))}
          </div>
        </Card>

        <Card title="Data & Backend" sub="Storage and reset">
          <div className="card-pad">
            <div className="kv" style={{ marginBottom: 12 }}>
              <span className="k">Backend</span>
              <span className="v">{isFirebaseConfigured ? <Badge tone="green" noDot>Firestore connected</Badge> : <Badge tone="amber" noDot>Local (this browser)</Badge>}</span>
            </div>

            {demoMode ? (
              <>
                <p className="tiny" style={{ marginBottom: 14 }}>
                  Your data is saved permanently in this browser. For a shared, multi-device backend, add Firebase
                  credentials to <code>.env</code> (see <code>.env.example</code>) and deploy <code>firestore.rules</code>, then restart.
                </p>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  <button className="btn" onClick={() => window.confirm('Start fresh? This clears ALL records (products, customers, bills…) so you can enter your own. This cannot be undone.') && resetEmpty()}>
                    <Icon name="plus" size={15} /> Start fresh (empty)
                  </button>
                  <button className="btn btn-danger" onClick={() => window.confirm('Reload the KKK sample dataset? Your current data will be replaced.') && resetDemo()}>
                    <Icon name="trash" size={15} /> Load sample data
                  </button>
                </div>
              </>
            ) : (
              <>
                <p className="tiny" style={{ marginBottom: 14 }}>Live Firestore backend. Push a starter dataset into your collections if this is a new project.</p>
                <button className="btn btn-gold" onClick={runSeed} disabled={seeding}>
                  <Icon name="download" size={15} /> {seeding ? 'Seeding…' : 'Seed Firestore with sample data'}
                </button>
                {seedMsg && <p className="tiny" style={{ marginTop: 10 }}>{seedMsg}</p>}
              </>
            )}

            <div style={{ marginTop: 18 }}>
              <div className="kv"><span className="k">Build</span><span className="v">v1.1 · TypeScript</span></div>
              <div className="kv"><span className="k">Storage</span><span className="v">{isFirebaseConfigured ? 'Cloud Firestore' : 'Browser localStorage'}</span></div>
              <div className="kv"><span className="k">Stack</span><span className="v">React + TypeScript + Vite · Firebase</span></div>
            </div>
          </div>
        </Card>
      </div>

      {staff && (
        <Modal title={staff.id ? `Edit staff · @${staff.username}` : 'Add staff login'} onClose={() => setStaff(null)}
          footer={<><button className="btn" onClick={() => setStaff(null)}>Cancel</button><button className="btn btn-primary" form="staffForm">{staff.id ? 'Save' : 'Add staff'}</button></>}>
          <form id="staffForm" onSubmit={saveStaff} className="form-grid">
            {!staff.id && <Field label="Username" full><input className="inp" name="username" autoCapitalize="none" placeholder="e.g. cashier1" required /></Field>}
            <Field label="Full Name" full><input className="inp" name="name" defaultValue={staff.name || ''} placeholder="e.g. Anitha M" required /></Field>
            <Field label="Role"><select className="sel" name="role" defaultValue={staff.role || 'cashier'}>{ROLE_KEYS.map((k) => <option key={k} value={k}>{ROLES[k as keyof typeof ROLES]?.label || k}</option>)}</select></Field>
            <Field label={staff.id ? 'New Password (blank = keep)' : 'Password'}><input className="inp" type="password" name="password" placeholder={staff.id ? '••••••' : 'min 4 chars'} {...(staff.id ? {} : { required: true })} /></Field>
            {staffErr && <div style={{ gridColumn: '1/-1', color: 'var(--red)', fontSize: 13, fontWeight: 600 }}>{staffErr}</div>}
          </form>
        </Modal>
      )}
    </div>
  )
}
