import { useState, useMemo, useEffect } from 'react'
import { useData } from '../context/DataContext'
import { useAuth } from '../context/AuthContext'
import { PageHeader, Badge, Modal, Toolbar, EmptyState } from '../components/ui'
import Icon from '../components/Icon'
import { inr, fmtDate, csvExport, PAY_COLORS } from '../utils/helpers'
import { buildInvoiceHTML, printInvoice } from '../utils/invoice'
import type { BillingType } from '../types'

export default function BillingHistory({ forcedBillingType }: { forcedBillingType?: BillingType }) {
  const { sales, customers, products, customerMap, productMap, company, upsert, addAuditLog } = useData()
  const { isSuperAdmin, isNonGstSession } = useAuth()

  // Filter mode: GST history vs Non-GST history (Non-GST visible ONLY to Super Admin)
  const [billingFilter, setBillingFilter] = useState<BillingType>(forcedBillingType || 'GST')

  useEffect(() => {
    if (forcedBillingType) {
      setBillingFilter(forcedBillingType)
    }
  }, [forcedBillingType])
  const [q, setQ] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [pricingFilter, setPricingFilter] = useState('all')
  const [cancelModal, setCancelModal] = useState<any>(null)
  const [cancelReason, setCancelReason] = useState('')

  const invoices = useMemo(() => {
    return (sales || []).filter((s: any) => {
      const bType = s.billingType || (s.id.startsWith('NG') ? 'NON_GST' : 'GST')

      // STRICT ISOLATION: Non-GST history MUST NOT be shown in standard GST login or any other role
      if (bType === 'NON_GST' && !isNonGstSession) return false

      if (billingFilter === 'GST' && bType === 'NON_GST') return false
      if (billingFilter === 'NON_GST' && bType === 'GST') return false

      if (statusFilter !== 'all' && (s.status || 'ACTIVE') !== statusFilter) return false
      if (pricingFilter !== 'all' && s.pricingType !== pricingFilter) return false

      if (q) {
        const term = q.toLowerCase()
        const custName = customerMap[s.customerId]?.name || s.address || ''
        const vNo = s.voucherNo || s.id
        if (!`${vNo} ${custName} ${s.salesperson || ''} ${s.userName || ''}`.toLowerCase().includes(term)) return false
      }
      return true
    })
  }, [sales, billingFilter, isNonGstSession, statusFilter, pricingFilter, q, customerMap])

  const printBill = (i: any) => {
    const cust = customerMap[i.customerId] || { name: 'Walk-in / Cash Customer', address: i.address }
    const billedByStr = i.billedBy || i.createdByName || i.userName || i.salesperson || 'Staff'
    printInvoice(
      buildInvoiceHTML({
        id: i.id,
        voucherNo: i.voucherNo || i.id,
        date: i.date,
        payStatus: i.payStatus,
        items: i.items,
        customer: cust,
        productMap,
        company: { ...company, gstin: i.billingType === 'GST' ? company.gstin : '' },
        billingType: i.billingType || 'GST',
        grandTotal: i.grandTotal || i.total,
        subtotal: i.subtotal || i.sub,
        gstTotal: i.gstTotal || i.tax,
        ledgerEntries: i.ledgerEntries || [],
        dispatchDetails: i.dispatchDetails,
        billedBy: billedByStr,
      })
    )
  }

  const handleCancelBill = (e: any) => {
    e.preventDefault()
    if (!cancelModal) return

    const inv = cancelModal
    const updated = {
      ...inv,
      status: 'CANCELLED',
      cancelledBy: 'Admin',
      cancelledDate: new Date().toISOString().slice(0, 10),
      cancelledReason: cancelReason || 'User Cancellation',
    }

    // 1. Update invoice status
    upsert('sales', updated)

    // 2. Reverse stock deduction
    (inv.items || []).forEach((it: any) => {
      const p = productMap[it.productId]
      if (p) {
        upsert('products', { ...p, stock: p.stock + (it.qty || 0) })
      }
    })

    // 3. Reverse customer credit outstanding if pending
    if (inv.payStatus !== 'Paid' && inv.customerId) {
      const c = customerMap[inv.customerId]
      if (c) {
        const invTotal = inv.grandTotal || inv.total || 0
        upsert('customers', { ...c, outstanding: Math.max(0, (c.outstanding || 0) - invTotal) })
      }
    }

    addAuditLog(null, 'BILL_CANCELLED', inv.billingType === 'GST' ? 'GST_BILLING' : 'NON_GST_BILLING', inv.id, `Reason: ${cancelReason}`)

    setCancelModal(null)
    setCancelReason('')
  }

  return (
    <div className="page">
      <PageHeader title="Billing History & Invoices" subtitle="Central record of generated sales invoices with price snapshots and audit logs.">
        <button
          className="btn"
          onClick={() =>
            csvExport(
              `${billingFilter.toLowerCase()}_invoices.csv`,
              invoices.map((i: any) => ({
                voucherNo: i.voucherNo || i.id,
                date: i.date,
                customer: customerMap[i.customerId]?.name || 'Walk-in',
                billingType: i.billingType || 'GST',
                pricingType: i.pricingType || 'RETAIL',
                subtotal: i.subtotal || i.sub || 0,
                gstTotal: i.gstTotal || i.tax || 0,
                grandTotal: i.grandTotal || i.total || 0,
                billedBy: i.billedBy || i.createdByName || i.userName || i.salesperson || 'Staff',
                payStatus: i.payStatus,
                status: i.status || 'ACTIVE',
              }))
            )
          }
        >
          <Icon name="download" /> Export CSV
        </button>
      </PageHeader>

      <Toolbar search={q} onSearch={setQ} placeholder="Search by Voucher No, Customer, User…">
        {/* GST vs Non-GST Filter Tabs */}
        <div className="pill-tabs" style={{ marginRight: 12 }}>
          <button className={billingFilter === 'GST' ? 'active' : ''} onClick={() => setBillingFilter('GST')}>
            GST Invoices
          </button>
          {isNonGstSession && (
            <button className={billingFilter === 'NON_GST' ? 'active' : ''} onClick={() => setBillingFilter('NON_GST')}>
              Non-GST Invoices (Super Admin)
            </button>
          )}
        </div>

        <select className="sel" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All Statuses</option>
          <option value="ACTIVE">Active</option>
          <option value="CANCELLED">Cancelled</option>
        </select>

        <select className="sel" value={pricingFilter} onChange={(e) => setPricingFilter(e.target.value)}>
          <option value="all">All Pricing Types</option>
          <option value="AGENCY">Agency</option>
          <option value="WHOLESALE">Wholesale</option>
          <option value="RETAIL">Retail</option>
        </select>

        <div className="spacer" />
        <span className="tiny">{invoices.length} invoices</span>
      </Toolbar>

      <div className="card table-wrap">
        <table className="tbl">
          <thead>
            <tr>
              <th>Voucher No</th>
              <th>Customer</th>
              <th>Date</th>
              <th>Pricing</th>
              <th>Billing Type</th>
              <th>Billed By</th>
              <th className="num">Taxable</th>
              <th className="num">GST</th>
              <th className="num">Grand Total</th>
              <th>Payment</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {invoices.map((i: any) => {
              const custName = customerMap[i.customerId]?.name || i.address || 'Walk-in Customer'
              const isCancelled = i.status === 'CANCELLED'
              const vNo = i.voucherNo || i.id
              const bType = i.billingType || (i.id.startsWith('NG') ? 'NON_GST' : 'GST')
              const grand = i.grandTotal || i.total || 0
              const sub = i.subtotal || i.sub || 0
              const gstAmt = bType === 'GST' ? (i.gstTotal || i.tax || 0) : 0
              const staffBilled = i.billedBy || i.createdByName || i.userName || i.salesperson || 'Staff'

              return (
                <tr key={i.id} style={{ opacity: isCancelled ? 0.6 : 1 }}>
                  <td className="cell-strong" style={{ color: 'var(--gold)' }}>{vNo}</td>
                  <td>
                    <div className="cell-strong">{custName}</div>
                    <div className="cell-sub">{i.salesperson ? `Sales: ${i.salesperson}` : ''}</div>
                  </td>
                  <td className="muted">{fmtDate(i.date)}</td>
                  <td><Badge tone="gold" noDot>{i.pricingType || 'RETAIL'}</Badge></td>
                  <td>
                    <Badge tone={bType === 'GST' ? 'green' : 'purple'} noDot>
                      {bType}
                    </Badge>
                  </td>
                  <td><div className="cell-strong" style={{ fontSize: 12 }}>{staffBilled}</div></td>
                  <td className="num muted">{inr(sub)}</td>
                  <td className="num muted">{bType === 'GST' ? inr(gstAmt) : '₹0'}</td>
                  <td className="num cell-strong" style={{ fontSize: 14 }}>{inr(grand)}</td>
                  <td><Badge tone={PAY_COLORS[i.payStatus]} noDot>{i.payStatus}</Badge></td>
                  <td>
                    <Badge tone={isCancelled ? 'red' : 'green'} noDot>
                      {i.status || 'ACTIVE'}
                    </Badge>
                  </td>
                  <td>
                    <div className="row-actions">
                      <button title="Print / PDF Invoice" onClick={() => printBill(i)}><Icon name="download" size={15} /></button>
                      {!isCancelled && (
                        <button title="Cancel Invoice" className="del" onClick={() => setCancelModal(i)}><Icon name="trash" size={15} /></button>
                      )}
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
        {!invoices.length && <EmptyState icon="billing" text={`No ${billingFilter} invoices match your filters.`} />}
      </div>

      {cancelModal && (
        <Modal
          title={`Cancel Invoice · ${cancelModal.voucherNo || cancelModal.id}`}
          onClose={() => setCancelModal(null)}
          footer={
            <>
              <button className="btn" onClick={() => setCancelModal(null)}>Close</button>
              <button className="btn btn-danger" form="cancelForm">Confirm Cancellation</button>
            </>
          }
        >
          <form id="cancelForm" onSubmit={handleCancelBill}>
            <p className="tiny" style={{ color: 'var(--red)', marginBottom: 12 }}>
              ⚠️ Cancelling this invoice will mark it <b>CANCELLED</b>, reverse product inventory deductions, and restore customer credit balances.
            </p>
            <div className="kv"><span className="k">Voucher No</span><span className="v">{cancelModal.voucherNo || cancelModal.id}</span></div>
            <div className="kv"><span className="k">Customer</span><span className="v">{customerMap[cancelModal.customerId]?.name || 'Walk-in'}</span></div>
            <div className="kv"><span className="k">Grand Total</span><span className="v">{inr(cancelModal.grandTotal || cancelModal.total)}</span></div>

            <div style={{ marginTop: 14 }}>
              <label className="k" style={{ fontSize: 12, fontWeight: 700 }}>Cancellation Reason</label>
              <input
                className="inp"
                style={{ width: '100%', marginTop: 4 }}
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                placeholder="e.g. Order cancelled by customer, Wrong entry"
                required
              />
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}
