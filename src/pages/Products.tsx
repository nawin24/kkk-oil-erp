import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Badge, Modal, Field, Toolbar, LogoPill, EmptyState } from '../components/ui'
import Icon from '../components/Icon'
import { OIL_TYPES, PACK_SIZES, UNIT_TYPES } from '../data/seed'
import { inr, num, csvExport, uid, todayISO } from '../utils/helpers'
import { exportToExcel, parseExcelOrCsv } from '../utils/excel'
import type { PricingType } from '../types'

export default function Products() {
  const { products, brands, brandMap, upsert, remove, addAuditLog } = useData()
  const [q, setQ] = useState('')
  const [brand, setBrand] = useState('all')
  const [oil, setOil] = useState('all')
  const [pricingType, setPricingType] = useState<PricingType>('RETAIL')
  const [edit, setEdit] = useState<any>(null)
  const [formErr, setFormErr] = useState('')

  // Import Modal State
  const [showImportModal, setShowImportModal] = useState(false)
  const [importPreview, setImportPreview] = useState<any[]>([])
  const [importError, setImportError] = useState('')
  const [importSuccessMsg, setImportSuccessMsg] = useState('')

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

  // Template Download Handler (.xlsx Excel & .csv)
  const downloadTemplate = (format: 'xlsx' | 'csv' = 'xlsx') => {
    const templateRows = [
      {
        'Code*': 'PRD-101',
        'Name*': 'KKK Gold Groundnut Oil 1L',
        'Brand*': 'KKK Gold',
        'Category': 'Edible Oils',
        'Oil Type': 'Groundnut Oil',
        'Pack Size': '1 L',
        'Unit Type': 'Bottle',
        'SKU': 'KKK-GN-1L',
        'HSN Code': '1508',
        'GST Rate %': 5,
        'Cost Price (₹)*': 165,
        'Agency Rate (₹)*': 180,
        'Wholesale Rate (₹)*': 190,
        'Retail Rate (₹)*': 198,
        'MRP (₹)*': 215,
        'Min Stock': 20,
        'Initial Stock': 100
      },
      {
        'Code*': 'PRD-102',
        'Name*': 'Anjali Gingelly Oil 500ml',
        'Brand*': 'Anjali Oils',
        'Category': 'Edible Oils',
        'Oil Type': 'Gingelly Oil',
        'Pack Size': '500 ml',
        'Unit Type': 'Bottle',
        'SKU': 'ANJ-GG-500ML',
        'HSN Code': '1508',
        'GST Rate %': 5,
        'Cost Price (₹)*': 90,
        'Agency Rate (₹)*': 105,
        'Wholesale Rate (₹)*': 112,
        'Retail Rate (₹)*': 118,
        'MRP (₹)*': 125,
        'Min Stock': 15,
        'Initial Stock': 80
      }
    ]
    if (format === 'csv') {
      csvExport('product_import_template.csv', templateRows)
    } else {
      exportToExcel('product_import_template.xlsx', templateRows, 'Template')
    }
  }

  // Native Excel (.xlsx, .xls) and CSV (.csv) Parser
  const handleFileImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setImportError('')
    setImportSuccessMsg('')

    try {
      const rawRows = await parseExcelOrCsv(file)
      if (!rawRows || !rawRows.length) {
        setImportError('The uploaded file is empty or missing data rows.')
        return
      }

      const parsedRecords: any[] = rawRows.map((rowObj: any, index: number) => {
        const findVal = (...keys: string[]) => {
          for (const k of keys) {
            const keyFound = Object.keys(rowObj).find(
              (rk) => rk.toLowerCase().replace(/[*"₹()]/g, '').trim() === k.toLowerCase().trim()
            )
            if (keyFound && rowObj[keyFound] !== undefined && rowObj[keyFound] !== '') {
              return String(rowObj[keyFound]).trim()
            }
          }
          return ''
        }

        const code = findVal('code', 'product code', 'sku') || `PRD-${Math.floor(100 + Math.random() * 900)}`
        const name = findVal('name', 'product name')
        const brandName = findVal('brand', 'brand name')
        const cost = Number(findVal('cost price', 'cost', 'purchase rate') || 0)
        const agencyRate = Number(findVal('agency rate', 'agency') || 0)
        const wholesaleRate = Number(findVal('wholesale rate', 'wholesale') || 0)
        const retailRate = Number(findVal('retail rate', 'retail', 'price') || 0)
        const mrp = Number(findVal('mrp') || 0)
        const initialStock = Number(findVal('initial stock', 'stock') || 0)

        let brandId = brands.find((b: any) => b.name.toLowerCase() === brandName.toLowerCase())?.id || brands[0]?.id || 'B1'
        const isValid = Boolean(code && name && cost >= 0 && (agencyRate > 0 || wholesaleRate > 0 || retailRate > 0))

        return {
          id: uid('P'),
          code,
          name,
          brandId,
          brandName: brandMap[brandId]?.name || brandName || 'KKK Gold',
          category: findVal('category') || 'Edible Oils',
          oilType: findVal('oil type') || OIL_TYPES[0],
          pack: findVal('pack size', 'pack') || '1 L',
          unit: findVal('unit type', 'unit') || 'Bottle',
          sku: findVal('sku') || code,
          hsn: findVal('hsn code', 'hsn') || '1508',
          gst: Number(findVal('gst rate %', 'gst') || 5),
          cost,
          agencyRate: agencyRate || retailRate,
          wholesaleRate: wholesaleRate || retailRate,
          retailRate: retailRate || wholesaleRate || agencyRate,
          price: retailRate || wholesaleRate || agencyRate,
          mrp: mrp || (retailRate * 1.1),
          minStock: Number(findVal('min stock') || 10),
          stock: initialStock,
          status: 'Active',
          isValid,
          rowNum: index + 2,
        }
      })

      setImportPreview(parsedRecords)
    } catch (err) {
      setImportError('Failed to parse file. Please upload a valid Excel (.xlsx, .xls) or CSV (.csv) file.')
    }
  }

  const confirmImport = () => {
    const validRows = importPreview.filter((r) => r.isValid)
    if (!validRows.length) {
      setImportError('No valid rows found to import.')
      return
    }

    validRows.forEach((r) => {
      const record = {
        id: r.id,
        code: r.code,
        name: r.name,
        brandId: r.brandId,
        category: r.category,
        oilType: r.oilType,
        pack: r.pack,
        unit: r.unit,
        sku: r.sku,
        hsn: r.hsn,
        gst: r.gst,
        cost: r.cost,
        agencyRate: r.agencyRate,
        wholesaleRate: r.wholesaleRate,
        retailRate: r.retailRate,
        price: r.retailRate,
        mrp: r.mrp,
        minStock: r.minStock,
        stock: r.stock,
        status: 'Active',
        createdDate: todayISO(),
        updatedDate: todayISO(),
      }
      upsert('products', record)
    })

    addAuditLog(null, 'PRODUCTS_IMPORTED', 'PRODUCTS', undefined, `Imported ${validRows.length} products via Excel/CSV`)
    setImportSuccessMsg(`✅ Successfully imported ${validRows.length} products! Saved to database & Firestore.`)
    setImportPreview([])
    setTimeout(() => setShowImportModal(false), 1200)
  }

  return (
    <div className="page">
      <PageHeader title="Product Master" subtitle={`${products.length} Central Master Products — manage SKUs, AWR rates, HSN codes, and inventory levels.`}>
        <button
          className="btn"
          onClick={() =>
            exportToExcel(
              'products_master_export.xlsx',
              rows.map((p) => ({
                Code: p.code,
                Name: p.name,
                Brand: brandMap[p.brandId]?.name || 'KKK Gold',
                Category: p.category,
                'Oil Type': p.oilType,
                Pack: p.pack,
                Unit: p.unit,
                SKU: p.sku,
                HSN: p.hsn,
                'GST %': p.gst,
                'Cost Rate (₹)': p.cost,
                'Agency Rate (₹)': p.agencyRate,
                'Wholesale Rate (₹)': p.wholesaleRate,
                'Retail Rate (₹)': p.retailRate,
                'MRP (₹)': p.mrp,
                Stock: p.stock,
                MinStock: p.minStock,
                Status: p.status || 'Active',
              })),
              'Products'
            )
          }
        >
          <Icon name="download" /> Export Excel (.xlsx)
        </button>
        <button
          className="btn btn-primary"
          onClick={() => {
            setImportError('')
            setImportSuccessMsg('')
            setImportPreview([])
            setShowImportModal(true)
          }}
        >
          <Icon name="download" size={14} /> Import Products
        </button>
        <button className="btn btn-gold" onClick={() => { setFormErr(''); setEdit(blank) }}>
          <Icon name="plus" /> Add Product
        </button>
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
              <th style={{ minWidth: 200 }}>AWR Rates (Agency / Wholesale / Retail)</th>
              <th className="num">MRP</th>
              <th className="num">Stock</th>
              <th>GST</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p: any) => {
              const low = p.stock <= p.minStock
              const b = brandMap[p.brandId]
              const agency = p.agencyRate ?? p.price ?? 0
              const wholesale = p.wholesaleRate ?? p.price ?? 0
              const retail = p.retailRate ?? p.price ?? 0

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
                  {/* 3-Tier Differentiated AWR Selling Rates */}
                  <td>
                    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', alignItems: 'center' }}>
                      <span className={`badge ${pricingType === 'AGENCY' ? 'gold' : 'gray'}`} style={{ fontSize: 11, fontWeight: pricingType === 'AGENCY' ? 800 : 500 }} title="Agency / Distributor Rate">
                        A: {inr(agency)}
                      </span>
                      <span className={`badge ${pricingType === 'WHOLESALE' ? 'blue' : 'gray'}`} style={{ fontSize: 11, fontWeight: pricingType === 'WHOLESALE' ? 800 : 500 }} title="Wholesale / Dealer Rate">
                        W: {inr(wholesale)}
                      </span>
                      <span className={`badge ${pricingType === 'RETAIL' ? 'green' : 'gray'}`} style={{ fontSize: 11, fontWeight: pricingType === 'RETAIL' ? 800 : 500 }} title="Retail / Counter Rate">
                        R: {inr(retail)}
                      </span>
                    </div>
                  </td>
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
                      <button className="del" onClick={() => window.confirm(`Delete product "${p.name}"?`) && remove('products', p.id)} title="Delete"><Icon name="trash" size={15} /></button>
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
        {!rows.length && <EmptyState icon="products" text="No products match your filters" />}
      </div>

      {/* Add / Edit Product Modal */}
      {edit && (
        <Modal lg title={products.some((p: any) => p.id === edit.id) ? `Edit Product · ${edit.name}` : 'Add Product'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="prodForm">Save Product</button></>}>
          <form id="prodForm" onSubmit={save} className="form-grid">
            {formErr && <div style={{ gridColumn: '1/-1', color: 'var(--red)', background: 'var(--red-soft)', padding: '8px 12px', borderRadius: 6, fontSize: 13, fontWeight: 600 }}>{formErr}</div>}

            <Field label="Product Code *"><input className="inp" name="code" defaultValue={edit.code || edit.sku} required placeholder="e.g. PRD-101" /></Field>
            <Field label="Product Name *" full><input className="inp" name="name" defaultValue={edit.name} required placeholder="e.g. KKK Gold Groundnut Oil 1L" /></Field>

            <Field label="Brand *"><select className="sel" name="brandId" defaultValue={edit.brandId}>{brands.map((b: any) => <option key={b.id} value={b.id}>{b.name}</option>)}</select></Field>
            <Field label="Category"><input className="inp" name="category" defaultValue={edit.category || 'Edible Oils'} required /></Field>
            <Field label="Oil Type"><select className="sel" name="oilType" defaultValue={edit.oilType}>{OIL_TYPES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="Pack Size"><select className="sel" name="pack" defaultValue={edit.pack}>{PACK_SIZES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="Unit Type"><select className="sel" name="unit" defaultValue={edit.unit}>{UNIT_TYPES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="SKU / Barcode"><input className="inp" name="sku" defaultValue={edit.sku || edit.code} required /></Field>
            <Field label="HSN Code"><input className="inp" name="hsn" defaultValue={edit.hsn} required /></Field>
            <Field label="GST Rate (%)"><input className="inp" type="number" min="0" step="0.01" name="gst" defaultValue={edit.gst} required /></Field>
            <Field label="MRP (₹) *"><input className="inp" type="number" min="0" step="0.01" name="mrp" defaultValue={edit.mrp} required /></Field>
            <Field label="Purchase / Cost Rate (₹) *"><input className="inp" type="number" min="0" step="0.01" name="cost" defaultValue={edit.cost} required /></Field>

            {/* AWR Selling Rates */}
            <div style={{ gridColumn: '1/-1', borderTop: '1px solid var(--border)', paddingTop: 12, marginTop: 6 }}>
              <h4 style={{ fontSize: 13, fontWeight: 700, color: 'var(--gold)', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '.5px' }}>
                Three Selling Rates (AWR Pricing Model)
              </h4>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
                <Field label="1. Agency Rate (₹) *">
                  <input className="inp" type="number" min="0" step="0.01" name="agencyRate" defaultValue={edit.agencyRate ?? edit.price} required style={{ borderLeft: '3px solid var(--gold)' }} />
                </Field>
                <Field label="2. Wholesale Rate (₹) *">
                  <input className="inp" type="number" min="0" step="0.01" name="wholesaleRate" defaultValue={edit.wholesaleRate ?? edit.price} required style={{ borderLeft: '3px solid var(--blue)' }} />
                </Field>
                <Field label="3. Retail Rate (₹) *">
                  <input className="inp" type="number" min="0" step="0.01" name="retailRate" defaultValue={edit.retailRate ?? edit.price} required style={{ borderLeft: '3px solid var(--green)' }} />
                </Field>
              </div>
            </div>

            <Field label="Opening / Current Stock"><input className="inp" type="number" min="0" name="stock" defaultValue={edit.stock} required /></Field>
            <Field label="Min Stock Alert Level"><input className="inp" type="number" min="0" name="minStock" defaultValue={edit.minStock} required /></Field>
            <Field label="Status"><select className="sel" name="status" defaultValue={edit.status || 'Active'}><option value="Active">Active</option><option value="Inactive">Inactive</option></select></Field>
          </form>
        </Modal>
      )}

      {/* Import Products via Excel / CSV Modal */}
      {showImportModal && (
        <Modal
          lg
          title="📥 Import Products via Excel / CSV"
          onClose={() => setShowImportModal(false)}
          footer={
            <>
              <button className="btn" onClick={() => setShowImportModal(false)}>Cancel</button>
              <button
                className="btn btn-primary"
                disabled={!importPreview.some((r) => r.isValid)}
                onClick={confirmImport}
              >
                Confirm &amp; Import Products ({importPreview.filter((r) => r.isValid).length})
              </button>
            </>
          }
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div style={{ background: 'var(--surface-2)', padding: 14, borderRadius: 8, border: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h4 style={{ fontSize: 14, fontWeight: 700, margin: 0, color: 'var(--text)' }}>Download Pre-formatted Template</h4>
                <p className="tiny" style={{ margin: '4px 0 0 0', color: 'var(--text-2)' }}>
                  Contains mandatory fields marked with (*): Code*, Name*, Brand*, Cost*, Agency*, Wholesale*, Retail*, MRP*.
                </p>
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <button className="btn btn-sm btn-gold" onClick={() => downloadTemplate('xlsx')}>
                  <Icon name="download" size={14} /> Excel (.xlsx)
                </button>
                <button className="btn btn-sm" onClick={() => downloadTemplate('csv')}>
                  <Icon name="download" size={14} /> CSV (.csv)
                </button>
              </div>
            </div>

            <div className="field">
              <label style={{ fontWeight: 700 }}>Select Excel or CSV File to Upload</label>
              <input
                type="file"
                accept=".csv, .xlsx, .xls, .txt"
                className="inp"
                style={{ padding: 10 }}
                onChange={handleFileImport}
              />
            </div>

            {importError && (
              <div style={{ background: 'var(--red-soft)', color: 'var(--red)', padding: '10px 14px', borderRadius: 6, fontWeight: 600, fontSize: 13 }}>
                {importError}
              </div>
            )}

            {importSuccessMsg && (
              <div style={{ background: 'var(--green-soft)', color: 'var(--green)', padding: '10px 14px', borderRadius: 6, fontWeight: 600, fontSize: 13 }}>
                {importSuccessMsg}
              </div>
            )}

            {importPreview.length > 0 && (
              <div>
                <h4 style={{ fontSize: 13, fontWeight: 700, textTransform: 'uppercase', marginBottom: 8, color: 'var(--gold)' }}>
                  Import Preview ({importPreview.filter((r) => r.isValid).length} Valid / {importPreview.length} Total Rows)
                </h4>
                <div className="table-wrap" style={{ maxHeight: 250, overflowY: 'auto' }}>
                  <table className="tbl" style={{ fontSize: 12 }}>
                    <thead>
                      <tr>
                        <th>Row</th>
                        <th>Code</th>
                        <th>Product Name</th>
                        <th>Brand</th>
                        <th className="num">Cost</th>
                        <th className="num">Agency</th>
                        <th className="num">Wholesale</th>
                        <th className="num">Retail</th>
                        <th className="num">MRP</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {importPreview.map((r, i) => (
                        <tr key={i} style={{ background: r.isValid ? 'transparent' : 'var(--red-soft)' }}>
                          <td>#{r.rowNum}</td>
                          <td className="cell-strong">{r.code}</td>
                          <td>{r.name}</td>
                          <td>{r.brandName}</td>
                          <td className="num">{inr(r.cost)}</td>
                          <td className="num">{inr(r.agencyRate)}</td>
                          <td className="num">{inr(r.wholesaleRate)}</td>
                          <td className="num">{inr(r.retailRate)}</td>
                          <td className="num">{inr(r.mrp)}</td>
                          <td>
                            <Badge tone={r.isValid ? 'green' : 'red'} noDot>
                              {r.isValid ? 'Valid' : 'Invalid Data'}
                            </Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        </Modal>
      )}
    </div>
  )
}
