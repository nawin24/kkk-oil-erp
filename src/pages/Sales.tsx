import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Badge, Modal, Field, Toolbar, StatCard, EmptyState } from '../components/ui'
import Icon from '../components/Icon'
import { inr, inrShort, fmtDate, num, csvExport, uid, todayISO, orderTotals, orderProfit, DISPATCH_COLORS, PAY_COLORS } from '../utils/helpers'

import { useAuth } from '../context/AuthContext'

const DISPATCH_STAGES = ['Order Received', 'Packing Pending', 'Ready for Dispatch', 'Loaded', 'In Transit', 'Delivered', 'Returned']

export default function Sales() {
  const { sales, customers, products, customerMap, productMap, upsert, remove } = useData()
  const { isNonGstSession } = useAuth()
  const [q, setQ] = useState('')
  const [status, setStatus] = useState('all')
  const [edit, setEdit] = useState<any>(null)
  const [lines, setLines] = useState<any[]>([])

  const rows = useMemo(() => sales.filter((so: any) => {
    const bType = so.billingType || (so.id.startsWith('NG') ? 'NON_GST' : 'GST')
    if (bType === 'NON_GST' && !isNonGstSession) return false
    return true
  }).map((so: any) => {
    const t = orderTotals(so.items, productMap)
    return { ...so, ...t, profit: orderProfit(so.items, productMap), customer: customerMap[so.customerId] }
  }).filter((so: any) => {
    if (status !== 'all' && so.dispatch !== status) return false
    if (q && !(`${so.id} ${so.customer?.name}`.toLowerCase().includes(q.toLowerCase()))) return false
    return true
  }), [sales, productMap, customerMap, status, q, isNonGstSession])

  const totalSales = rows.reduce((s, r) => s + r.total, 0)
  const totalProfit = rows.reduce((s, r) => s + r.profit, 0)
  const pending = sales.filter((s) => !['Delivered', 'Returned'].includes(s.dispatch)).length

  const openNew = () => {
    setLines([{ productId: products[0]?.id, qty: 1, rate: products[0]?.price || 0 }])
    setEdit({ id: uid('SO'), customerId: customers[0]?.id, date: todayISO(), salesperson: 'Anitha M', dispatch: 'Order Received', payStatus: 'Pending' })
  }
  const openEdit = (so) => { setLines(so.items.map((i) => ({ ...i }))); setEdit(so) }

  const addLine = () => setLines([...lines, { productId: products[0]?.id, qty: 1, rate: products[0]?.price || 0 }])
  const setLine = (i, key, val) => setLines(lines.map((l, idx) => {
    if (idx !== i) return l
    const next = { ...l, [key]: val }
    if (key === 'productId') next.rate = productMap[val]?.price || 0
    return next
  }))
  const delLine = (i) => setLines(lines.filter((_, idx) => idx !== i))

  const preview = orderTotals(lines, productMap)

  const save = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    const items = lines.map((l) => ({ productId: l.productId, qty: +l.qty, rate: +l.rate }))
    const dispatch = String(f.get('dispatch'))
    const record = {
      id: edit.id, customerId: f.get('customerId'), date: f.get('date'),
      salesperson: f.get('salesperson'), dispatch, payStatus: f.get('payStatus'), items,
    }
    const existing = sales.find((s) => s.id === edit.id)
    upsert('sales', record)

    // Business logic: on first dispatch (Loaded+), reduce finished-goods stock
    const stockStages = ['Loaded', 'In Transit', 'Delivered']
    const wasShipped = existing && stockStages.includes(existing.dispatch)
    const nowShipped = stockStages.includes(dispatch)
    if (nowShipped && !wasShipped) {
      items.forEach((it) => {
        const p = products.find((x) => x.id === it.productId)
        if (p) upsert('products', { ...p, stock: Math.max(0, p.stock - it.qty) })
      })
    }
    // Business logic: new credit order raises customer outstanding
    if (!existing && f.get('payStatus') !== 'Paid') {
      const c = customers.find((x) => x.id === record.customerId)
      if (c) upsert('customers', { ...c, outstanding: c.outstanding + orderTotals(items, productMap).total })
    }
    setEdit(null)
  }

  return (
    <div className="page">
      <PageHeader title="Sales" subtitle="Dealer, distributor, wholesale & retail orders with auto GST and dispatch tracking.">
        <button className="btn" onClick={() => csvExport('sales.csv', rows.map((r) => ({ id: r.id, customer: r.customer?.name, date: r.date, total: Math.round(r.total), dispatch: r.dispatch, payStatus: r.payStatus })))}><Icon name="download" /> GST Sales Report</button>
        <button className="btn btn-gold" onClick={openNew}><Icon name="plus" /> New Sales Order</button>
      </PageHeader>

      <div className="stat-grid">
        <StatCard icon="sales" tone="green" label="Sales (period)" value={inrShort(totalSales)} delta={`${sales.length} orders`} deltaDir="up" />
        <StatCard icon="reports" tone="gold" label="Est. Profit" value={inrShort(totalProfit)} delta="on these orders" deltaDir="up" />
        <StatCard icon="truck" tone="purple" label="Pending Dispatch" value={`${pending} orders`} delta="to ship" deltaDir="flat" />
        <StatCard icon="rupee" tone="red" label="Payment Pending" value={`${sales.filter((s) => s.payStatus !== 'Paid').length} orders`} delta="follow up" deltaDir="down" />
      </div>

      <Toolbar search={q} onSearch={setQ} placeholder="Search order or customer…">
        <select className="sel" value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="all">All Dispatch Status</option>
          {DISPATCH_STAGES.map((s) => <option key={s}>{s}</option>)}
        </select>
      </Toolbar>

      <div className="card table-wrap">
        <table className="tbl">
          <thead><tr>
            <th>Order No</th><th>Customer</th><th>Date</th><th className="num">Items</th>
            <th className="num">Sub Total</th><th className="num">GST</th><th className="num">Total</th>
            <th>Dispatch</th><th>Payment</th><th></th>
          </tr></thead>
          <tbody>
            {rows.map((so) => (
              <tr key={so.id}>
                <td className="cell-strong">{so.id}</td>
                <td><div className="cell-strong">{so.customer?.name}</div><div className="cell-sub">{so.customer?.type} · {so.customer?.area}</div></td>
                <td className="muted">{fmtDate(so.date)}</td>
                <td className="num">{so.items.length}</td>
                <td className="num muted">{inr(so.sub)}</td>
                <td className="num muted">{inr(so.tax)}</td>
                <td className="num cell-strong">{inr(so.total)}</td>
                <td><Badge tone={DISPATCH_COLORS[so.dispatch]} noDot>{so.dispatch}</Badge></td>
                <td><Badge tone={PAY_COLORS[so.payStatus]} noDot>{so.payStatus}</Badge></td>
                <td><div className="row-actions">
                  <button onClick={() => openEdit(so)}><Icon name="edit" size={15} /></button>
                  <button className="del" onClick={() => window.confirm('Delete order?') && remove('sales', so.id)}><Icon name="trash" size={15} /></button>
                </div></td>
              </tr>
            ))}
          </tbody>
        </table>
        {!rows.length && <EmptyState icon="sales" text="No sales orders" />}
      </div>

      {edit && (
        <Modal lg title={sales.some((s) => s.id === edit.id) ? `Edit ${edit.id}` : 'New Sales Order'} onClose={() => setEdit(null)}
          footer={<>
            <div style={{ marginRight: 'auto', fontSize: 13 }}>
              <span className="muted">Sub {inr(preview.sub)} · GST {inr(preview.tax)} · </span>
              <b style={{ fontSize: 15 }}>Total {inr(preview.total)}</b>
            </div>
            <button className="btn" onClick={() => setEdit(null)}>Cancel</button>
            <button className="btn btn-primary" form="soForm">Save Order</button>
          </>}>
          <form id="soForm" onSubmit={save}>
            <div className="form-grid" style={{ marginBottom: 18 }}>
              <Field label="Customer / Dealer"><select className="sel" name="customerId" defaultValue={edit.customerId}>{customers.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select></Field>
              <Field label="Order Date"><input className="inp" type="date" name="date" defaultValue={edit.date} /></Field>
              <Field label="Salesperson"><input className="inp" name="salesperson" defaultValue={edit.salesperson} /></Field>
              <Field label="Dispatch Status"><select className="sel" name="dispatch" defaultValue={edit.dispatch}>{DISPATCH_STAGES.map((s) => <option key={s}>{s}</option>)}</select></Field>
              <Field label="Payment Status"><select className="sel" name="payStatus" defaultValue={edit.payStatus}><option>Pending</option><option>Partial</option><option>Paid</option></select></Field>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
              <label style={{ fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.5px', color: 'var(--text-3)' }}>Order Items</label>
              <button type="button" className="btn btn-sm" onClick={addLine}><Icon name="plus" size={14} /> Add Item</button>
            </div>
            <div className="table-wrap" style={{ border: '1px solid var(--border)', borderRadius: 10 }}>
              <table className="tbl">
                <thead><tr><th>Product</th><th className="num">Qty</th><th className="num">Rate</th><th>GST</th><th className="num">Amount</th><th></th></tr></thead>
                <tbody>
                  {lines.map((l, i) => {
                    const p = productMap[l.productId]
                    const amt = l.qty * l.rate
                    return (
                      <tr key={i}>
                        <td><select className="sel" style={{ width: '100%' }} value={l.productId} onChange={(e) => setLine(i, 'productId', e.target.value)}>{products.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}</select></td>
                        <td className="num"><input className="inp" type="number" style={{ width: 70 }} value={l.qty} onChange={(e) => setLine(i, 'qty', e.target.value)} /></td>
                        <td className="num"><input className="inp" type="number" style={{ width: 90 }} value={l.rate} onChange={(e) => setLine(i, 'rate', e.target.value)} /></td>
                        <td><Badge tone="gray" noDot>{p?.gst || 0}%</Badge></td>
                        <td className="num cell-strong">{inr(amt)}</td>
                        <td><button type="button" className="row-actions" onClick={() => delLine(i)} style={{ border: 0, background: 'none', color: 'var(--red)' }}><Icon name="trash" size={15} /></button></td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}
