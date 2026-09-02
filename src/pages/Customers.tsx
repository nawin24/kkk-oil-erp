import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Badge, Modal, Field, Toolbar, StatCard, EmptyState, LogoPill } from '../components/ui'
import Icon from '../components/Icon'
import { inr, inrShort, num, csvExport, uid, orderTotals } from '../utils/helpers'

export default function Customers() {
  const { customers, sales, productMap, upsert, remove } = useData()
  const [q, setQ] = useState('')
  const [type, setType] = useState('all')
  const [edit, setEdit] = useState(null)

  const enriched = customers.map((c) => {
    const orders = sales.filter((s) => s.customerId === c.id)
    const business = orders.reduce((s, o) => s + orderTotals(o.items, productMap).total, 0)
    const overLimit = c.outstanding > c.creditLimit
    return { ...c, orders: orders.length, business, overLimit }
  })

  const rows = useMemo(() => enriched.filter((c) => {
    if (type !== 'all' && c.type !== type) return false
    if (q && !`${c.name} ${c.area} ${c.contact}`.toLowerCase().includes(q.toLowerCase())) return false
    return true
  }), [enriched, type, q])

  const totalOutstanding = customers.reduce((s, c) => s + c.outstanding, 0)
  const overLimitCount = enriched.filter((c) => c.overLimit).length

  const blank = { id: uid('C'), name: '', type: 'Dealer', contact: '', phone: '', gstin: '', area: '', route: 'R1', creditLimit: 100000, outstanding: 0, brandPref: 'KKK Gold' }

  const save = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    upsert('customers', {
      id: edit.id, name: f.get('name'), type: f.get('type'), contact: f.get('contact'), phone: f.get('phone'),
      gstin: f.get('gstin'), area: f.get('area'), route: f.get('route'), creditLimit: +f.get('creditLimit'),
      outstanding: +f.get('outstanding'), brandPref: f.get('brandPref'),
    })
    setEdit(null)
  }

  return (
    <div className="page">
      <PageHeader title="Customers & Dealers" subtitle="Dealer profiles, credit limits, outstanding and order history.">
        <button className="btn" onClick={() => csvExport('customers.csv', rows.map(({ overLimit, ...r }) => r))}><Icon name="download" /> Export</button>
        <button className="btn btn-gold" onClick={() => setEdit(blank)}><Icon name="plus" /> Add Customer</button>
      </PageHeader>

      <div className="stat-grid">
        <StatCard icon="customers" tone="blue" label="Total Customers" value={`${customers.length}`} delta="dealers & retail" deltaDir="flat" />
        <StatCard icon="rupee" tone="red" label="Total Outstanding" value={inrShort(totalOutstanding)} delta="receivable" deltaDir="down" />
        <StatCard icon="alert" tone="amber" label="Over Credit Limit" value={`${overLimitCount} dealers`} delta="hold sales" deltaDir="down" />
        <StatCard icon="sales" tone="green" label="Active Routes" value={`${new Set(customers.map((c) => c.route)).size}`} delta="delivery routes" deltaDir="flat" />
      </div>

      <Toolbar search={q} onSearch={setQ} placeholder="Search name, area, contact…">
        <select className="sel" value={type} onChange={(e) => setType(e.target.value)}>
          <option value="all">All Types</option><option>Dealer</option><option>Distributor</option><option>Wholesale</option><option>Retail</option>
        </select>
      </Toolbar>

      <div className="card table-wrap">
        <table className="tbl">
          <thead><tr>
            <th>Customer</th><th>Type</th><th>Area / Route</th><th>Brand Pref.</th>
            <th className="num">Credit Limit</th><th className="num">Outstanding</th><th className="num">Orders</th><th></th>
          </tr></thead>
          <tbody>
            {rows.map((c) => (
              <tr key={c.id}>
                <td><div className="with-logo">
                  <LogoPill name={c.name} color="#1f8a5b" />
                  <div><div className="cell-strong">{c.name}</div><div className="cell-sub">{c.contact} · {c.phone}</div></div>
                </div></td>
                <td><Badge tone="gray" noDot>{c.type}</Badge></td>
                <td><div className="cell-strong" style={{ fontSize: 12.5 }}>{c.area}</div><div className="cell-sub">Route {c.route}</div></td>
                <td className="muted">{c.brandPref}</td>
                <td className="num muted">{inr(c.creditLimit)}</td>
                <td className="num">
                  <span style={{ fontWeight: 600, color: c.overLimit ? 'var(--red)' : 'inherit' }}>{inr(c.outstanding)}</span>
                  {c.overLimit && <div><Badge tone="red" noDot>Over limit</Badge></div>}
                </td>
                <td className="num">{c.orders}</td>
                <td><div className="row-actions">
                  <button onClick={() => setEdit(c)}><Icon name="edit" size={15} /></button>
                  <button className="del" onClick={() => window.confirm('Delete customer?') && remove('customers', c.id)}><Icon name="trash" size={15} /></button>
                </div></td>
              </tr>
            ))}
          </tbody>
        </table>
        {!rows.length && <EmptyState icon="customers" text="No customers found" />}
      </div>

      {edit && (
        <Modal lg title={customers.some((c) => c.id === edit.id) ? 'Edit Customer' : 'Add Customer'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="custForm">Save Customer</button></>}>
          <form id="custForm" onSubmit={save} className="form-grid">
            <Field label="Customer Name" full><input className="inp" name="name" defaultValue={edit.name} required /></Field>
            <Field label="Type"><select className="sel" name="type" defaultValue={edit.type}><option>Dealer</option><option>Distributor</option><option>Wholesale</option><option>Retail</option></select></Field>
            <Field label="Contact Person"><input className="inp" name="contact" defaultValue={edit.contact} /></Field>
            <Field label="Phone"><input className="inp" name="phone" defaultValue={edit.phone} /></Field>
            <Field label="GSTIN"><input className="inp" name="gstin" defaultValue={edit.gstin} /></Field>
            <Field label="Area"><input className="inp" name="area" defaultValue={edit.area} /></Field>
            <Field label="Route"><input className="inp" name="route" defaultValue={edit.route} /></Field>
            <Field label="Brand Preference"><input className="inp" name="brandPref" defaultValue={edit.brandPref} /></Field>
            <Field label="Credit Limit"><input className="inp" type="number" name="creditLimit" defaultValue={edit.creditLimit} /></Field>
            <Field label="Outstanding"><input className="inp" type="number" name="outstanding" defaultValue={edit.outstanding} /></Field>
          </form>
        </Modal>
      )}
    </div>
  )
}
