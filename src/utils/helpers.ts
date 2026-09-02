// ============================================================
// Formatting + business-logic helpers
// ============================================================

export const inr = (n: number | null | undefined) => {
  if (n == null || isNaN(n)) return '₹0'
  const v = Math.round(n)
  return '₹' + v.toLocaleString('en-IN')
}

// Compact Indian currency: ₹1.2L, ₹3.4Cr
export const inrShort = (n: number) => {
  const v = Math.abs(n || 0)
  const sign = n < 0 ? '-' : ''
  if (v >= 1e7) return `${sign}₹${(v / 1e7).toFixed(2)} Cr`
  if (v >= 1e5) return `${sign}₹${(v / 1e5).toFixed(2)} L`
  if (v >= 1e3) return `${sign}₹${(v / 1e3).toFixed(1)} K`
  return `${sign}₹${Math.round(v)}`
}

export const num = (n: number) => (n || 0).toLocaleString('en-IN')

export const fmtDate = (d: string | Date | undefined) => {
  if (!d) return '—'
  const dt = new Date(d)
  return dt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
}

export const todayISO = () => new Date().toISOString().slice(0, 10)
export const currentTimeStr = () => new Date().toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true })

// Returns the active selling rate for a product based on AWR type, date, and price history
export const getEffectiveProductRate = (
  product: any,
  pricingType: 'AGENCY' | 'WHOLESALE' | 'RETAIL' = 'RETAIL',
  dateISO: string = todayISO(),
  priceHistory: any[] = []
): number => {
  if (!product) return 0

  // 1. Check if there is a price history record for this product & pricing type effective on or before dateISO
  if (priceHistory && priceHistory.length > 0) {
    const records = priceHistory.filter(
      (h) => h.productId === product.id && h.pricingType === pricingType && h.effectiveDate <= dateISO
    ).sort((a, b) => (b.effectiveDate + (b.effectiveTime || '')).localeCompare(a.effectiveDate + (a.effectiveTime || '')))

    if (records.length > 0) {
      return records[0].newRate
    }
  }

  // 2. Fallback to product master rates
  if (pricingType === 'AGENCY') return product.agencyRate ?? product.price ?? 0
  if (pricingType === 'WHOLESALE') return product.wholesaleRate ?? product.price ?? 0
  return product.retailRate ?? product.price ?? 0
}

// GST split for an order line
export const lineTotal = (
  qty: number,
  rate: number,
  gst: number = 0,
  discountPercent: number = 0,
  discountAmt: number = 0,
  isGstEnabled: boolean = true
) => {
  const gross = qty * rate
  const calcDisc = discountAmt > 0 ? discountAmt : gross * (discountPercent / 100)
  const afterDisc = Math.max(0, gross - calcDisc)
  const tax = isGstEnabled ? afterDisc * (gst / 100) : 0
  return { gross, discount: calcDisc, afterDisc, taxRate: isGstEnabled ? gst : 0, tax, total: afterDisc + tax }
}

