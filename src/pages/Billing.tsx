import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Badge, Modal, Field, StatCard, Card } from '../components/ui'
import Icon from '../components/Icon'
import { inr, inrShort, fmtDate, csvExport, uid, todayISO, orderTotals, PAY_COLORS } from '../utils/helpers'
import { buildInvoiceHTML, printInvoice, invoiceNo } from '../utils/invoice'

export default function Billing() {
  const { sales, customers, products, customerMap, productMap, metrics, expenses, company, upsert, remove } = useData()
  const [tab, setTab] = useState('invoices')
  const [q, setQ] = useState('')
  const [pay, setPay] = useState(null)
  const [exp, setExp] = useState(null)
  const [inv, setInv] = useState<any>(null)   // new-invoice draft
  const [lines, setLines] = useState<any[]>([])

  // ---- New invoice (creates a sales order, the invoice source) ----
  const openInvoice = () => {
    setLines([{ productId: products[0]?.id, qty: 1, rate: products[0]?.price || 0 }])
    setInv({ id: uid('SO'), customerId: customers[0]?.id, date: todayISO(), payStatus: 'Pending' })
  }
  const addLine = () => setLines([...lines, { productId: products[0]?.id, qty: 1, rate: products[0]?.price || 0 }])
  const setLine = (i, key, val) => setLines(lines.map((l, idx) => {
    if (idx !== i) return l
    const next = { ...l, [key]: val }
    if (key === 'productId') next.rate = productMap[val]?.price || 0
    return next
  }))
  const delLine = (i) => setLines(lines.filter((_, idx) => idx !== i))
  const invPreview = orderTotals(lines, productMap)

  const saveInvoice = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    const items = lines.map((l) => ({ productId: l.productId, qty: +l.qty, rate: +l.rate }))
    const record = {
      id: inv.id, customerId: f.get('customerId'), date: f.get('date'),
      salesperson: 'Billing', dispatch: 'Order Received', payStatus: f.get('payStatus'), items,
    }
    upsert('sales', record)
    // credit invoice raises customer outstanding
    if (record.payStatus !== 'Paid') {
      const c = customers.find((x) => x.id === record.customerId)
      if (c) upsert('customers', { ...c, outstanding: c.outstanding + orderTotals(items, productMap).total })
    }
    setInv(null)
  }

  // ---- Print / Save-as-PDF a GST tax invoice ----
  const printOne = (i) => printInvoice(buildInvoiceHTML({
    id: i.id, date: i.date, payStatus: i.payStatus, items: i.items,
    customer: customerMap[i.customerId], productMap, company,
  }))

  const invoices = useMemo(() => sales.map((so) => {
    const t = orderTotals(so.items, productMap)
    return { ...so, ...t, customer: customerMap[so.customerId] }
  }).filter((i) => !q || `${i.id} ${i.customer?.name}`.toLowerCase().includes(q.toLowerCase())), [sales, productMap, customerMap, q])

  const totalInvoiced = invoices.reduce((s, i) => s + i.total, 0)
  const received = invoices.filter((i) => i.payStatus === 'Paid').reduce((s, i) => s + i.total, 0)
  const totalGST = invoices.reduce((s, i) => s + i.tax, 0)
  const totalExpense = expenses.reduce((s, e) => s + e.amount, 0)
  const netProfit = metrics.totalProfit - totalExpense

  // record payment → mark paid + reduce customer outstanding
  const savePay = (e) => {
    e.preventDefault()
    const so = pay
    upsert('sales', { ...so, payStatus: 'Paid' })
    const c = customers.find((x) => x.id === so.customerId)
    const t = orderTotals(so.items, productMap).total
    if (c) upsert('customers', { ...c, outstanding: Math.max(0, c.outstanding - t) })
    setPay(null)
  }

  const saveExp = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    upsert('expenses', { id: exp.id, date: f.get('date'), head: f.get('head'), note: f.get('note'), amount: +f.get('amount') })
    setExp(null)
  }

  return (
    <div className="page">
      <PageHeader title="Billing & Accounts" subtitle="GST invoices, payments, expenses and profit & loss overview.">
        <button className="btn" onClick={() => csvExport('invoices.csv', invoices.map((i) => ({ id: invoiceNo(i.id), customer: i.customer?.name, date: i.date, sub: Math.round(i.sub), gst: Math.round(i.tax), total: Math.round(i.total), status: i.payStatus })))}><Icon name="download" /> Tally Export</button>
        <button className="btn" onClick={() => setExp({ id: uid('EXP'), date: todayISO(), head: 'Transport', note: '', amount: 0 })}><Icon name="plus" /> Add Expense</button>
        <button className="btn btn-gold" onClick={openInvoice}><Icon name="plus" /> New Invoice</button>
      </PageHeader>

      <div className="stat-grid">
        <StatCard icon="billing" tone="gold" label="Total Invoiced" value={inrShort(totalInvoiced)} delta={`${invoices.length} invoices`} deltaDir="flat" />
        <StatCard icon="rupee" tone="green" label="Payment Received" value={inrShort(received)} delta="cleared" deltaDir="up" />
        <StatCard icon="rupee" tone="red" label="Customer Outstanding" value={inrShort(metrics.customerOutstanding)} delta="receivable" deltaDir="down" />
        <StatCard icon="reports" tone="teal" label="GST Collected" value={inrShort(totalGST)} delta="output tax" deltaDir="flat" />
      </div>

      {/* P&L mini */}
      <div className="grid-2 mb-16">
        <Card title="Profit & Loss Overview" sub="Period snapshot">
          <div className="card-pad">
            <div className="kv"><span className="k">Sales Revenue</span><span className="v">{inr(metrics.totalRevenue)}</span></div>
            <div className="kv"><span className="k">Cost of Goods (purchase + production)</span><span className="v">{inr(metrics.totalRevenue - metrics.totalProfit)}</span></div>
            <div className="kv"><span className="k">Gross Profit</span><span className="v" style={{ color: 'var(--green)' }}>{inr(metrics.totalProfit)}</span></div>
            <div className="kv"><span className="k">Operating Expenses</span><span className="v" style={{ color: 'var(--red)' }}>− {inr(totalExpense)}</span></div>
            <div className="kv" style={{ borderTop: '2px solid var(--border)', marginTop: 4, paddingTop: 12 }}>
              <span className="k" style={{ fontWeight: 700, color: 'var(--text)' }}>Net Profit</span>
              <span className="v" style={{ fontSize: 17, color: netProfit >= 0 ? 'var(--green)' : 'var(--red)' }}>{inr(netProfit)}</span>
            </div>
          </div>
        </Card>
        <Card title="Expense Breakdown" sub="By head">
          <div className="card-pad">
            {Object.entries(expenses.reduce((acc: Record<string, number>, e: any) => { acc[e.head] = (acc[e.head] || 0) + e.amount; return acc }, {} as Record<string, number>))
              .sort((a, b) => (b[1] as number) - (a[1] as number)).map(([head, amt]) => {
                const numAmt = Number(amt) || 0
                const pct = totalExpense ? (numAmt / totalExpense) * 100 : 0
                return (
                  <div key={head} style={{ marginBottom: 13 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 5 }}>
                      <span style={{ fontWeight: 600 }}>{head}</span><span className="muted">{inr(numAmt)}</span>
                    </div>
                    <div className="bar"><span style={{ width: `${pct}%` }} /></div>
                  </div>
                )
              })}
          </div>
        </Card>
      </div>

      <div className="toolbar">
        <div className="pill-tabs">
          <button className={tab === 'invoices' ? 'active' : ''} onClick={() => setTab('invoices')}>Invoices</button>
          <button className={tab === 'expenses' ? 'active' : ''} onClick={() => setTab('expenses')}>Expenses</button>
        </div>
        {tab === 'invoices' && <div className="field-search" style={{ marginLeft: 'auto' }}><Icon name="search" size={16} style={{ color: 'var(--text-3)' }} /><input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search invoice…" /></div>}
      </div>

      <div className="card table-wrap">
        {tab === 'invoices' ? (
          <table className="tbl">
            <thead><tr><th>Invoice No</th><th>Customer</th><th>Date</th><th className="num">Taxable</th><th className="num">GST</th><th className="num">Total</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {invoices.map((i) => (
                <tr key={i.id}>
                  <td className="cell-strong">{invoiceNo(i.id)}</td>
                  <td>{i.customer?.name}</td>
                  <td className="muted">{fmtDate(i.date)}</td>
                  <td className="num muted">{inr(i.sub)}</td>
                  <td className="num muted">{inr(i.tax)}</td>
                  <td className="num cell-strong">{inr(i.total)}</td>
                  <td><Badge tone={PAY_COLORS[i.payStatus]} noDot>{i.payStatus}</Badge></td>
                  <td><div className="row-actions">
                    {i.payStatus !== 'Paid' && <button title="Record payment" onClick={() => setPay(i)} style={{ color: 'var(--green)' }}><Icon name="check" size={16} /></button>}
                    <button title="Print / Save PDF" onClick={() => printOne(i)}><Icon name="download" size={15} /></button>
                  </div></td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <table className="tbl">
            <thead><tr><th>Voucher</th><th>Head</th><th>Note</th><th>Date</th><th className="num">Amount</th><th></th></tr></thead>
            <tbody>
              {expenses.map((e) => (
                <tr key={e.id}>
                  <td className="cell-strong">{e.id}</td>
                  <td><Badge tone="gray" noDot>{e.head}</Badge></td>
                  <td className="muted">{e.note}</td>
                  <td className="muted">{fmtDate(e.date)}</td>
                  <td className="num cell-strong">{inr(e.amount)}</td>
                  <td><div className="row-actions">
                    <button onClick={() => setExp(e)}><Icon name="edit" size={15} /></button>
                    <button className="del" onClick={() => window.confirm('Delete expense?') && remove('expenses', e.id)}><Icon name="trash" size={15} /></button>
                  </div></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {pay && (
        <Modal title={`Record Payment · INV-${pay.id.replace('SO-', '')}`} onClose={() => setPay(null)}
          footer={<><button className="btn" onClick={() => setPay(null)}>Cancel</button><button className="btn btn-primary" form="payForm">Confirm Payment</button></>}>
          <form id="payForm" onSubmit={savePay}>
            <div className="kv"><span className="k">Customer</span><span className="v">{pay.customer?.name}</span></div>
            <div className="kv"><span className="k">Invoice Total</span><span className="v">{inr(pay.total)}</span></div>
            <div className="kv"><span className="k">Current Outstanding</span><span className="v">{inr(pay.customer?.outstanding || 0)}</span></div>
            <p className="tiny" style={{ marginTop: 12 }}>Confirming marks this invoice <b>Paid</b> and reduces the customer's outstanding balance.</p>
          </form>
        </Modal>
      )}

      {exp && (
        <Modal title={expenses.some((x) => x.id === exp.id) ? 'Edit Expense' : 'Add Expense'} onClose={() => setExp(null)}
          footer={<><button className="btn" onClick={() => setExp(null)}>Cancel</button><button className="btn btn-primary" form="expForm">Save Expense</button></>}>
          <form id="expForm" onSubmit={saveExp} className="form-grid">
            <Field label="Expense Head"><select className="sel" name="head" defaultValue={exp.head}><option>Transport</option><option>Labour</option><option>Electricity</option><option>Maintenance</option><option>Production</option><option>Misc</option></select></Field>
            <Field label="Date"><input className="inp" type="date" name="date" defaultValue={exp.date} /></Field>
            <Field label="Amount"><input className="inp" type="number" name="amount" defaultValue={exp.amount} /></Field>
            <Field label="Note" full><input className="inp" name="note" defaultValue={exp.note} /></Field>
          </form>
        </Modal>
      )}

      {inv && (
        <Modal lg title={`New Invoice · ${invoiceNo(inv.id)}`} onClose={() => setInv(null)}
          footer={<>
            <div style={{ marginRight: 'auto', fontSize: 13 }}>
              <span className="muted">Taxable {inr(invPreview.sub)} · GST {inr(invPreview.tax)} · </span>
              <b style={{ fontSize: 15 }}>Total {inr(invPreview.total)}</b>
            </div>
            <button className="btn" onClick={() => setInv(null)}>Cancel</button>
            <button className="btn btn-primary" form="invForm">Create Invoice</button>
          </>}>
          <form id="invForm" onSubmit={saveInvoice}>
            <div className="form-grid" style={{ marginBottom: 18 }}>
              <Field label="Bill To / Customer"><select className="sel" name="customerId" defaultValue={inv.customerId}>{customers.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</select></Field>
              <Field label="Invoice Date"><input className="inp" type="date" name="date" defaultValue={inv.date} /></Field>
              <Field label="Payment Status"><select className="sel" name="payStatus" defaultValue={inv.payStatus}><option>Pending</option><option>Partial</option><option>Paid</option></select></Field>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
              <label style={{ fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.5px', color: 'var(--text-3)' }}>Invoice Items</label>
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
            <p className="tiny" style={{ marginTop: 12 }}>Creating saves a GST sales invoice. Use the <b>Print</b> action in the invoice list to generate a printable / PDF tax invoice.</p>
          </form>
        </Modal>
      )}
    </div>
  )
}
