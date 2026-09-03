// ============================================================
// GST Tax Invoice — printable HTML builder + print helper
// Generates an A4 tax invoice for a sales order and prints it
// (browser print dialog → paper or Save as PDF).
// ============================================================
import { inr, fmtDate, lineTotal } from './helpers'

// Seller / company details (single source of truth for the invoice header).
// GSTIN state code 33 = Tamil Nadu → used to decide CGST+SGST vs IGST.
export const COMPANY = {
  name: 'KKK Oil Factory',
  legal: 'KKK Oils',
  address: 'SIDCO Industrial Estate, Dharmapuri, Tamil Nadu 636705',
  gstin: '33ABCKK1234F1Z5',
  stateCode: '33',
  state: 'Tamil Nadu',
  phone: '+91 98430 11111',
  email: 'accounts@kkkoil.in',
  fssai: '10012345000123',
  bank: { name: 'Canara Bank, Dharmapuri', acc: '1234 5678 9012', ifsc: 'CNRB0001234' },
}

const CRORE = 10000000
const LAKH = 100000

const ONES = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen',
  'Eighteen', 'Nineteen']
const TENS = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety']

function twoDigit(n: number): string {
  if (n < 20) return ONES[n]
  const t = Math.floor(n / 10)
  const o = n % 10
  return TENS[t] + (o ? ' ' + ONES[o] : '')
}

function threeDigit(n: number): string {
  const h = Math.floor(n / 100)
  const r = n % 100
  let s = ''
  if (h) s += ONES[h] + ' Hundred'
  if (r) s += (h ? ' ' : '') + twoDigit(r)
  return s
}

// Indian-format rupees in words: crore / lakh / thousand / hundred.
export function amountInWords(amount: number): string {
  const rupees = Math.floor(Math.abs(amount))
  const paise = Math.round((Math.abs(amount) - rupees) * 100)
  if (rupees === 0 && paise === 0) return 'Zero Rupees Only'

  const parts: string[] = []
  const crore = Math.floor(rupees / CRORE)
  const lakh = Math.floor((rupees % CRORE) / LAKH)
  const thousand = Math.floor((rupees % LAKH) / 1000)
  const hundred = rupees % 1000

  if (crore) parts.push(twoDigit(crore) + ' Crore')
  if (lakh) parts.push(twoDigit(lakh) + ' Lakh')
  if (thousand) parts.push(twoDigit(thousand) + ' Thousand')
  if (hundred) parts.push(threeDigit(hundred))

  let words = parts.join(' ').trim() + ' Rupees'
  if (paise) words += ' and ' + twoDigit(paise) + ' Paise'
  return words + ' Only'
}

export interface InvoiceLine {
  productId: string
  productCode?: string
  productName?: string
  unit?: string
  qty: number
  rate: number
  discAmount?: number
  taxableAmount?: number
  gstRate?: number
  gstAmount?: number
  finalAmount?: number
}

interface InvoiceInput {
  id: string           // e.g. GST-000001 or NG-000001
  voucherNo?: string
  date: string
  payStatus?: string
  items: InvoiceLine[]
  customer?: any
  productMap: Record<string, any>
  company?: Partial<typeof COMPANY>
  billingType?: 'GST' | 'NON_GST'
  grandTotal?: number
  subtotal?: number
  gstTotal?: number
  ledgerEntries?: { ledgerName: string; amount: number }[]
  dispatchDetails?: any
  billedBy?: string
}

export const invoiceNo = (id: string) => id