// Centralized tax & ledger calculation for GST vs Non-GST billing
export const calculateBillTotals = (
  rawLines: any[],
  productMap: Record<string, any>,
  pricingType: 'AGENCY' | 'WHOLESALE' | 'RETAIL' = 'RETAIL',
  billingType: 'GST' | 'NON_GST' = 'GST',
  dateISO: string = todayISO(),
  priceHistory: any[] = [],
  companyStateCode: string = '33',
  customerStateCode: string = '33'
) => {
  const isGst = billingType === 'GST'
  let subtotal = 0
  let totalDiscount = 0
  let totalGst = 0
  const gstBreakdown: Record<number, number> = {}

  const items = rawLines.map((line) => {
    const p = productMap[line.productId] || {}
    const qty = Number(line.qty) || 0
    const appliedRate = line.appliedRate ?? getEffectiveProductRate(p, pricingType, dateISO, priceHistory)
    const discPercent = Number(line.discPercent) || 0
    const discAmount = Number(line.discAmount) || 0
    const schemeAmt = Number(line.schemeAmount) || 0

    const t = lineTotal(qty, appliedRate, p.gst || 0, discPercent, discAmount, isGst)
    const taxableAmount = Math.max(0, t.afterDisc - schemeAmt)
    const gstRate = isGst ? (p.gst || 0) : 0
    const gstAmount = isGst ? taxableAmount * (gstRate / 100) : 0
    const finalAmount = taxableAmount + gstAmount

    subtotal += t.gross
    totalDiscount += t.discount + schemeAmt
    totalGst += gstAmount

    if (isGst && gstRate > 0) {
      gstBreakdown[gstRate] = (gstBreakdown[gstRate] || 0) + gstAmount
    }

    return {
      productId: line.productId,
      productCode: p.code || p.sku || line.productId,
      productName: p.name || 'Unknown Product',
      unit: p.unit || 'Bottle',
      qty,
      rate: appliedRate,
      mrp: p.mrp || appliedRate,
      pricingType,
      appliedRate,
      discPercent,
      discAmount: t.discount,
      schemeAmount: schemeAmt,
      taxableAmount,
      gstRate,
      gstAmount,
      finalAmount,
    }
  })

  const rawGrandTotal = items.reduce((s, it) => s + it.finalAmount, 0)
  const grandTotal = Math.round(rawGrandTotal)
  const roundOff = Number((grandTotal - rawGrandTotal).toFixed(2))

  // Build Ledger Entries
  const ledgerEntries: { ledgerName: string; amount: number }[] = []
  if (isGst && totalGst > 0) {
    const isInterState = companyStateCode !== customerStateCode
    Object.entries(gstBreakdown).forEach(([rateStr, amt]) => {
      const rate = Number(rateStr)
      if (isInterState) {
        ledgerEntries.push({ ledgerName: `OUTPUT IGST ON SALES (GST ${rate}%)`, amount: Number(amt.toFixed(2)) })
      } else {
        const half = Number((amt / 2).toFixed(2))
        ledgerEntries.push({ ledgerName: `OUTPUT CGST ON SALES (GST ${rate}%)`, amount: half })
        ledgerEntries.push({ ledgerName: `OUTPUT SGST ON SALES (GST ${rate}%)`, amount: half })
      }
    })
  }

  return {
    items,
    subtotal,
    totalDiscount,
    totalGst: isGst ? totalGst : 0,
    roundOff,
    grandTotal,
    ledgerEntries,
  }
}

// Backward compatible orderTotals
export const orderTotals = (items: any[], productMap: Record<string, any>) => {
  const res = calculateBillTotals(items, productMap, 'RETAIL', 'GST')
  return { sub: res.subtotal - res.totalDiscount, tax: res.totalGst, total: res.grandTotal }
}

export const orderProfit = (items: any[], productMap: Record<string, any>) => {
  let revenue = 0, cost = 0
  items.forEach((it) => {
    const p = productMap[it.productId]
    revenue += (it.qty || 0) * (it.rate || 0)
    cost += (it.qty || 0) * (p ? p.cost : 0)
  })
  return revenue - cost
}

export const monthKey = (d: string | Date) => new Date(d).toISOString().slice(0, 7)

export const isSameDay = (a: string | Date, b: string | Date) =>
  new Date(a).toDateString() === new Date(b).toDateString()

export const DISPATCH_COLORS: Record<string, string> = {
  'Order Received': 'gray',
  'Packing Pending': 'amber',
  'Ready for Dispatch': 'blue',
  'Loaded': 'purple',
  'In Transit': 'teal',
  'Delivered': 'green',
  'Payment Collected': 'green',
  'Returned': 'red',
}
export const PAY_COLORS: Record<string, string> = { Paid: 'green', Partial: 'amber', Pending: 'red', Unpaid: 'red' }
export const QC_COLORS: Record<string, string> = { Passed: 'green', Pending: 'amber', Failed: 'red' }
export const PROD_COLORS: Record<string, string> = { Completed: 'green', 'In Progress': 'blue', Planned: 'amber' }

export const uid = (prefix: string) => `${prefix}-${Math.floor(1000 + Math.random() * 9000)}`

export const csvExport = (filename: string, rows: any[]) => {
  if (!rows || !rows.length) return
  const headers = Object.keys(rows[0])
  const escape = (v: any) => `"${String(v ?? '').replace(/"/g, '""')}"`
  const csv = [headers.join(','), ...rows.map((r) => headers.map((h) => escape(r[h])).join(','))].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}
