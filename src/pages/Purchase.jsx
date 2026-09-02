import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext.jsx'
import { PageHeader, Badge, Modal, Field, Toolbar, StatCard, EmptyState } from '../components/ui.jsx'
import Icon from '../components/Icon.jsx'
import { inr, inrShort, fmtDate, num, csvExport, uid, todayISO, PAY_COLORS, QC_COLORS } from '../utils/helpers.js'

export default function Purchase() {
  const { purchases, suppliers, supplierMap, metrics, upsert, remove } = useData()
  const [q, setQ] = useState('')
  const [status, setStatus] = useState('all')
  const [edit, setEdit] = useState(null)

  const withTotals = purchases.map((po) => {
    const sub = po.qty * po.rate
    const tax = sub * (po.gst / 100)
    return { ...po, sub, tax, total: sub + tax, supplier: supplierMap[po.supplierId]?.name }
  })

  const rows = useMemo(() => withTotals.filter((po) => {
    if (status !== 'all' && po.payStatus !== status) return false
    if (q && !(`${po.id} ${po.material} ${po.supplier}`.toLowerCase().includes(q.toLowerCase()))) return false
    return true
  }), [withTotals, status, q])

  const totalPurchase = withTotals.reduce((s, p) => s + p.total, 0)
  const pendingQC = withTotals.filter((p) => p.qc === 'Pending').length

  const blank = { id: uid('PO'), supplierId: suppliers[0]?.id, date: todayISO(), material: '', qty: 0, unit: 'kg', rate: 0, gst: 5, qc: 'Pending', payStatus: 'Unpaid', inward: false }

  const save = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    upsert('purchases', {
      id: edit.id, supplierId: f.get('supplierId'), date: f.get('date'), material: f.get('material'),
      qty: +f.get('qty'), unit: f.get('unit'), rate: +f.get('rate'), gst: +f.get('gst'),
      qc: f.get('qc'), payStatus: f.get('payStatus'), inward: f.get('inward') === 'on',
    })
    setEdit(null)
  }

  return (
    <div className="page">
      <PageHeader title="Raw Material Purchase" subtitle="Purchase orders, inward, quality checks and supplier dues.">
        <button className="btn" onClick={() => csvExport('purchases.csv', rows.map(({ ...r }) => r))}><Icon name="download" /> GST Purchase Report</button>
        <button className="btn btn-gold" onClick={() => setEdit(blank)}><Icon name="plus" /> New Purchase Order</button>
      </PageHeader>

      <div className="stat-grid">
        <StatCard icon="purchase" tone="gold" label="Total Purchases" value={inrShort(totalPurchase)} delta={`${purchases.length} orders`} deltaDir="flat" />
        <StatCard icon="rupee" tone="red" label="Supplier Due" value={inrShort(metrics.purchaseDue)} delta="payable" deltaDir="flat" />
        <StatCard icon="alert" tone="amber" label="Pending QC" value={`${pendingQC} lots`} delta="awaiting check" deltaDir="flat" />
        <StatCard icon="check" tone="green" label="Inward Done" value={`${withTotals.filter((p) => p.inward).length} lots`} delta="received" deltaDir="up" />
      </div>

      <Toolbar search={q} onSearch={setQ} placeholder="Search PO, material, supplier…">
        <select className="sel" value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="all">All Payment Status</option><option>Paid</option><option>Partial</option><option>Unpaid</option>
        </select>
      </Toolbar>

      <div className="card table-wrap">
        <table className="tbl">
          <thead><tr>
            <th>PO No</th><th>Supplier</th><th>Material</th><th>Date</th>
            <th className="num">Qty</th><th className="num">Rate</th><th className="num">Total (inc GST)</th>
            <th>QC</th><th>Inward</th><th>Payment</th><th></th>
          </tr></thead>
          <tbody>
            {rows.map((po) => (
              <tr key={po.id}>
                <td className="cell-strong">{po.id}</td>
                <td>{po.supplier}</td>
                <td className="muted">{po.material}</td>
                <td className="muted">{fmtDate(po.date)}</td>
                <td className="num">{num(po.qty)} {po.unit}</td>
                <td className="num muted">{inr(po.rate)}</td>
                <td className="num cell-strong">{inr(po.total)}</td>
                <td><Badge tone={QC_COLORS[po.qc]} noDot>{po.qc}</Badge></td>
                <td>{po.inward ? <Badge tone="green">Received</Badge> : <Badge tone="gray">Awaiting</Badge>}</td>
                <td><Badge tone={PAY_COLORS[po.payStatus]} noDot>{po.payStatus}</Badge></td>
                <td><div className="row-actions">
                  <button onClick={() => setEdit(po)}><Icon name="edit" size={15} /></button>
                  <button className="del" onClick={() => window.confirm('Delete PO?') && remove('purchases', po.id)}><Icon name="trash" size={15} /></button>
                </div></td>
              </tr>
            ))}
          </tbody>
        </table>
        {!rows.length && <EmptyState icon="purchase" text="No purchase orders" />}
      </div>

      {edit && (
        <Modal lg title={purchases.some((p) => p.id === edit.id) ? 'Edit Purchase Order' : 'New Purchase Order'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="poForm">Save Purchase</button></>}>
          <form id="poForm" onSubmit={save} className="form-grid">
            <Field label="Supplier"><select className="sel" name="supplierId" defaultValue={edit.supplierId}>{suppliers.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}</select></Field>
            <Field label="Date"><input className="inp" type="date" name="date" defaultValue={edit.date} /></Field>
            <Field label="Material" full><input className="inp" name="material" defaultValue={edit.material} required /></Field>
            <Field label="Quantity"><input className="inp" type="number" name="qty" defaultValue={edit.qty} /></Field>
            <Field label="Unit"><select className="sel" name="unit" defaultValue={edit.unit}><option>kg</option><option>L</option><option>pcs</option></select></Field>
            <Field label="Rate"><input className="inp" type="number" name="rate" defaultValue={edit.rate} /></Field>
            <Field label="GST %"><input className="inp" type="number" name="gst" defaultValue={edit.gst} /></Field>
            <Field label="QC Status"><select className="sel" name="qc" defaultValue={edit.qc}><option>Pending</option><option>Passed</option><option>Failed</option></select></Field>
            <Field label="Payment Status"><select className="sel" name="payStatus" defaultValue={edit.payStatus}><option>Unpaid</option><option>Partial</option><option>Paid</option></select></Field>
            <Field label="Inward Received" full><label style={{ display: 'flex', gap: 8, alignItems: 'center', fontWeight: 500 }}><input type="checkbox" name="inward" defaultChecked={edit.inward} /> Material received into godown</label></Field>
          </form>
        </Modal>
      )}
    </div>
  )
}
