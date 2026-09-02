import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { useAuth } from '../context/AuthContext'
import { PageHeader, EmptyState } from '../components/ui'
import Icon from '../components/Icon'
import { inr, uid, todayISO, lineTotal } from '../utils/helpers'
import { buildInvoiceHTML, printInvoice, invoiceNo } from '../utils/invoice'

const PAY_MODES = ['Cash', 'UPI', 'Card', 'Credit']

export default function Counter() {
  const { products, customers, customerMap, productMap, company, upsert } = useData()
  const { user } = useAuth()

  const [q, setQ] = useState('')
  const [customerId, setCustomerId] = useState('')     // '' = walk-in / cash
  const [mode, setMode] = useState('Cash')
  const [cart, setCart] = useState<Record<string, number>>({})   // productId -> qty
  const [toast, setToast] = useState('')

  const shown = useMemo(() => {
    const term = q.trim().toLowerCase()
    return products.filter((p) =>
      !term || `${p.name} ${p.sku} ${p.oilType}`.toLowerCase().includes(term))
  }, [products, q])

  const addItem = (id: string) => setCart((c) => ({ ...c, [id]: (c[id] || 0) + 1 }))
  const setQty = (id: string, qty: number) => setCart((c) => {
    const next = { ...c }
    if (qty <= 0) delete next[id]
    else next[id] = qty
    return next
  })

  const lines = useMemo(() => Object.entries(cart).map(([id, qty]) => {
    const p = productMap[id]
    const t = lineTotal(qty, p?.price || 0, p?.gst || 0)
    return { id, product: p, qty, rate: p?.price || 0, gst: p?.gst || 0, taxable: t.afterDisc, tax: t.tax, amount: t.total }
  }), [cart, productMap])

  const sub = lines.reduce((s, l) => s + l.taxable, 0)
  const tax = lines.reduce((s, l) => s + l.tax, 0)
  const grand = sub + tax
  const payable = Math.round(grand)
  const count = lines.reduce((s, l) => s + l.qty, 0)

  const clear = () => { setCart({}); setCustomerId(''); setMode('Cash') }

  const buildRecord = () => {
    const items = lines.map((l) => ({ productId: l.id, qty: l.qty, rate: l.rate }))
    const paid = mode !== 'Credit'
    const id = uid('SO')
    return {
      id,
      voucherNo: id,
      billingType: 'GST',
      pricingType: 'RETAIL',
      customerId: customerId || 'CASH-WALKIN',
      date: todayISO(),
      salesperson: user?.name || 'Counter',
      userId: user?.id || 'cashier',
      userName: user?.name || 'Cashier',
      userRole: user?.role || 'cashier',
      dispatch: 'Delivered',
      payStatus: paid ? 'Paid' : 'Pending',
      payMode: mode,
      items,
      grandTotal: payable,
      status: 'ACTIVE',
    }
  }

  // Persist the bill: save sale, reduce finished stock, raise outstanding on credit.
  const commit = (record: any) => {
    upsert('sales', record)
    record.items.forEach((it: any) => {
      const p = products.find((x) => x.id === it.productId)
      if (p) upsert('products', { ...p, stock: Math.max(0, p.stock - it.qty) })
    })
    if (record.payStatus !== 'Paid' && record.customerId) {
      const c = customers.find((x) => x.id === record.customerId)
      if (c) upsert('customers', { ...c, outstanding: (c.outstanding || 0) + payable })
    }
  }

  const validate = () => {
    if (!lines.length) { setToast('Add at least one product.'); return false }
    if (mode === 'Credit' && !customerId) { setToast('Credit bills need a customer — pick one or choose Cash/UPI/Card.'); return false }
    return true
  }

  const save = (andPrint: boolean) => {
    if (!validate()) return
    const record = buildRecord()
    commit(record)
    if (andPrint) {
      printInvoice(buildInvoiceHTML({
        id: record.id, date: record.date, payStatus: record.payStatus,
        items: record.items, customer: customerMap[customerId], productMap, company,
      }))
    }
    setToast(`Bill ${invoiceNo(record.id)} saved${andPrint ? ' — opening print…' : ''} · ${inr(payable)}`)
    clear()
  }

  return (
    <div className="page">
      <PageHeader title="Billing Counter" subtitle="Fast GST billing — add products, take payment, print the tax invoice.">
        <span className="badge gray no-dot" style={{ fontSize: 12 }}>{company?.name}</span>
      </PageHeader>

      <div className="counter-grid">
        {/* -------- Product picker -------- */}
        <div className="card" style={{ padding: 16, display: 'flex', flexDirection: 'column', minHeight: 420 }}>
          <div className="field-search" style={{ marginBottom: 14 }}>
            <Icon name="search" size={16} style={{ color: 'var(--text-3)' }} />
            <input autoFocus value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search product, SKU or oil type…" />
          </div>
          {products.length === 0 ? (
            <EmptyState icon="products" text="No products yet. Add products in the Products module first." />
          ) : (
            <div className="prod-picker">
              {shown.map((p) => (
                <button key={p.id} className="prod-btn" onClick={() => addItem(p.id)} title={`Add ${p.name}`}>
                  <div className="pb-name">{p.name}</div>
                  <div className="pb-meta">
                    <span className="pb-price">{inr(p.price)}</span>
                    <span className={`pb-stock ${p.stock <= p.minStock ? 'low' : ''}`}>{p.stock} in stock</span>
                  </div>
                </button>
              ))}
              {!shown.length && <EmptyState icon="search" text="No product matches your search." />}
            </div>
          )}
        </div>

        {/* -------- Bill / cart -------- */}
        <div className="card bill-panel">
          <div className="bill-head">
            <h4>Current Bill</h4>
            <span className="muted">{count} item{count === 1 ? '' : 's'}</span>
          </div>

          <div className="bill-cust">
            <select className="sel" value={customerId} onChange={(e) => setCustomerId(e.target.value)}>
              <option value="">Walk-in / Cash customer</option>
              {customers.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>

          <div className="bill-lines">
            {!lines.length && <div className="bill-empty"><Icon name="billing" size={30} /><span>No items yet — click a product to add it.</span></div>}
            {lines.map((l) => (
              <div key={l.id} className="bill-line">
                <div className="bl-info">
                  <div className="bl-name">{l.product?.name || l.id}</div>
                  <div className="bl-sub">{inr(l.rate)} · GST {l.gst}%</div>
                </div>
                <div className="qty-step">
                  <button onClick={() => setQty(l.id, l.qty - 1)} aria-label="decrease">−</button>
                  <input value={l.qty} onChange={(e) => setQty(l.id, Math.max(0, parseInt(e.target.value) || 0))} />
                  <button onClick={() => setQty(l.id, l.qty + 1)} aria-label="increase">+</button>
                </div>
                <div className="bl-amt">{inr(l.amount)}</div>
                <button className="bl-del" onClick={() => setQty(l.id, 0)} aria-label="remove"><Icon name="trash" size={15} /></button>
              </div>
            ))}
          </div>

          <div className="bill-totals">
            <div className="kv"><span className="k">Taxable</span><span className="v">{inr(sub)}</span></div>
            <div className="kv"><span className="k">GST</span><span className="v">{inr(tax)}</span></div>
            <div className="kv grand"><span className="k">Total Payable</span><span className="v">{inr(payable)}</span></div>
          </div>

          <div className="pay-modes">
            {PAY_MODES.map((m) => (
              <button key={m} className={`pay-opt ${mode === m ? 'active' : ''}`} onClick={() => setMode(m)}>{m}</button>
            ))}
          </div>

          {toast && <div className="bill-toast">{toast}</div>}

          <div className="bill-actions">
            <button className="btn" onClick={clear} disabled={!lines.length && !customerId}>Clear</button>
            <button className="btn btn-primary" onClick={() => save(false)} disabled={!lines.length}>Save</button>
            <button className="btn btn-gold" onClick={() => save(true)} disabled={!lines.length}><Icon name="download" size={15} /> Save &amp; Print</button>
          </div>
        </div>
      </div>
    </div>
  )
}
