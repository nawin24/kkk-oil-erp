import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { useAuth } from '../context/AuthContext'
import { PageHeader, Badge, Modal, Field, Toolbar, EmptyState } from '../components/ui'
import Icon from '../components/Icon'
import { inr, todayISO } from '../utils/helpers'

export default function PriceManagement() {
  const { products, upsert, priceHistory, addAuditLog } = useData()
  const { user, canEditPrices } = useAuth()
  const [q, setQ] = useState('')

  // Single Edit Modal State
  const [selectedProd, setSelectedProd] = useState<any>(null)
  const [agencyRate, setAgencyRate] = useState<number>(0)
  const [wholesaleRate, setWholesaleRate] = useState<number>(0)
  const [retailRate, setRetailRate] = useState<number>(0)
  const [mrp, setMrp] = useState<number>(0)
  const [effectiveDate, setEffectiveDate] = useState<string>(todayISO())
  const [msg, setMsg] = useState('')

  const filtered = useMemo(() => {
    return products.filter((p: any) =>
      !q || `${p.name} ${p.code || ''} ${p.sku}`.toLowerCase().includes(q.toLowerCase())
    )
  }, [products, q])

  const openSingleEditModal = (p: any) => {
    setSelectedProd(p)
    setAgencyRate(p.agencyRate ?? p.price ?? 0)
    setWholesaleRate(p.wholesaleRate ?? p.price ?? 0)
    setRetailRate(p.retailRate ?? p.price ?? 0)
    setMrp(p.mrp ?? 0)
    setEffectiveDate(todayISO())
    setMsg('')
  }

  const handleSaveAllPrices = (e: any) => {
    e.preventDefault()
    if (!selectedProd) return
    if (agencyRate < 0 || wholesaleRate < 0 || retailRate < 0) {
      setMsg('Rates cannot be negative.')
      return
    }

    const updatedProduct = {
      ...selectedProd,
      agencyRate: Number(agencyRate),
      wholesaleRate: Number(wholesaleRate),
      retailRate: Number(retailRate),
      price: Number(retailRate), // Default price fallback
      mrp: Number(mrp),
      updatedDate: todayISO(),
    }

    // Save directly to Firebase Firestore & local state
    upsert('products', updatedProduct)

    addAuditLog(
      user,
      'PRICE_CHANGE',
      'PRICE_MANAGEMENT',
      `Old Rates - Agency: ₹${selectedProd.agencyRate}, Wholesale: ₹${selectedProd.wholesaleRate}, Retail: ₹${selectedProd.retailRate}`,
      `New Rates - Agency: ₹${agencyRate}, Wholesale: ₹${wholesaleRate}, Retail: ₹${retailRate}`
    )

    setMsg('✅ Rates & MRP updated and saved to backend!')
    setTimeout(() => {
      setSelectedProd(null)
    }, 1000)
  }

  if (!canEditPrices) {
    return (
      <div className="page">
        <PageHeader title="Price Management" subtitle="Access Restricted" />
        <div className="card card-pad" style={{ color: 'var(--red)' }}>
          ⚠️ You do not have permission to modify master product prices.
        </div>
      </div>
    )
  }

  return (
    <div className="page">
      <PageHeader
        title="Price Management"
        subtitle="Single unified price modifier for Agency, Wholesale, and Retail rates directly synced to Firebase backend."
      />

      <Toolbar search={q} onSearch={setQ} placeholder="Search product name or code…">
        <span className="tiny" style={{ marginLeft: 'auto' }}>{filtered.length} products</span>
      </Toolbar>

      <div className="card table-wrap">
        <table className="tbl">
          <thead>
            <tr>
              <th>Code / Product Name</th>
              <th className="num">Cost Rate</th>
              <th className="num">MRP</th>
              <th className="num" style={{ color: 'var(--gold)' }}>Agency Rate</th>
              <th className="num" style={{ color: 'var(--blue)' }}>Wholesale Rate</th>
              <th className="num" style={{ color: 'var(--green)' }}>Retail Rate</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((p: any) => (
              <tr key={p.id}>
                <td>
                  <div className="cell-strong">{p.name}</div>
                  <div className="cell-sub"><span style={{ fontWeight: 700, color: 'var(--gold)' }}>{p.code || p.sku}</span> · {p.pack}</div>
                </td>
                <td className="num muted">{inr(p.cost)}</td>
                <td className="num muted">{inr(p.mrp)}</td>
                <td className="num cell-strong" style={{ color: 'var(--gold)' }}>{inr(p.agencyRate ?? p.price)}</td>
                <td className="num cell-strong" style={{ color: 'var(--blue)' }}>{inr(p.wholesaleRate ?? p.price)}</td>
                <td className="num cell-strong" style={{ color: 'var(--green)' }}>{inr(p.retailRate ?? p.price)}</td>
                <td>
                  {/* Single Unified Edit Button */}
                  <button
                    className="btn btn-sm btn-gold"
                    onClick={() => openSingleEditModal(p)}
                    style={{ fontSize: 12, fontWeight: 700 }}
                  >
                    <Icon name="edit" size={14} /> Edit &amp; Modify Rates
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!filtered.length && <EmptyState icon="products" text="No products found" />}
      </div>

      {/* SINGLE UNIFIED EDIT & MODIFY MODAL */}
      {selectedProd && (
        <Modal
          title={`Edit & Modify Rates · ${selectedProd.name}`}
          onClose={() => setSelectedProd(null)}
          footer={
            <>
              <button className="btn" onClick={() => setSelectedProd(null)}>Cancel</button>
              <button className="btn btn-primary" form="singlePriceForm">Save Changes to Backend</button>
            </>
          }
        >
          <form id="singlePriceForm" onSubmit={handleSaveAllPrices} className="form-grid">
            {msg && (
              <div style={{ gridColumn: '1/-1', padding: '8px 12px', background: 'var(--gold-soft)', borderRadius: 6, fontSize: 13, fontWeight: 600, color: 'var(--gold-deep)' }}>
                {msg}
              </div>
            )}

            <div style={{ gridColumn: '1/-1', background: 'var(--bg-subtle)', padding: 12, borderRadius: 8, fontSize: 12 }}>
              <div className="cell-strong" style={{ color: 'var(--gold)' }}>Product Code: {selectedProd.code || selectedProd.sku}</div>
              <div><b>Pack / Unit:</b> {selectedProd.pack} ({selectedProd.unit})</div>
              <div><b>Cost Price:</b> {inr(selectedProd.cost)}</div>
            </div>

            <Field label="MRP (Maximum Retail Price ₹)">
              <input
                className="inp"
                type="number"
                step="0.01"
                min="0"
                value={mrp}
                onChange={(e) => setMrp(Number(e.target.value))}
                required
              />
            </Field>

            <Field label="Effective Date">
              <input
                className="inp"
                type="date"
                value={effectiveDate}
                onChange={(e) => setEffectiveDate(e.target.value)}
                required
              />
            </Field>

            <div style={{ gridColumn: '1/-1', borderTop: '1px solid var(--border)', paddingTop: 10, marginTop: 4 }}>
              <h4 style={{ fontSize: 12, fontWeight: 800, textTransform: 'uppercase', color: 'var(--gold)', marginBottom: 8 }}>
                Modify All 3 Rates in One Place (AWR Model)
              </h4>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
                <div>
                  <label className="k" style={{ fontSize: 11, fontWeight: 700, color: 'var(--gold)' }}>1. Agency Rate (₹)</label>
                  <input
                    className="inp"
                    type="number"
                    step="0.01"
                    min="0"
                    style={{ width: '100%', fontWeight: 700, color: 'var(--gold)' }}
                    value={agencyRate}
                    onChange={(e) => setAgencyRate(Number(e.target.value))}
                    required
                  />
                </div>
                <div>
                  <label className="k" style={{ fontSize: 11, fontWeight: 700, color: 'var(--blue)' }}>2. Wholesale Rate (₹)</label>
                  <input
                    className="inp"
                    type="number"
                    step="0.01"
                    min="0"
                    style={{ width: '100%', fontWeight: 700, color: 'var(--blue)' }}
                    value={wholesaleRate}
                    onChange={(e) => setWholesaleRate(Number(e.target.value))}
                    required
                  />
                </div>
                <div>
                  <label className="k" style={{ fontSize: 11, fontWeight: 700, color: 'var(--green)' }}>3. Retail Rate (₹)</label>
                  <input
                    className="inp"
                    type="number"
                    step="0.01"
                    min="0"
                    style={{ width: '100%', fontWeight: 700, color: 'var(--green)' }}
                    value={retailRate}
                    onChange={(e) => setRetailRate(Number(e.target.value))}
                    required
                  />
                </div>
              </div>
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}
