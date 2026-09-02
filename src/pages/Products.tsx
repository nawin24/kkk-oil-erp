import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Badge, Modal, Field, Toolbar, LogoPill, EmptyState } from '../components/ui'
import Icon from '../components/Icon'
import { OIL_TYPES, PACK_SIZES, UNIT_TYPES } from '../data/seed'
import { inr, num, csvExport, uid, todayISO } from '../utils/helpers'
import type { PricingType } from '../types'

export default function Products() {
  const { products, brands, brandMap, upsert, remove, addAuditLog } = useData()
  const [q, setQ] = useState('')
  const [brand, setBrand] = useState('all')
  const [oil, setOil] = useState('all')
  const [pricingType, setPricingType] = useState<PricingType>('RETAIL')
  const [edit, setEdit] = useState<any>(null)
  const [formErr, setFormErr] = useState('')

  const rows = useMemo(() => products.filter((p: any) => {
    if (brand !== 'all' && p.brandId !== brand) return false
    if (oil !== 'all' && p.oilType !== oil) return false
    if (q && !(`${p.name} ${p.code || ''} ${p.sku}`.toLowerCase().includes(q.toLowerCase()))) return false
    return true
  }), [products, brand, oil, q])

  const blank = {
    id: uid('P'),
    code: `PRD-${Math.floor(100 + Math.random() * 900)}`,
    brandId: brands[0]?.id,
    name: '',
    category: 'Edible Oils',
    oilType: OIL_TYPES[0],
    pack: '1 L',
    unit: 'Bottle',
    sku: '',
    hsn: '1508',
    gst: 5,
    cost: 0,
    agencyRate: 0,
    wholesaleRate: 0,
    retailRate: 0,
    price: 0,
    mrp: 0,
    minStock: 10,
    stock: 0,
    status: 'Active',
  }

  const getDisplayedRate = (p: any) => {
    if (pricingType === 'AGENCY') return p.agencyRate ?? p.price ?? 0
    if (pricingType === 'WHOLESALE') return p.wholesaleRate ?? p.price ?? 0
    return p.retailRate ?? p.price ?? 0
  }

  const save = (e: any) => {
    e.preventDefault()
    setFormErr('')
    const f = new FormData(e.target)
    const code = String(f.get('code') || '').trim()
    const name = String(f.get('name') || '').trim()
    const agencyRate = Math.max(0, Number(f.get('agencyRate')) || 0)
    const wholesaleRate = Math.max(0, Number(f.get('wholesaleRate')) || 0)
    const retailRate = Math.max(0, Number(f.get('retailRate')) || 0)
    const cost = Math.max(0, Number(f.get('cost')) || 0)
    const mrp = Math.max(0, Number(f.get('mrp')) || 0)

    // Check duplicate code
    const isNew = !products.some((p: any) => p.id === edit.id)
    if (isNew && products.some((p: any) => p.code?.toLowerCase() === code.toLowerCase())) {
      setFormErr(`Product Code "${code}" already exists. Please use a unique code.`)
      return
    }

    const record = {
      id: edit.id,
      code: code || edit.sku || edit.id,
      brandId: f.get('brandId'),
      name,
      category: f.get('category') || 'Edible Oils',
      oilType: f.get('oilType'),
      pack: f.get('pack'),
      unit: f.get('unit'),
      sku: f.get('sku') || code,
      hsn: f.get('hsn'),
      gst: Math.max(0, Number(f.get('gst')) || 0),
      cost,
      agencyRate,
      wholesaleRate,
      retailRate,
      price: retailRate, // Retail fallback
      mrp,
      minStock: Math.max(0, Number(f.get('minStock')) || 0),
      stock: Math.max(0, Number(f.get('stock')) || 0),
      status: f.get('status') || 'Active',
      updatedDate: todayISO(),
      createdDate: edit.createdDate || todayISO(),
    }

    upsert('products', record)
    addAuditLog(null, isNew ? 'PRODUCT_CREATED' : 'PRODUCT_UPDATED', 'PRODUCTS', isNew ? undefined : edit.name, name)
    setEdit(null)
  }

  return (
    <div className="page">
      <PageHeader title="Product Master" subtitle={`${products.length} Central Master Products — manage SKUs, AWR rates, HSN codes, and inventory levels.`}>
        <button className="btn" onClick={() => csvExport('products.csv', rows.map((p) => ({ ...p, brand: brandMap[p.brandId]?.name })))}><Icon name="download" /> Export</button>
        <button className="btn btn-gold" onClick={() => { setFormErr(''); setEdit(blank) }}><Icon name="plus" /> Add Product</button>
      </PageHeader>

      <Toolbar search={q} onSearch={setQ} placeholder="Search product name, code, SKU…">
        {/* AWR Pricing Selector */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginRight: 12, background: 'var(--bg-card)', padding: '3px 6px', borderRadius: 8, border: '1px solid var(--border)' }}>
          <span className="tiny" style={{ fontWeight: 700, textTransform: 'uppercase', marginRight: 4, color: 'var(--text-3)' }}>View Rate:</span>
          <button
            type="button"
            className={`btn btn-sm ${pricingType === 'AGENCY' ? 'btn-gold' : ''}`}
            style={{ padding: '3px 10px', fontSize: 12 }}
            onClick={() => setPricingType('AGENCY')}
          >
            AGENCY
          </button>
          <button
            type="button"
            className={`btn btn-sm ${pricingType === 'WHOLESALE' ? 'btn-gold' : ''}`}
            style={{ padding: '3px 10px', fontSize: 12 }}
            onClick={() => setPricingType('WHOLESALE')}
          >
            WHOLESALE
          </button>
          <button
            type="button"
            className={`btn btn-sm ${pricingType === 'RETAIL' ? 'btn-gold' : ''}`}
            style={{ padding: '3px 10px', fontSize: 12 }}
            onClick={() => setPricingType('RETAIL')}
          >
            RETAIL
          </button>
        </div>

        <select className="sel" value={brand} onChange={(e) => setBrand(e.target.value)}>
          <option value="all">All Brands</option>
          {brands.map((b: any) => <option key={b.id} value={b.id}>{b.name}</option>)}
        </select>

        <select className="sel" value={oil} onChange={(e) => setOil(e.target.value)}>
          <option value="all">All Oil Types</option>
          {OIL_TYPES.map((o) => <option key={o}>{o}</option>)}
        </select>

        <div className="spacer" />
        <span className="tiny">{rows.length} shown</span>
      </Toolbar>

      <div className="card table-wrap">
        <table className="tbl">
          <thead>
            <tr>
              <th>Code / Product</th>
              <th>Category / Oil Type</th>
              <th>SKU / HSN</th>
              <th>Pack &amp; Unit</th>
              <th className="num">Cost</th>
              <th className="num" style={{ color: 'var(--gold)' }}>{pricingType} Rate</th>
              <th className="num">MRP</th>
              <th className="num">Stock</th>
              <th>GST</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p: any) => {
              const low = p.stock <= p.minStock
              const b = brandMap[p.brandId]
              const rate = getDisplayedRate(p)
              return (
                <tr key={p.id}>
                  <td>
                    <div className="with-logo">
                      <LogoPill name={b?.name || '?'} color={b?.color} />
                      <div>
                        <div className="cell-strong">{p.name}</div>
                        <div className="cell-sub"><span style={{ fontWeight: 700, color: 'var(--gold)' }}>{p.code || p.sku}</span> · {b?.name}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div className="cell-strong" style={{ fontSize: 12 }}>{p.category || 'Edible Oils'}</div>
                    <div className="cell-sub">{p.oilType}</div>
                  </td>
                  <td>
                    <div className="cell-strong" style={{ fontSize: 12 }}>{p.sku}</div>
                    <div className="cell-sub">HSN {p.hsn}</div>
                  </td>
                  <td>{p.pack} ({p.unit})</td>
                  <td className="num muted">{inr(p.cost)}</td>
                  <td className="num cell-strong" style={{ color: 'var(--gold)', fontSize: 14 }}>{inr(rate)}</td>
                  <td className="num muted">{inr(p.mrp)}</td>
                  <td className="num">
                    <span style={{ fontWeight: 600, color: low ? 'var(--red)' : 'inherit' }}>{num(p.stock)}</span>
                    {low && <div><Badge tone="red" noDot>Low</Badge></div>}
                  </td>
                  <td><Badge tone="gray" noDot>{p.gst}%</Badge></td>
                  <td>
                    <Badge tone={p.status === 'Inactive' ? 'red' : 'green'} noDot>
                      {p.status || 'Active'}
                    </Badge>
                  </td>
                  <td>
                    <div className="row-actions">
                      <button onClick={() => { setFormErr(''); setEdit(p) }} title="Edit Product & Rates"><Icon name="edit" size={15} /></button>
                      <button className="del" onClick={() => window.confirm('Delete product?') && remove('products', p.id)} title="Delete"><Icon name="trash" size={15} /></button>
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
        {!rows.length && <EmptyState icon="products" text="No products match your filters" />}
      </div>

      {edit && (
        <Modal lg title={products.some((p: any) => p.id === edit.id) ? `Edit Product · ${edit.name}` : 'Add Product'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="prodForm">Save Product</button></>}>
          <form id="prodForm" onSubmit={save} className="form-grid">
            {formErr && <div style={{ gridColumn: '1/-1', color: 'var(--red)', background: 'var(--red-soft)', padding: '8px 12px', borderRadius: 6, fontSize: 13, fontWeight: 600 }}>{formErr}</div>}

            <Field label="Product Code"><input className="inp" name="code" defaultValue={edit.code || edit.sku} required placeholder="e.g. PRD-101" /></Field>
            <Field label="Product Name" full><input className="inp" name="name" defaultValue={edit.name} required placeholder="e.g. KKK Gold Groundnut Oil 1L" /></Field>

            <Field label="Brand"><select className="sel" name="brandId" defaultValue={edit.brandId}>{brands.map((b: any) => <option key={b.id} value={b.id}>{b.name}</option>)}</select></Field>
            <Field label="Category"><input className="inp" name="category" defaultValue={edit.category || 'Edible Oils'} required /></Field>
            <Field label="Oil Type"><select className="sel" name="oilType" defaultValue={edit.oilType}>{OIL_TYPES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="Pack Size"><select className="sel" name="pack" defaultValue={edit.pack}>{PACK_SIZES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="Unit Type"><select className="sel" name="unit" defaultValue={edit.unit}>{UNIT_TYPES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="SKU / Barcode"><input className="inp" name="sku" defaultValue={edit.sku || edit.code} required /></Field>
            <Field label="HSN Code"><input className="inp" name="hsn" defaultValue={edit.hsn} required /></Field>
            <Field label="GST Rate (%)"><input className="inp" type="number" min="0" step="0.01" name="gst" defaultValue={edit.gst} required /></Field>
            <Field label="MRP (₹)"><input className="inp" type="number" min="0" step="0.01" name="mrp" defaultValue={edit.mrp} required /></Field>
            <Field label="Purchase / Cost Rate (₹)"><input className="inp" type="number" min="0" step="0.01" name="cost" defaultValue={edit.cost} required /></Field>

            {/* AWR Selling Rates */}
            <div style={{ gridColumn: '1/-1', borderTop: '1px solid var(--border)', paddingTop: 12, marginTop: 6 }}>
              <h4 style={{ fontSize: 13, fontWeight: 700, color: 'var(--gold)', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '.5px' }}>
                Three Selling Rates (AWR Pricing Model)
              </h4>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
                <Field label="1. Agency Rate (₹)">
                  <input className="inp" type="number" min="0" step="0.01" name="agencyRate" defaultValue={edit.agencyRate ?? edit.price} required />
                </Field>
                <Field label="2. Wholesale Rate (₹)">
                  <input className="inp" type="number" min="0" step="0.01" name="wholesaleRate" defaultValue={edit.wholesaleRate ?? edit.price} required />
                </Field>
                <Field label="3. Retail Rate (₹)">
                  <input className="inp" type="number" min="0" step="0.01" name="retailRate" defaultValue={edit.retailRate ?? edit.price} required />
                </Field>
              </div>
            </div>

            <Field label="Opening / Current Stock"><input className="inp" type="number" min="0" name="stock" defaultValue={edit.stock} required /></Field>
            <Field label="Min Stock Alert Level"><input className="inp" type="number" min="0" name="minStock" defaultValue={edit.minStock} required /></Field>
            <Field label="Status"><select className="sel" name="status" defaultValue={edit.status || 'Active'}><option value="Active">Active</option><option value="Inactive">Inactive</option></select></Field>
          </form>
        </Modal>
      )}
    </div>
  )
}

