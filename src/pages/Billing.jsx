import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext.jsx'
import { PageHeader, Badge, Modal, Field, StatCard, Card, Toolbar, EmptyState } from '../components/ui.jsx'
import Icon from '../components/Icon.jsx'
import { inr, inrShort, fmtDate, csvExport, uid, todayISO, orderTotals, PAY_COLORS } from '../utils/helpers.js'

export default function Billing() {
  const { sales, customers, customerMap, productMap, metrics, expenses, upsert, remove } = useData()
  const [tab, setTab] = useState('invoices')
  const [q, setQ] = useState('')
  const [pay, setPay] = useState(null)
  const [exp, setExp] = useState(null)

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
        <button className="btn" onClick={() => csvExport('invoices.csv', invoices.map((i) => ({ id: i.id, customer: i.customer?.name, date: i.date, sub: Math.round(i.sub), gst: Math.round(i.tax), total: Math.round(i.total), status: i.payStatus })))}><Icon name="download" /> Tally Export</button>
        <button className="btn btn-gold" onClick={() => setExp({ id: uid('EXP'), date: todayISO(), head: 'Transport', note: '', amount: 0 })}><Icon name="plus" /> Add Expense</button>
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
            {Object.entries(expenses.reduce((acc, e) => { acc[e.head] = (acc[e.head] || 0) + e.amount; return acc }, {}))
              .sort((a, b) => b[1] - a[1]).map(([head, amt]) => {
                const pct = totalExpense ? (amt / totalExpense) * 100 : 0
                return (
                  <div key={head} style={{ marginBottom: 13 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 5 }}>
                      <span style={{ fontWeight: 600 }}>{head}</span><span className="muted">{inr(amt)}</span>
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
                  <td className="cell-strong">INV-{i.id.replace('SO-', '')}</td>
                  <td>{i.customer?.name}</td>
                  <td className="muted">{fmtDate(i.date)}</td>
                  <td className="num muted">{inr(i.sub)}</td>
                  <td className="num muted">{inr(i.tax)}</td>
                  <td className="num cell-strong">{inr(i.total)}</td>
                  <td><Badge tone={PAY_COLORS[i.payStatus]} noDot>{i.payStatus}</Badge></td>
                  <td><div className="row-actions">
                    {i.payStatus !== 'Paid' && <button title="Record payment" onClick={() => setPay(i)} style={{ color: 'var(--green)' }}><Icon name="check" size={16} /></button>}
                    <button title="Download PDF" onClick={() => alert(`Generating PDF for INV-${i.id.replace('SO-', '')}`)}><Icon name="download" size={15} /></button>
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
    </div>
  )
}
