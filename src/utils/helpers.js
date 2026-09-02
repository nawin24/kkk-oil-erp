// ============================================================
// Formatting + business-logic helpers
// ============================================================

export const inr = (n) => {
  if (n == null || isNaN(n)) return '₹0'
  const v = Math.round(n)
  return '₹' + v.toLocaleString('en-IN')
}

// Compact Indian currency: ₹1.2L, ₹3.4Cr
export const inrShort = (n) => {
  const v = Math.abs(n || 0)
  const sign = n < 0 ? '-' : ''
  if (v >= 1e7) return `${sign}₹${(v / 1e7).toFixed(2)} Cr`
  if (v >= 1e5) return `${sign}₹${(v / 1e5).toFixed(2)} L`
  if (v >= 1e3) return `${sign}₹${(v / 1e3).toFixed(1)} K`
  return `${sign}₹${Math.round(v)}`
}

export const num = (n) => (n || 0).toLocaleString('en-IN')

export const fmtDate = (d) => {
  if (!d) return '—'
  const dt = new Date(d)
  return dt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
}

export const todayISO = () => new Date().toISOString().slice(0, 10)

// GST split for an order line
export const lineTotal = (qty, rate, gst = 0, discount = 0) => {
  const gross = qty * rate
  const afterDisc = gross - discount
  const tax = afterDisc * (gst / 100)
  return { gross, afterDisc, tax, total: afterDisc + tax }
}

// Total of a sales order (items array of {productId, qty, rate}) given product lookup
export const orderTotals = (items, productMap) => {
  let sub = 0, tax = 0
  items.forEach((it) => {
    const p = productMap[it.productId]
    const gst = p ? p.gst : 0
    const t = lineTotal(it.qty, it.rate, gst)
    sub += t.afterDisc
    tax += t.tax
  })
  return { sub, tax, total: sub + tax }
}

// Estimated profit on a sales order using product cost
export const orderProfit = (items, productMap) => {
  let revenue = 0, cost = 0
  items.forEach((it) => {
    const p = productMap[it.productId]
    revenue += it.qty * it.rate
    cost += it.qty * (p ? p.cost : 0)
  })
  return revenue - cost
}

export const monthKey = (d) => new Date(d).toISOString().slice(0, 7)

export const isSameDay = (a, b) =>
  new Date(a).toDateString() === new Date(b).toDateString()

// Status → badge color mapping
export const DISPATCH_COLORS = {
  'Order Received': 'gray',
  'Packing Pending': 'amber',
  'Ready for Dispatch': 'blue',
  'Loaded': 'purple',
  'In Transit': 'teal',
  'Delivered': 'green',
  'Payment Collected': 'green',
  'Returned': 'red',
}
export const PAY_COLORS = { Paid: 'green', Partial: 'amber', Pending: 'red', Unpaid: 'red' }
export const QC_COLORS = { Passed: 'green', Pending: 'amber', Failed: 'red' }
export const PROD_COLORS = { Completed: 'green', 'In Progress': 'blue', Planned: 'amber' }

export const uid = (prefix) => `${prefix}-${Math.floor(1000 + Math.random() * 9000)}`

export const csvExport = (filename, rows) => {
  if (!rows || !rows.length) return
  const headers = Object.keys(rows[0])
  const escape = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`
  const csv = [headers.join(','), ...rows.map((r) => headers.map((h) => escape(r[h])).join(','))].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}
