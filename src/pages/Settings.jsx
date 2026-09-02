import { useData } from '../context/DataContext.jsx'
import { useAuth } from '../context/AuthContext.jsx'
import { PageHeader, Card, Badge } from '../components/ui.jsx'
import Icon from '../components/Icon.jsx'
import { ROLES, USERS } from '../data/seed.js'

export default function Settings() {
  const { resetDemo } = useData()
  const { user } = useAuth()

  return (
    <div className="page">
      <PageHeader title="Settings" subtitle="Company profile, roles, permissions and data management." />

      <div className="grid-2 mb-16">
        <Card title="Company Profile" sub="KKK Oil Factory">
          <div className="card-pad">
            <div className="kv"><span className="k">Business Name</span><span className="v">KKK Oils</span></div>
            <div className="kv"><span className="k">Location</span><span className="v">Dharmapuri, Tamil Nadu</span></div>
            <div className="kv"><span className="k">GSTIN</span><span className="v">33ABCKK1234F1Z5</span></div>
            <div className="kv"><span className="k">Own Brand</span><span className="v">KKK Gold</span></div>
            <div className="kv"><span className="k">Brands Handled</span><span className="v">4</span></div>
            <div className="kv"><span className="k">Financial Year</span><span className="v">2026–27</span></div>
          </div>
        </Card>

        <Card title="Your Session" sub="Current login">
          <div className="card-pad">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
              <div className="avatar" style={{ width: 46, height: 46, fontSize: 16 }}>{user.name.split(' ').map((w) => w[0]).slice(0, 2).join('')}</div>
              <div>
                <div style={{ fontWeight: 700 }}>{user.name}</div>
                <div className="tiny">{user.email} · {user.phone}</div>
              </div>
            </div>
            <div className="kv"><span className="k">Role</span><span className="v"><Badge tone="gold" noDot>{user.roleLabel}</Badge></span></div>
            <div className="kv"><span className="k">Access</span><span className="v">{user.access === '*' ? 'All modules' : `${user.access.length} modules`}</span></div>
          </div>
        </Card>
      </div>

      <Card title="Roles & Permissions" sub="Role-based access control">
        <div className="table-wrap">
          <table className="tbl">
            <thead><tr><th>Role</th><th>User</th><th>Module Access</th></tr></thead>
            <tbody>
              {Object.entries(ROLES).map(([key, r]) => {
                const u = USERS.find((x) => x.role === key)
                return (
                  <tr key={key}>
                    <td className="cell-strong">{r.label}</td>
                    <td className="muted">{u?.name}</td>
                    <td>
                      {r.access === '*'
                        ? <Badge tone="green" noDot>Full Access</Badge>
                        : <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>{r.access.map((m) => <Badge key={m} tone="gray" noDot>{m}</Badge>)}</div>}
                    </td>
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

        <Card title="Data Management" sub="Demo controls">
          <div className="card-pad">
            <p className="tiny" style={{ marginBottom: 14 }}>All ERP data is stored locally in your browser. You can reset everything back to the original demo dataset at any time.</p>
            <button className="btn btn-danger" onClick={() => window.confirm('Reset all data to demo defaults? Your changes will be lost.') && resetDemo()}>
              <Icon name="trash" size={15} /> Reset demo data
            </button>
            <div style={{ marginTop: 18 }}>
              <div className="kv"><span className="k">Build</span><span className="v">v1.0 MVP</span></div>
              <div className="kv"><span className="k">Storage</span><span className="v">Browser localStorage</span></div>
              <div className="kv"><span className="k">Stack</span><span className="v">React + Vite · Express API ready</span></div>
            </div>
          </div>
        </Card>
      </div>
    </div>
  )
}
