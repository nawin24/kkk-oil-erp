import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext.jsx'
import { PageHeader, Badge, Modal, Field, Toolbar, StatCard, EmptyState, LogoPill } from '../components/ui.jsx'
import Icon from '../components/Icon.jsx'
import { inr, inrShort, csvExport, uid } from '../utils/helpers.js'

function Stars({ rating }) {
  return (
    <span style={{ color: 'var(--gold)', fontSize: 13, letterSpacing: 1 }} title={rating}>
      {'★'.repeat(Math.round(rating))}<span style={{ color: 'var(--border-strong)' }}>{'★'.repeat(5 - Math.round(rating))}</span>
    </span>
  )
}

export default function Suppliers() {
  const { suppliers, purchases, upsert, remove } = useData()
  const [q, setQ] = useState('')
  const [edit, setEdit] = useState(null)

  const enriched = suppliers.map((s) => ({
    ...s,
    orders: purchases.filter((p) => p.supplierId === s.id).length,
  }))

  const rows = useMemo(() => enriched.filter((s) =>
    !q || `${s.name} ${s.material} ${s.address}`.toLowerCase().includes(q.toLowerCase())), [enriched, q])

  const totalDue = suppliers.reduce((s, x) => s + x.due, 0)
  const avgRating = (suppliers.reduce((s, x) => s + x.rating, 0) / suppliers.length).toFixed(1)

  const blank = { id: uid('S'), name: '', material: '', contact: '', phone: '', gstin: '', address: '', rating: 4, due: 0 }

  const save = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    upsert('suppliers', {
      id: edit.id, name: f.get('name'), material: f.get('material'), contact: f.get('contact'),
      phone: f.get('phone'), gstin: f.get('gstin'), address: f.get('address'), rating: +f.get('rating'), due: +f.get('due'),
    })
    setEdit(null)
  }

  return (
    <div className="page">
      <PageHeader title="Suppliers" subtitle="Raw material & packing suppliers, dues and quality ratings.">
        <button className="btn" onClick={() => csvExport('suppliers.csv', rows)}><Icon name="download" /> Export</button>
        <button className="btn btn-gold" onClick={() => setEdit(blank)}><Icon name="plus" /> Add Supplier</button>
      </PageHeader>

      <div className="stat-grid">
        <StatCard icon="suppliers" tone="blue" label="Total Suppliers" value={`${suppliers.length}`} delta="active" deltaDir="flat" />
        <StatCard icon="rupee" tone="red" label="Total Payable" value={inrShort(totalDue)} delta="supplier dues" deltaDir="down" />
        <StatCard icon="reports" tone="gold" label="Avg Quality Rating" value={`${avgRating} / 5`} delta="across vendors" deltaDir="up" />
        <StatCard icon="purchase" tone="teal" label="Purchase Orders" value={`${purchases.length}`} delta="period" deltaDir="flat" />
      </div>

      <Toolbar search={q} onSearch={setQ} placeholder="Search supplier or material…" />

      <div className="card table-wrap">
        <table className="tbl">
          <thead><tr>
            <th>Supplier</th><th>Material</th><th>GSTIN</th><th>Location</th>
            <th className="num">POs</th><th>Quality</th><th className="num">Payment Due</th><th></th>
          </tr></thead>
          <tbody>
            {rows.map((s) => (
              <tr key={s.id}>
                <td><div className="with-logo">
                  <LogoPill name={s.name} color="#7c3aed" />
                  <div><div className="cell-strong">{s.name}</div><div className="cell-sub">{s.contact} · {s.phone}</div></div>
                </div></td>
                <td className="muted">{s.material}</td>
                <td className="muted" style={{ fontSize: 12 }}>{s.gstin}</td>
                <td className="muted">{s.address}</td>
                <td className="num">{s.orders}</td>
                <td><Stars rating={s.rating} /></td>
                <td className="num"><span style={{ fontWeight: 600, color: s.due > 0 ? 'var(--red)' : 'var(--green)' }}>{s.due > 0 ? inr(s.due) : 'Settled'}</span></td>
                <td><div className="row-actions">
                  <button onClick={() => setEdit(s)}><Icon name="edit" size={15} /></button>
                  <button className="del" onClick={() => window.confirm('Delete supplier?') && remove('suppliers', s.id)}><Icon name="trash" size={15} /></button>
                </div></td>
              </tr>
            ))}
          </tbody>
        </table>
        {!rows.length && <EmptyState icon="suppliers" text="No suppliers found" />}
      </div>

      {edit && (
        <Modal lg title={suppliers.some((s) => s.id === edit.id) ? 'Edit Supplier' : 'Add Supplier'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="supForm">Save Supplier</button></>}>
          <form id="supForm" onSubmit={save} className="form-grid">
            <Field label="Supplier Name" full><input className="inp" name="name" defaultValue={edit.name} required /></Field>
            <Field label="Material Supplied"><input className="inp" name="material" defaultValue={edit.material} /></Field>
            <Field label="Contact Person"><input className="inp" name="contact" defaultValue={edit.contact} /></Field>
            <Field label="Phone"><input className="inp" name="phone" defaultValue={edit.phone} /></Field>
            <Field label="GSTIN"><input className="inp" name="gstin" defaultValue={edit.gstin} /></Field>
            <Field label="Address" full><input className="inp" name="address" defaultValue={edit.address} /></Field>
            <Field label="Quality Rating (1-5)"><input className="inp" type="number" step="0.1" min="1" max="5" name="rating" defaultValue={edit.rating} /></Field>
            <Field label="Payment Due"><input className="inp" type="number" name="due" defaultValue={edit.due} /></Field>
          </form>
        </Modal>
      )}
    </div>
  )
}
