import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext.jsx'
import { PageHeader, Badge, Modal, Field, Toolbar, LogoPill, EmptyState } from '../components/ui.jsx'
import Icon from '../components/Icon.jsx'
import { OIL_TYPES, PACK_SIZES, UNIT_TYPES } from '../data/seed.js'
import { inr, num, csvExport, uid } from '../utils/helpers.js'

export default function Products() {
  const { products, brands, brandMap, upsert, remove } = useData()
  const [q, setQ] = useState('')
  const [brand, setBrand] = useState('all')
  const [oil, setOil] = useState('all')
  const [edit, setEdit] = useState(null)

  const rows = useMemo(() => products.filter((p) => {
    if (brand !== 'all' && p.brandId !== brand) return false
    if (oil !== 'all' && p.oilType !== oil) return false
    if (q && !(`${p.name} ${p.sku}`.toLowerCase().includes(q.toLowerCase()))) return false
    return true
  }), [products, brand, oil, q])

  const blank = { id: uid('P'), brandId: brands[0]?.id, name: '', oilType: OIL_TYPES[0], pack: '1 L', unit: 'Bottle', sku: '', hsn: '1508', gst: 5, cost: 0, price: 0, mrp: 0, minStock: 0, stock: 0 }

  const save = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    upsert('products', {
      id: edit.id, brandId: f.get('brandId'), name: f.get('name'), oilType: f.get('oilType'),
      pack: f.get('pack'), unit: f.get('unit'), sku: f.get('sku'), hsn: f.get('hsn'),
      gst: +f.get('gst'), cost: +f.get('cost'), price: +f.get('price'), mrp: +f.get('mrp'),
      minStock: +f.get('minStock'), stock: +f.get('stock'),
    })
    setEdit(null)
  }

  return (
    <div className="page">
      <PageHeader title="Products" subtitle={`${products.length} oil SKUs across pack sizes and brands.`}>
        <button className="btn" onClick={() => csvExport('products.csv', rows.map((p) => ({ ...p, brand: brandMap[p.brandId]?.name })))}><Icon name="download" /> Export</button>
        <button className="btn btn-gold" onClick={() => setEdit(blank)}><Icon name="plus" /> Add Product</button>
      </PageHeader>

      <Toolbar search={q} onSearch={setQ} placeholder="Search name or SKU…">
        <select className="sel" value={brand} onChange={(e) => setBrand(e.target.value)}>
          <option value="all">All Brands</option>
          {brands.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
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
              <th>Product</th><th>Oil Type</th><th>SKU / HSN</th><th>Pack</th>
              <th className="num">Cost</th><th className="num">Price</th><th className="num">MRP</th>
              <th className="num">Stock</th><th>GST</th><th></th>
            </tr>
          </thead>
          <tbody>
            {rows.map((p) => {
              const low = p.stock <= p.minStock
              const b = brandMap[p.brandId]
              return (
                <tr key={p.id}>
                  <td>
                    <div className="with-logo">
                      <LogoPill name={b?.name || '?'} color={b?.color} />
                      <div>
                        <div className="cell-strong">{p.name}</div>
                        <div className="cell-sub">{b?.name} · {p.unit}</div>
                      </div>
                    </div>
                  </td>
                  <td className="muted">{p.oilType}</td>
                  <td><div className="cell-strong" style={{ fontSize: 12 }}>{p.sku}</div><div className="cell-sub">HSN {p.hsn}</div></td>
                  <td>{p.pack}</td>
                  <td className="num muted">{inr(p.cost)}</td>
                  <td className="num cell-strong">{inr(p.price)}</td>
                  <td className="num muted">{inr(p.mrp)}</td>
                  <td className="num">
                    <span style={{ fontWeight: 600, color: low ? 'var(--red)' : 'inherit' }}>{num(p.stock)}</span>
                    {low && <div><Badge tone="red" noDot>Low</Badge></div>}
                  </td>
                  <td><Badge tone="gray" noDot>{p.gst}%</Badge></td>
                  <td>
                    <div className="row-actions">
                      <button onClick={() => setEdit(p)}><Icon name="edit" size={15} /></button>
                      <button className="del" onClick={() => window.confirm('Delete product?') && remove('products', p.id)}><Icon name="trash" size={15} /></button>
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
        <Modal lg title={products.some((p) => p.id === edit.id) ? 'Edit Product' : 'Add Product'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="prodForm">Save Product</button></>}>
          <form id="prodForm" onSubmit={save} className="form-grid">
            <Field label="Product Name" full><input className="inp" name="name" defaultValue={edit.name} required /></Field>
            <Field label="Brand"><select className="sel" name="brandId" defaultValue={edit.brandId}>{brands.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}</select></Field>
            <Field label="Oil Type"><select className="sel" name="oilType" defaultValue={edit.oilType}>{OIL_TYPES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="Pack Size"><select className="sel" name="pack" defaultValue={edit.pack}>{PACK_SIZES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="Unit Type"><select className="sel" name="unit" defaultValue={edit.unit}>{UNIT_TYPES.map((o) => <option key={o}>{o}</option>)}</select></Field>
            <Field label="SKU Code"><input className="inp" name="sku" defaultValue={edit.sku} required /></Field>
            <Field label="HSN Code"><input className="inp" name="hsn" defaultValue={edit.hsn} /></Field>
            <Field label="GST %"><input className="inp" type="number" name="gst" defaultValue={edit.gst} /></Field>
            <Field label="Purchase / Cost Price"><input className="inp" type="number" name="cost" defaultValue={edit.cost} /></Field>
            <Field label="Selling Price"><input className="inp" type="number" name="price" defaultValue={edit.price} /></Field>
            <Field label="MRP"><input className="inp" type="number" name="mrp" defaultValue={edit.mrp} /></Field>
            <Field label="Opening Stock"><input className="inp" type="number" name="stock" defaultValue={edit.stock} /></Field>
            <Field label="Min Stock Level"><input className="inp" type="number" name="minStock" defaultValue={edit.minStock} /></Field>
          </form>
        </Modal>
      )}
    </div>
  )
}
