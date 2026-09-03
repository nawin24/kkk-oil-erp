import { useState, useMemo, useEffect } from 'react'
import { useData } from '../context/DataContext'
import { useAuth } from '../context/AuthContext'
import { PageHeader, Badge, Modal } from '../components/ui'
import Icon from '../components/Icon'
import { inr, todayISO, currentTimeStr, calculateBillTotals, getEffectiveProductRate } from '../utils/helpers'
import { GODOWNS } from '../data/seed'
import { buildInvoiceHTML, printInvoice } from '../utils/invoice'
import type { PricingType, BillingType } from '../types'

export default function ErpBilling({ forcedBillingType }: { forcedBillingType?: BillingType }) {
  const { products, customers, company, priceHistory, sales, upsert, addAuditLog } = useData()
  const { user, isSuperAdmin, isCashier, isNonGstSession } = useAuth()

  // Mode Selection: GST vs NON_GST (If forced, locked to forcedBillingType; otherwise defaults to GST)
  const [billingType, setBillingType] = useState<BillingType>(forcedBillingType || 'GST')

  useEffect(() => {
    if (forcedBillingType) {
      setBillingType(forcedBillingType)
      setVoucherType(forcedBillingType === 'GST' ? 'GST Invoice' : 'Non-GST Voucher')
    }
  }, [forcedBillingType])

  // Voucher Header State
  const [voucherType, setVoucherType] = useState(forcedBillingType === 'NON_GST' ? 'Non-GST Voucher' : 'GST Invoice')
  const [entryDate, setEntryDate] = useState(todayISO())
  const [customerId, setCustomerId] = useState('')
  const [route, setRoute] = useState('')
  const [address, setAddress] = useState('')
  const [gstin, setGstin] = useState('')
  const [salesMan, setSalesMan] = useState(user?.name || 'Srinivasan')
  const [deliveryMan, setDeliveryMan] = useState('Srinivasan')
  const [godown, setGodown] = useState('Main Godown')
  const [pricingType, setPricingType] = useState<PricingType>('RETAIL')
  const [payMode, setPayMode] = useState('Cash')

  // Quick Product Adder State
  const [prodSearch, setProdSearch] = useState('')
  const [selectedProduct, setSelectedProduct] = useState<any>(null)
  const [inputQty, setInputQty] = useState(1)
  const [inputDisc, setInputDisc] = useState(0)

  // Item Grid raw lines
  const [rawLines, setRawLines] = useState<any[]>([])

  // Horizon ERP Collapsible Section Tabs
  const [activeErpTab, setActiveErpTab] = useState<'dispatch' | 'ewb' | 'eInvoice' | 'ledger'>('dispatch')

  // Dispatch details (PO, Vehicle, Driver)
  const [poNumber, setPoNumber] = useState('')
  const [poDate, setPoDate] = useState(todayISO())
  const [dispatchThrough, setDispatchThrough] = useState('')
  const [vehicleNumber, setVehicleNumber] = useState('')
  const [driverName, setDriverName] = useState('')
  const [deliveryNote, setDeliveryNote] = useState('')
  const [gatePassNo, setGatePassNo] = useState('')

  // E-Way Bill details (GST only)
  const [supplyType, setSupplyType] = useState('Outward')
  const [supplySubType, setSupplySubType] = useState('Supply')
  const [transportMode, setTransportMode] = useState('Road')
  const [transporterName, setTransporterName] = useState('')
  const [transporterId, setTransporterId] = useState('')
  const [transportDistance, setTransportDistance] = useState(0)
  const [ewbNo, setEwbNo] = useState('')
  const [ewbDate, setEwbDate] = useState('')
  const [validTill, setValidTill] = useState('')

  // E-Invoice details (GST only)
  const [irn, setIrn] = useState('')
  const [irnGenerated, setIrnGenerated] = useState(false)

  const [toastMsg, setToastMsg] = useState('')

  // Auto-generate Voucher Number with separate numbering series
  const voucherNo = useMemo(() => {
    const prefix = billingType === 'GST' ? 'GST' : 'NG'
    const matchingCount = (sales || []).filter((s: any) => (s.billingType || (s.id.startsWith('NG') ? 'NON_GST' : 'GST')) === billingType).length
    const numStr = String(matchingCount + 1).padStart(6, '0')
    return `${prefix}-${numStr}`
  }, [sales, billingType])

  // Map product lookups
  const productMap = useMemo(() => Object.fromEntries((products || []).map((p: any) => [p.id, p])), [products])
  const customerMap = useMemo(() => Object.fromEntries((customers || []).map((c: any) => [c.id, c])), [customers])

  // Auto-fill customer details when party is selected
  useEffect(() => {
    if (customerId && customerMap[customerId]) {
      const c = customerMap[customerId]
      setRoute(c.route || '')
      setAddress(c.address || c.area || '')
      setGstin(c.gstin || '')
    } else {
      setRoute('')
      setAddress('')
      setGstin('')
    }
  }, [customerId, customerMap])

  // Re-calculate line rates whenever pricingType, entryDate, or product list changes
  useEffect(() => {
    setRawLines((prevLines) =>
      prevLines.map((line) => {
        const p = productMap[line.productId]
        if (!p) return line
        const activeRate = getEffectiveProductRate(p, pricingType, entryDate, priceHistory)
        return { ...line, appliedRate: activeRate }
      })
    )
  }, [pricingType, entryDate, productMap, priceHistory])

  // Calculate live Horizon ERP bill totals
  const billCalc = useMemo(() => {
    const cust = customerMap[customerId]
    return calculateBillTotals(
      rawLines,
      productMap,
      pricingType,
      billingType,
      entryDate,
      priceHistory,
      company?.stateCode || '33',
      cust?.gstin ? cust.gstin.slice(0, 2) : '33'
    )
  }, [rawLines, productMap, pricingType, billingType, entryDate, priceHistory, company, customerId, customerMap])

  // Quick Product Adder
  const handleAddProduct = (prod: any) => {
    if (!prod) return
    const effectiveRate = getEffectiveProductRate(prod, pricingType, entryDate, priceHistory)
    const existingIndex = rawLines.findIndex((l) => l.productId === prod.id)

    if (existingIndex >= 0) {
      setRawLines((prev) =>
        prev.map((l, idx) => (idx === existingIndex ? { ...l, qty: l.qty + inputQty } : l))
      )
    } else {
      setRawLines((prev) => [
        ...prev,
        {
          productId: prod.id,
          qty: inputQty,
          appliedRate: effectiveRate,
          discPercent: inputDisc,
          discAmount: 0,
          schemeAmount: 0,
        },
      ])
    }
    setProdSearch('')
    setSelectedProduct(null)
    setInputQty(1)
    setInputDisc(0)
  }

  const updateLine = (index: number, key: string, val: any) => {
    setRawLines((prev) =>
      prev.map((l, idx) => (idx === index ? { ...l, [key]: val } : l))
    )
  }

  const removeLine = (index: number) => {
    setRawLines((prev) => prev.filter((_, idx) => idx !== index))
  }

  const clearForm = () => {
    setRawLines([])
    setCustomerId('')
    setRoute('')
    setAddress('')
    setGstin('')
    setPoNumber('')
    setVehicleNumber('')
    setDriverName('')
    setEwbNo('')
    setIrn('')
    setIrnGenerated(false)
  }

  const [isProcessing, setIsProcessing] = useState(false)
  const [lastSavedBill, setLastSavedBill] = useState<any>(null)

  // Validate bill before saving
  const validateBill = () => {
    if (!rawLines.length) {
      setToastMsg('❌ Please complete all required billing details. (Add at least one product)')
      return false
    }
    if (payMode === 'Credit' && !customerId) {
      setToastMsg('❌ Credit bills require a selected customer.')
      return false
    }
    return true
  }

  const saveBill = async (andPrint: boolean = false) => {
    if (isProcessing) return
    if (!validateBill()) return

    setIsProcessing(true)
    setToastMsg('💾 Saving bill to database…')

    try {
      const cust = customerMap[customerId]
      const paid = payMode !== 'Credit'
      const billedByStr = `${user?.name || 'Cashier'} (${user?.roleLabel || 'Staff'})`

      const invoiceRecord: any = {
        id: voucherNo,
        voucherNo,
        voucherType: billingType === 'GST' ? voucherType : 'Non-GST Voucher',
        billingType,
        pricingType,
        customerId: customerId || 'CASH-WALKIN',
        date: entryDate,
        time: currentTimeStr(),
        salesperson: salesMan,
        deliveryMan,
        godown,
        route,
        address,
        gstin: billingType === 'GST' ? gstin : '',
        dispatch: 'Delivered',
        payStatus: paid ? 'Paid' : 'Pending',
        payMode,
        userId: user?.id || 'cashier',
        userName: user?.name || 'Cashier',
        userRole: user?.role || 'cashier',
        createdBy: user?.id || 'cashier',
        createdByRole: user?.role || 'cashier',
        createdByName: user?.name || 'Cashier',
        billedBy: billedByStr,
        items: billCalc.items,
        subtotal: billCalc.subtotal,
        discountTotal: billCalc.totalDiscount,
        gstTotal: billingType === 'GST' ? billCalc.totalGst : 0,
        roundOff: billCalc.roundOff,
        grandTotal: billCalc.grandTotal,
        ledgerEntries: billingType === 'GST' ? billCalc.ledgerEntries : [],
        dispatchDetails: { poNumber, poDate, dispatchThrough, vehicleNumber, driverName, deliveryNote, gatePassNo },
        ewbDetails: billingType === 'GST' ? { supplyType, supplySubType, transportMode, transporterName, transporterId, transportDistance, ewbNo, ewbDate, validTill } : undefined,
        eInvoiceDetails: billingType === 'GST' ? { irn, irnGenerated } : undefined,
        status: 'ACTIVE',
        createdAt: new Date().toISOString(),
      }

      // 1. Save invoice to database FIRST
      upsert('sales', invoiceRecord)

      // 2. Update stock in Inventory
      rawLines.forEach((it) => {
        const p = productMap[it.productId]
        if (p) {
          const nextStock = Math.max(0, p.stock - it.qty)
          upsert('products', { ...p, stock: nextStock })
        }
      })

      // 3. Update customer outstanding if credit bill
      if (!paid && customerId && cust) {
        upsert('customers', { ...cust, outstanding: (cust.outstanding || 0) + billCalc.grandTotal })
      }

      // 4. Audit Log
      addAuditLog(user, 'BILL_CREATED', billingType === 'GST' ? 'GST_BILLING' : 'NON_GST_BILLING', undefined, `${voucherNo} — Total ₹${billCalc.grandTotal} by ${billedByStr}`)

      // 5. Generate & Print SECOND (only after DB save success)
      if (andPrint) {
        printInvoice(
          buildInvoiceHTML({
            id: voucherNo,
            date: entryDate,
            payStatus: invoiceRecord.payStatus,
            items: invoiceRecord.items,
            customer: cust || { name: 'Walk-in / Cash Customer', address },
            productMap,
            company: { ...company, gstin: billingType === 'GST' ? company.gstin : '' },
            billingType,
            voucherNo,
            grandTotal: billCalc.grandTotal,
            subtotal: billCalc.subtotal,
            gstTotal: billCalc.totalGst,
            ledgerEntries: invoiceRecord.ledgerEntries,
            dispatchDetails: invoiceRecord.dispatchDetails,
            billedBy: billedByStr,
          })
        )
      }

      setLastSavedBill(invoiceRecord)
      setToastMsg(`✅ ${billingType} Invoice ${voucherNo} saved successfully! Total: ${inr(billCalc.grandTotal)}`)
      clearForm()
    } catch (e) {
      setToastMsg('❌ Unable to save the bill. Please try again.')
    } finally {
      setIsProcessing(false)
    }
  }

  // Search product list
  const filteredProducts = useMemo(() => {
    const term = prodSearch.toLowerCase()
    return (products || []).filter(
      (p: any) => p.status !== 'Inactive' && (!term || `${p.name} ${p.code} ${p.sku} ${p.category}`.toLowerCase().includes(term))
    )
  }, [products, prodSearch])

  return (
    <div className="page" style={{ paddingBottom: 24 }}>
      {/* HORIZON ERP TITLE HEADER BAR */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '12px 18px',
          background: 'var(--brand)',
          color: '#fff',
          borderRadius: '8px 8px 0 0',
          borderBottom: '3px solid var(--gold)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ background: 'var(--gold)', color: '#000', fontWeight: 900, fontSize: 13, padding: '4px 8px', borderRadius: 4, letterSpacing: '.5px' }}>
            {company?.name || 'KKK OIL FACTORY'} ERP
          </div>
          <div>
            <h2 style={{ fontSize: 18, fontWeight: 800, margin: 0, color: '#834006', letterSpacing: '.5px' }}>
              {billingType === 'GST' ? 'SALES INVOICE VOUCHER' : 'NON-GST SALES VOUCHER'}
            </h2>
            <span style={{ fontSize: 12, color: '#c86d1e', opacity: 0.9 }}>
              {billingType === 'GST' ? 'Ledger Billing Station' : 'Private Non-GST Voucher Station (Super Admin)'}
            </span>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Badge tone={billingType === 'GST' ? 'gold' : 'purple'} noDot>
            VOUCHER: {voucherNo}
          </Badge>
        </div>
      </div>

      {/* Toast Alert */}
      {toastMsg && (
        <div style={{ padding: '10px 16px', background: toastMsg.includes('❌') ? 'var(--red-soft)' : 'var(--green-soft)', color: toastMsg.includes('❌') ? 'var(--red)' : 'var(--green)', fontWeight: 600, fontSize: 13, borderBottom: '1px solid var(--border)' }}>
          {toastMsg}
        </div>
      )}

      {/* HORIZON ERP HEADER INFORMATION PANEL */}
      <div className="card" style={{ borderRadius: '0 0 8px 8px', padding: 16, marginBottom: 16, borderTop: 'none' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))', gap: 14 }}>
          <div>
            <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Voucher Type</label>
            <select className="sel" style={{ width: '100%', fontSize: 13, fontWeight: 600 }} value={voucherType} onChange={(e) => setVoucherType(e.target.value)}>
              {billingType === 'GST' ? (
                <>
                  <option value="GST Invoice">GST Tax Invoice</option>
                  <option value="Delivery Note">Delivery Note</option>
                  <option value="Sales Order">Sales Order</option>
                </>
              ) : (
                <option value="Non-GST Voucher">Non-GST Voucher</option>
              )}
            </select>
          </div>

          <div>
            <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Voucher No.</label>
            <input className="inp" style={{ width: '100%', fontWeight: 800, color: 'var(--gold)', fontSize: 13 }} value={voucherNo} readOnly />
          </div>

          <div>
            <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Voucher Date</label>
            <input className="inp" style={{ width: '100%', fontSize: 13 }} type="date" value={entryDate} onChange={(e) => setEntryDate(e.target.value)} />
          </div>

          <div>
            <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Party Ledger / Customer</label>
            <select className="sel" style={{ width: '100%', fontSize: 13, fontWeight: 700 }} value={customerId} onChange={(e) => setCustomerId(e.target.value)}>
              <option value="">Walk-in / Cash Customer</option>
              {(customers || []).map((c: any) => (
                <option key={c.id} value={c.id}>{c.name} {c.code ? `(${c.code})` : ''}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Price List (AWR Rates)</label>
            <div style={{ display: 'flex', gap: 4, width: '100%' }}>
              {(['AGENCY', 'WHOLESALE', 'RETAIL'] as PricingType[]).map((t) => (
                <button
                  key={t}
                  type="button"
                  className={`btn btn-sm ${pricingType === t ? 'btn-gold' : ''}`}
                  style={{ flex: 1, minWidth: 0, fontSize: 11, padding: '6px 4px', fontWeight: 700, justifyContent: 'center' }}
                  onClick={() => setPricingType(t)}
                >
                  <span className="truncate">{t}</span>
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Delivery Address</label>
            <input className="inp" style={{ width: '100%', fontSize: 12 }} value={address} onChange={(e) => setAddress(e.target.value)} placeholder="Delivery Address / Town" />
          </div>

          {billingType === 'GST' && (
            <div>
              <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Customer GSTIN</label>
              <input className="inp" style={{ width: '100%', fontSize: 12, fontWeight: 600 }} value={gstin} onChange={(e) => setGstin(e.target.value.toUpperCase())} placeholder="33XXXXX1234X1ZX" />
            </div>
          )}

          <div>
            <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Sales Man</label>
            <input className="inp" style={{ width: '100%', fontSize: 12 }} value={salesMan} onChange={(e) => setSalesMan(e.target.value)} />
          </div>

          <div>
            <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', display: 'block', marginBottom: 4 }}>Godown Location</label>
            <select className="sel" style={{ width: '100%', fontSize: 12 }} value={godown} onChange={(e) => setGodown(e.target.value)}>
              {GODOWNS.map((g) => <option key={g} value={g}>{g}</option>)}
            </select>
          </div>
        </div>
      </div>

      {/* HORIZON ERP DENSE SPREADSHEET ITEM ENTRY & GRID */}
      <div className="card" style={{ padding: 16, marginBottom: 16 }}>
        {/* Fast Item Barcode / Code Search Bar */}
        <div style={{ background: 'var(--bg-subtle)', padding: 12, borderRadius: 8, marginBottom: 14, border: '1px solid var(--border)' }}>
          <div style={{ fontSize: 11, fontWeight: 800, textTransform: 'uppercase', color: 'var(--gold)', marginBottom: 6 }}>
            ⚡ Fast Item Entry (Scan Barcode / Search Code or Name)
          </div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
            <input
              className="inp"
              placeholder="Type product name, code (e.g. PRD-101)..."
              value={prodSearch}
              onChange={(e) => setProdSearch(e.target.value)}
              style={{ flex: '2 1 220px', minWidth: 200 }}
            />
            <input
              className="inp"
              type="number"
              min="1"
              placeholder="Qty"
              value={inputQty}
              onChange={(e) => setInputQty(Math.max(1, Number(e.target.value) || 1))}
              style={{ flex: '0 0 80px', width: 80, textAlign: 'right' }}
            />
            <input
              className="inp"
              type="number"
              min="0"
              placeholder="Disc %"
              value={inputDisc}
              onChange={(e) => setInputDisc(Number(e.target.value) || 0)}
              style={{ flex: '0 0 80px', width: 80, textAlign: 'right' }}
            />
          </div>

          {/* Quick Selection Dropdown Chips */}
          {prodSearch && (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 10, background: 'var(--bg-card)', padding: 8, borderRadius: 6, border: '1px solid var(--border)' }}>
              {filteredProducts.slice(0, 6).map((p: any) => (
                <button
                  key={p.id}
                  type="button"
                  className="btn btn-sm btn-gold"
                  onClick={() => handleAddProduct(p)}
                  style={{ fontSize: 12, maxWidth: '100%', overflow: 'hidden' }}
                >
                  <span className="truncate">
                    + {p.name} ({p.code}) — {inr(getEffectiveProductRate(p, pricingType, entryDate, priceHistory))} (Stock: {p.stock})
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* HORIZON ERP TABLE STRUCTURE */}
        <div className="table-wrap" style={{ border: '1px solid var(--border)', borderRadius: 6, overflowX: 'auto' }}>
          <table className="tbl" style={{ fontSize: 12, minWidth: 850 }}>
            <thead>
              <tr style={{ background: 'var(--brand)', color: '#fff' }}>
                <th style={{ width: 35, textTransform: 'uppercase', textAlign: 'center' }}>#</th>
                <th style={{ textTransform: 'uppercase', width: 100 }}>Item Code</th>
                <th style={{ textTransform: 'uppercase', minWidth: 180 }}>Description of Goods</th>
                <th style={{ textTransform: 'uppercase', width: 90 }}>Pack / Unit</th>
                <th className="num" style={{ textTransform: 'uppercase', width: 80 }}>MRP</th>
                <th className="num" style={{ width: 75, textTransform: 'uppercase' }}>Qty</th>
                <th className="num" style={{ width: 105, textTransform: 'uppercase' }}>Rate ({pricingType})</th>
                <th className="num" style={{ width: 75, textTransform: 'uppercase' }}>Disc %</th>
                <th className="num" style={{ textTransform: 'uppercase', width: 110 }}>Taxable Amt</th>
                {billingType === 'GST' && <th style={{ textTransform: 'uppercase', width: 70 }}>GST %</th>}
                {billingType === 'GST' && <th className="num" style={{ textTransform: 'uppercase', width: 90 }}>Tax Amt</th>}
                <th className="num" style={{ textTransform: 'uppercase', width: 110 }}>Line Total</th>
                <th style={{ width: 40 }}></th>
              </tr>
            </thead>
            <tbody>
              {billCalc.items.map((line: any, i: number) => {
                const raw = rawLines[i] || {}
                return (
                  <tr key={i} style={{ background: i % 2 === 0 ? 'transparent' : 'rgba(0,0,0,.02)' }}>
                    <td style={{ textAlign: 'center', fontWeight: 600 }}>{i + 1}</td>
                    <td className="cell-strong" style={{ color: 'var(--gold)', fontSize: 11, whiteSpace: 'nowrap' }}>{line.productCode}</td>
                    <td>
                      <div className="cell-strong" style={{ fontSize: 13, lineHeight: 1.3 }}>{line.productName}</div>
                      <div className="cell-sub" style={{ fontSize: 11 }}>Category: Edible Oils</div>
                    </td>
                    <td><Badge tone="gray" noDot>{line.unit}</Badge></td>
                    <td className="num muted" style={{ whiteSpace: 'nowrap' }}>{inr(line.mrp)}</td>
                    <td className="num">
                      <input
                        className="inp"
                        type="number"
                        min="1"
                        style={{ width: 65, textAlign: 'right', padding: '4px 6px', fontSize: 12, fontWeight: 700 }}
                        value={raw.qty || 1}
                        onChange={(e) => updateLine(i, 'qty', Math.max(1, Number(e.target.value) || 0))}
                      />
                    </td>
                    <td className="num cell-strong" style={{ whiteSpace: 'nowrap' }}>
                      {isCashier ? (
                        <span style={{ fontWeight: 700 }}>{inr(line.rate)}</span>
                      ) : (
                        <input
                          className="inp"
                          type="number"
                          step="0.01"
                          style={{ width: 85, textAlign: 'right', padding: '4px 6px', fontSize: 12, fontWeight: 700 }}
                          value={raw.appliedRate ?? line.rate}
                          onChange={(e) => updateLine(i, 'appliedRate', Number(e.target.value))}
                        />
                      )}
                    </td>
                    <td className="num">
                      <input
                        className="inp"
                        type="number"
                        min="0"
                        max="100"
                        style={{ width: 60, textAlign: 'right', padding: '4px 6px', fontSize: 12 }}
                        value={raw.discPercent || 0}
                        onChange={(e) => updateLine(i, 'discPercent', Number(e.target.value))}
                      />
                    </td>
                    <td className="num cell-strong" style={{ whiteSpace: 'nowrap' }}>{inr(line.taxableAmount)}</td>
                    {billingType === 'GST' && <td><Badge tone="gray" noDot>{line.gstRate}%</Badge></td>}
                    {billingType === 'GST' && <td className="num muted" style={{ whiteSpace: 'nowrap' }}>{inr(line.gstAmount)}</td>}
                    <td className="num cell-strong" style={{ color: 'var(--gold)', fontSize: 13, whiteSpace: 'nowrap' }}>{inr(line.finalAmount)}</td>
                    <td>
                      <button type="button" className="del" style={{ padding: 4 }} onClick={() => removeLine(i)}><Icon name="trash" size={14} /></button>
                    </td>
                  </tr>
                )
              })}
              {!billCalc.items.length && (
                <tr>
                  <td colSpan={13} style={{ textAlign: 'center', padding: 32 }} className="muted">
                    No items in voucher. Use the fast entry bar above to scan or search products.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* DUAL PANEL FOOTER: LEFT ERP TABS & RIGHT COUNTER DISPLAY */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: 16, marginTop: 16 }}>
          
          {/* LEFT HORIZON ERP EXPANDABLE TABS */}
          <div style={{ background: 'var(--bg-subtle)', padding: 14, borderRadius: 8, border: '1px solid var(--border)' }}>
            <div className="pill-tabs" style={{ marginBottom: 12, width: '100%' }}>
              <button className={activeErpTab === 'dispatch' ? 'active' : ''} onClick={() => setActiveErpTab('dispatch')}>
                🚛 Dispatch Details
              </button>
              {billingType === 'GST' && (
                <button className={activeErpTab === 'ewb' ? 'active' : ''} onClick={() => setActiveErpTab('ewb')}>
                  📄 E-Way Bill
                </button>
              )}
              {billingType === 'GST' && (
                <button className={activeErpTab === 'eInvoice' ? 'active' : ''} onClick={() => setActiveErpTab('eInvoice')}>
                  ⚡ E-Invoice IRN
                </button>
              )}
              <button className={activeErpTab === 'ledger' ? 'active' : ''} onClick={() => setActiveErpTab('ledger')}>
                📑 Tax Ledgers
              </button>
            </div>

            {activeErpTab === 'dispatch' && (
              <div className="form-grid" style={{ fontSize: 12 }}>
                <div><label className="k">PO Number</label><input className="inp" style={{ width: '100%', fontSize: 12 }} value={poNumber} onChange={(e) => setPoNumber(e.target.value)} placeholder="PO-1002" /></div>
                <div><label className="k">PO Date</label><input className="inp" style={{ width: '100%', fontSize: 12 }} type="date" value={poDate} onChange={(e) => setPoDate(e.target.value)} /></div>
                <div><label className="k">Dispatch Via</label><input className="inp" style={{ width: '100%', fontSize: 12 }} value={dispatchThrough} onChange={(e) => setDispatchThrough(e.target.value)} placeholder="VRL Logistics" /></div>
                <div><label className="k">Vehicle No.</label><input className="inp" style={{ width: '100%', fontSize: 12, fontWeight: 700 }} value={vehicleNumber} onChange={(e) => setVehicleNumber(e.target.value.toUpperCase())} placeholder="TN29BF6289" /></div>
                <div><label className="k">Driver Name</label><input className="inp" style={{ width: '100%', fontSize: 12 }} value={driverName} onChange={(e) => setDriverName(e.target.value)} /></div>
                <div><label className="k">Gate Pass No</label><input className="inp" style={{ width: '100%', fontSize: 12 }} value={gatePassNo} onChange={(e) => setGatePassNo(e.target.value)} /></div>
              </div>
            )}

            {activeErpTab === 'ewb' && billingType === 'GST' && (
              <div className="form-grid" style={{ fontSize: 12 }}>
                <div><label className="k">Supply Sub Type</label><select className="sel" style={{ width: '100%', fontSize: 12 }} value={supplySubType} onChange={(e) => setSupplySubType(e.target.value)}><option>Supply</option><option>Line Sales</option></select></div>
                <div><label className="k">Transport Mode</label><select className="sel" style={{ width: '100%', fontSize: 12 }} value={transportMode} onChange={(e) => setTransportMode(e.target.value)}><option>Road</option><option>Rail</option></select></div>
                <div><label className="k">Transporter ID</label><input className="inp" style={{ width: '100%', fontSize: 12 }} value={transporterId} onChange={(e) => setTransporterId(e.target.value)} /></div>
                <div><label className="k">EWB No.</label><input className="inp" style={{ width: '100%', fontSize: 12, fontWeight: 700 }} value={ewbNo} onChange={(e) => setEwbNo(e.target.value)} placeholder="552061582233" /></div>
              </div>
            )}

            {activeErpTab === 'eInvoice' && billingType === 'GST' && (
              <div className="form-grid" style={{ fontSize: 12 }}>
                <div style={{ gridColumn: '1/-1' }}><label className="k">IRN Hash</label><input className="inp" style={{ width: '100%', fontSize: 11 }} value={irn} onChange={(e) => setIrn(e.target.value)} placeholder="9f3ce96a9aeea2f3269dcb7cab4e59b408e87564" /></div>
              </div>
            )}

            {activeErpTab === 'ledger' && (
              <div>
                <div className="table-wrap">
                  <table className="tbl" style={{ fontSize: 12 }}>
                    <thead><tr><th>Sl No</th><th>Ledger Name</th><th className="num">Amount</th></tr></thead>
                    <tbody>
                      {billCalc.ledgerEntries.map((l: any, i: number) => (
                        <tr key={i}>
                          <td>{i + 1}</td>
                          <td className="cell-strong">{l.ledgerName}</td>
                          <td className="num cell-strong">{inr(l.amount)}</td>
                        </tr>
                      ))}
                      {!billCalc.ledgerEntries.length && (
                        <tr><td colSpan={3} className="muted" style={{ textAlign: 'center', padding: 12 }}>No output tax ledgers (Non-GST billing).</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>

          {/* RIGHT HORIZON ERP COUNTER DISPLAY & ACTION STATION */}
          <div className="card" style={{ padding: 16, background: 'var(--bg-card)', border: '2px solid var(--gold)', borderRadius: 8 }}>
            <div style={{ fontSize: 12, fontWeight: 800, textTransform: 'uppercase', color: 'var(--gold)', marginBottom: 8, display: 'flex', justifyContent: 'space-between', gap: 8 }}>
              <span>VOUCHER BILL TOTALS</span>
              <span>MODE: {payMode.toUpperCase()}</span>
            </div>

            <div className="kv"><span className="k">Gross Taxable Subtotal</span><span className="v">{inr(billCalc.subtotal)}</span></div>
            <div className="kv"><span className="k">Item Discounts Total</span><span className="v">− {inr(billCalc.totalDiscount)}</span></div>
            <div className="kv">
              <span className="k">Output GST Tax</span>
              <span className="v" style={{ fontWeight: 700, color: billingType === 'GST' ? 'var(--gold)' : 'var(--text-3)' }}>
                {billingType === 'GST' ? inr(billCalc.totalGst) : '₹0 (Non-GST)'}
              </span>
            </div>
            <div className="kv"><span className="k">Round Off (+/−)</span><span className="v">{inr(billCalc.roundOff)}</span></div>

            {/* BIG HIGHLIGHTED COUNTER NET PAYABLE DISPLAY */}
            <div style={{ background: 'var(--brand)', color: '#fff', padding: '12px 16px', borderRadius: 8, marginTop: 10, textAlign: 'right', overflow: 'hidden' }}>
              <div style={{ fontSize: 11, textTransform: 'uppercase', color: 'var(--gold-soft)', letterSpacing: '1px' }}>GRAND NET PAYABLE</div>
              <div style={{ fontSize: 24, fontWeight: 900, color: 'var(--gold)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{inr(billCalc.grandTotal)}</div>
            </div>

            {/* Payment Mode Selector Buttons */}
            <div style={{ marginTop: 12 }}>
              <label className="k" style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', display: 'block', marginBottom: 6 }}>Payment Type</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
                {['Cash', 'Credit', 'UPI', 'Card'].map((mode) => (
                  <button
                    key={mode}
                    type="button"
                    className={`btn btn-sm ${payMode === mode ? 'btn-gold' : ''}`}
                    style={{ fontSize: 11, fontWeight: 700, justifyContent: 'center', padding: '6px 2px' }}
                    onClick={() => setPayMode(mode)}
                  >
                    {mode}
                  </button>
                ))}
              </div>
            </div>

            {/* Horizon ERP Action Station Buttons */}
            <div style={{ display: 'flex', gap: 8, marginTop: 16, flexWrap: 'wrap' }}>
              <button
                className="btn"
                disabled={isProcessing}
                style={{ flex: '1 1 80px', fontSize: 12, justifyContent: 'center' }}
                onClick={clearForm}
              >
                <Icon name="trash" size={14} /> Clear
              </button>
              <button
                className="btn btn-primary"
                disabled={isProcessing}
                style={{ flex: '1 1 80px', fontSize: 12, justifyContent: 'center' }}
                onClick={() => saveBill(false)}
              >
                <Icon name="check" size={14} /> {isProcessing ? 'Processing…' : 'Save (F2)'}
              </button>
              <button
                className="btn btn-gold"
                disabled={isProcessing}
                style={{ flex: '1.5 1 130px', fontSize: 12, fontWeight: 800, justifyContent: 'center' }}
                onClick={() => saveBill(true)}
              >
                <Icon name="download" size={14} /> {isProcessing ? 'Saving & Printing…' : 'Save & Print'}
              </button>
            </div>

            {/* Post-Save Quick Actions Bar */}
            {lastSavedBill && (
              <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px dashed var(--border)', display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <span style={{ width: '100%', fontSize: 11, fontWeight: 700, color: 'var(--green)' }}>
                  ✅ Saved Bill: {lastSavedBill.voucherNo} ({inr(lastSavedBill.grandTotal)})
                </span>
                <button
                  type="button"
                  className="btn btn-sm btn-gold"
                  style={{ fontSize: 11, flex: 1, justifyContent: 'center' }}
                  onClick={() => {
                    const cust = customerMap[lastSavedBill.customerId]
                    printInvoice(
                      buildInvoiceHTML({
                        id: lastSavedBill.voucherNo,
                        date: lastSavedBill.date,
                        payStatus: lastSavedBill.payStatus,
                        items: lastSavedBill.items,
                        customer: cust || { name: 'Walk-in / Cash Customer', address: lastSavedBill.address },
                        productMap,
                        company: { ...company, gstin: lastSavedBill.billingType === 'GST' ? company.gstin : '' },
                        billingType: lastSavedBill.billingType,
                        voucherNo: lastSavedBill.voucherNo,
                        grandTotal: lastSavedBill.grandTotal,
                        subtotal: lastSavedBill.subtotal,
                        gstTotal: lastSavedBill.gstTotal,
                        ledgerEntries: lastSavedBill.ledgerEntries,
                        dispatchDetails: lastSavedBill.dispatchDetails,
                        billedBy: lastSavedBill.billedBy,
                      })
                    )
                  }}
                >
                  <Icon name="download" size={12} /> Print Again
                </button>
                <button
                  type="button"
                  className="btn btn-sm"
                  style={{ fontSize: 11, flex: 1, justifyContent: 'center' }}
                  onClick={() => {
                    setLastSavedBill(null)
                    clearForm()
                  }}
                >
                  + New Bill
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