const esc = (v: any) =>
  String(v ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

export function buildInvoiceHTML({
  id,
  voucherNo: vNo,
  date,
  payStatus,
  items,
  customer,
  productMap,
  company,
  billingType = 'GST',
  grandTotal: forcedGrand,
  subtotal: forcedSub,
  gstTotal: forcedGst,
  ledgerEntries = [],
  dispatchDetails,
  billedBy,
}: InvoiceInput): string {
  const isGst = billingType === 'GST'
  const co = { ...COMPANY, ...(company || {}), bank: { ...COMPANY.bank, ...(company?.bank || {}) } }
  const buyerState = String(customer?.gstin || '').slice(0, 2)
  const interState = buyerState && buyerState !== co.stateCode
  const displayNo = vNo || id

  let subTotal = 0
  let taxTotal = 0

  const rows = items.map((it, i) => {
    const p = productMap[it.productId] || {}
    const name = it.productName || p.name || it.productId
    const code = it.productCode || p.code || p.sku || ''
    const hsn = p.hsn || '—'
    const unit = it.unit || p.unit || 'Bottle'
    const gstRate = isGst ? (it.gstRate ?? p.gst ?? 0) : 0

    const gross = it.qty * it.rate
    const disc = it.discAmount || 0
    const taxable = it.taxableAmount ?? (gross - disc)
    const tax = isGst ? (it.gstAmount ?? taxable * (gstRate / 100)) : 0

    subTotal += taxable
    taxTotal += tax

    return `
      <tr>
        <td class="c">${i + 1}</td>
        <td>
          <div style="font-weight:600">${esc(name)}</div>
          ${code ? `<div style="font-size:10px;color:#666">${esc(code)}</div>` : ''}
        </td>
        <td class="c">${esc(hsn)}</td>
        <td class="r">${it.qty}</td>
        <td class="c">${esc(unit)}</td>
        <td class="r">${inr(it.rate)}</td>
        ${isGst ? `<td class="c">${gstRate}%</td>` : ''}
        <td class="r">${inr(taxable)}</td>
        <td class="r" style="font-weight:600">${inr(taxable + tax)}</td>
      </tr>`
  }).join('')

  const computedGrand = subTotal + (isGst ? taxTotal : 0)
  const payable = forcedGrand ? Math.round(forcedGrand) : Math.round(computedGrand)
  const roundOff = payable - computedGrand
  const half = (forcedGst ?? taxTotal) / 2

  const taxBlock = isGst
    ? (interState
        ? `<div class="kv"><span>IGST</span><span>${inr(forcedGst ?? taxTotal)}</span></div>`
        : `<div class="kv"><span>CGST</span><span>${inr(half)}</span></div>
           <div class="kv"><span>SGST</span><span>${inr(half)}</span></div>`)
    : ''

  const statusTag = payStatus
    ? `<span class="tag ${payStatus === 'Paid' ? 'paid' : 'due'}">${esc(payStatus)}</span>`
    : ''

  const docTitle = isGst ? 'TAX INVOICE' : 'SALES BILL / VOUCHER'

  return `<!doctype html><html><head><meta charset="utf-8">
<title>${esc(displayNo)}</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, "Segoe UI", Roboto, Arial, sans-serif; color: #1a1a1a; font-size: 12px; background: #f3f3f0; padding: 20px; }
  .sheet { width: 210mm; min-height: 297mm; margin: 0 auto; background: #fff; padding: 16mm 14mm; box-shadow: 0 2px 14px rgba(0,0,0,.12); }
  .top { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid ${isGst ? '#e3a92e' : '#7c3aed'}; padding-bottom: 12px; }
  .co-name { font-size: 22px; font-weight: 800; color: #17442b; letter-spacing: .3px; }
  .co-sub { color: #555; margin-top: 3px; line-height: 1.5; max-width: 340px; }
  .doc-title { text-align: right; }
  .doc-title h1 { font-size: 18px; letter-spacing: 2px; color: ${isGst ? '#17442b' : '#7c3aed'}; text-transform: uppercase; }
  .doc-title .meta { margin-top: 6px; color: #444; line-height: 1.6; }
  .tag { display: inline-block; padding: 2px 9px; border-radius: 20px; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .5px; }
  .tag.paid { background: #dcf3e5; color: #137a4d; }
  .tag.due { background: #fde8e8; color: #c0392b; }
  .parties { display: flex; gap: 14px; margin: 16px 0; }
  .party { flex: 1; border: 1px solid #e5e5e0; border-radius: 8px; padding: 11px 13px; }
  .party h3 { font-size: 10px; text-transform: uppercase; letter-spacing: .6px; color: #999; margin-bottom: 6px; }
  .party .nm { font-weight: 700; font-size: 13px; }
  .party .ln { color: #555; margin-top: 3px; line-height: 1.5; }
  table { width: 100%; border-collapse: collapse; margin-top: 6px; }
  thead th { background: ${isGst ? '#17442b' : '#4c1d95'}; color: #fff; font-size: 10px; text-transform: uppercase; letter-spacing: .4px; padding: 8px 7px; text-align: left; }
  tbody td { padding: 8px 7px; border-bottom: 1px solid #eee; }
  .c { text-align: center; } .r { text-align: right; }
  .foot { display: flex; justify-content: space-between; margin-top: 16px; gap: 20px; }
  .terms { flex: 1; font-size: 11px; color: #555; line-height: 1.7; }
  .terms h4 { font-size: 10px; text-transform: uppercase; letter-spacing: .5px; color: #999; margin-bottom: 5px; }
  .totals { width: 260px; }
  .totals .kv { display: flex; justify-content: space-between; padding: 5px 0; color: #444; }
  .totals .grand { display: flex; justify-content: space-between; border-top: 2px solid ${isGst ? '#17442b' : '#4c1d95'}; margin-top: 6px; padding-top: 8px; font-size: 15px; font-weight: 800; color: ${isGst ? '#17442b' : '#4c1d95'}; }
  .words { margin-top: 14px; padding: 9px 12px; background: #faf6ec; border: 1px solid #f0e2c0; border-radius: 8px; font-size: 11px; }
  .words b { color: #17442b; }
  .sign { margin-top: 30px; text-align: right; }
  .sign .line { display: inline-block; border-top: 1px solid #999; padding-top: 5px; min-width: 180px; text-align: center; color: #555; font-size: 11px; }
  .note { text-align: center; margin-top: 22px; color: #999; font-size: 10px; }
  @media print {
    body { background: #fff; padding: 0; }
    .sheet { box-shadow: none; width: auto; min-height: auto; padding: 12mm; }
    @page { size: A4; margin: 0; }
  }
</style></head>
<body>
  <div class="sheet">
    <div class="top">
      <div>
        <div class="co-name">${esc(co.name)}</div>
        <div class="co-sub">
          ${esc(co.address)}<br>
          ${isGst && co.gstin ? `GSTIN: <b>${esc(co.gstin)}</b> · ` : ''}${co.fssai ? `FSSAI: ${esc(co.fssai)}` : ''}<br>
          ${esc(co.phone)}${co.email ? ` · ${esc(co.email)}` : ''}
        </div>
      </div>
      <div class="doc-title">
        <h1>${docTitle}</h1>
        <div class="meta">
          <div><b>${esc(displayNo)}</b> ${statusTag}</div>
          <div>Date: ${esc(fmtDate(date))}</div>
          <div>Billing Type: <b>${esc(billingType)}</b></div>
          ${billedBy ? `<div>Billed By: <b>${esc(billedBy)}</b></div>` : ''}
        </div>
      </div>
    </div>

    <div class="parties">
      <div class="party">
        <h3>Bill To</h3>
        <div class="nm">${esc(customer?.name || 'Cash Customer')}</div>
        <div class="ln">${esc(customer?.address || customer?.area || '')}${customer?.route ? ' · Route ' + esc(customer.route) : ''}</div>
        ${isGst && customer?.gstin ? `<div class="ln">GSTIN: ${esc(customer.gstin)}</div>` : ''}
        ${customer?.phone ? `<div class="ln">Ph: ${esc(customer.phone)}</div>` : ''}
      </div>
      <div class="party">
        <h3>Dispatch Details</h3>
        <div class="nm">${esc(dispatchDetails?.dispatchThrough || 'Direct Delivery')}</div>
        ${dispatchDetails?.vehicleNumber ? `<div class="ln">Vehicle: ${esc(dispatchDetails.vehicleNumber)}</div>` : ''}
        ${dispatchDetails?.poNumber ? `<div class="ln">PO No: ${esc(dispatchDetails.poNumber)}</div>` : ''}
      </div>
    </div>

    <table>
      <thead><tr>
        <th class="c">#</th><th>Description</th><th class="c">HSN</th>
        <th class="r">Qty</th><th class="c">Unit</th><th class="r">Rate</th>
        ${isGst ? `<th class="c">GST</th>` : ''}
        <th class="r">Taxable</th><th class="r">Total</th>
      </tr></thead>
      <tbody>${rows}</tbody>
    </table>

    <div class="foot">
      <div class="terms">
        ${co.bank?.acc ? `<h4>Bank Details</h4>
        ${esc(co.bank.name)}<br>
        A/C: ${esc(co.bank.acc)} · IFSC: ${esc(co.bank.ifsc)}` : ''}
        <h4 style="margin-top:12px">Terms &amp; Conditions</h4>
        Goods once sold will not be taken back. Interest @18% p.a. on overdue bills. Subject to ${esc(co.state)} jurisdiction.
      </div>
      <div class="totals">
        <div class="kv"><span>Subtotal Value</span><span>${inr(forcedSub ?? subTotal)}</span></div>
        ${taxBlock}
        ${Math.abs(roundOff) > 0.004 ? `<div class="kv"><span>Round Off</span><span>${roundOff >= 0 ? '+' : '−'} ${inr(Math.abs(roundOff))}</span></div>` : ''}
        <div class="grand"><span>Grand Total</span><span>${inr(payable)}</span></div>
      </div>
    </div>

    <div class="words">Amount in words: <b>${esc(amountInWords(payable))}</b></div>

    <div class="sign">
      <div class="line">For ${esc(co.name)}<br><br>Authorised Signatory</div>
    </div>

    <div class="note">This is a computer-generated ${billingType} voucher.</div>
  </div>
</body></html>`
}


// Print the given invoice HTML via a hidden iframe (avoids popup blockers).
export function printInvoice(html: string) {
  const iframe = document.createElement('iframe')
  iframe.style.position = 'fixed'
  iframe.style.right = '0'
  iframe.style.bottom = '0'
  iframe.style.width = '0'
  iframe.style.height = '0'
  iframe.style.border = '0'
  document.body.appendChild(iframe)

  const doc = iframe.contentWindow?.document
  if (!doc) { document.body.removeChild(iframe); return }
  doc.open()
  doc.write(html)
  doc.close()

  const win = iframe.contentWindow!
  const done = () => setTimeout(() => { try { document.body.removeChild(iframe) } catch { /* already gone */ } }, 1000)
  win.onafterprint = done
  // Give the iframe a tick to lay out before printing.
  setTimeout(() => { win.focus(); win.print(); done() }, 250)
}
