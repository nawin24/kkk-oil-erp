import { useState } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Card, Badge, Modal, Field, LogoPill } from '../components/ui'
import Icon from '../components/Icon'
import { inrShort, csvExport, uid } from '../utils/helpers'

export default function Brands() {
  const { brands, products, sales, productMap, brandMap, upsert, remove } = useData()
  const [edit, setEdit] = useState(null)

  // brand-wise sales + stock
  const stats = brands.map((b) => {
    const prods = products.filter((p) => p.brandId === b.id)
    const stock = prods.reduce((s, p) => s + p.stock, 0)
    let revenue = 0
    sales.forEach((so) => so.items.forEach((it) => {
      const p = productMap[it.productId]
      if (p && p.brandId === b.id) revenue += it.qty * it.rate
    }))
    return { ...b, products: prods.length, stock, revenue }
  })

  const blank = { id: uid('B'), name: '', type: 'Third-party Brand', color: '#2563eb', contact: '', phone: '', gstin: '' }

  const save = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    upsert('brands', {
      id: edit.id,
      name: f.get('name'), type: f.get('type'), color: f.get('color'),
      contact: f.get('contact'), phone: f.get('phone'), gstin: f.get('gstin'),
    })
    setEdit(null)
  }

  return (
    <div className="page">
      <PageHeader title="Brands" subtitle="KKK's own brand plus the third-party oil brands you handle.">
        <button className="btn" onClick={() => csvExport('brands.csv', stats.map(({ color, ...r }) => r))}><Icon name="download" /> Export</button>
        <button className="btn btn-gold" onClick={() => setEdit(blank)}><Icon name="plus" /> Add Brand</button>
      </PageHeader>

      <div className="grid-12">
        {stats.map((b) => (
          <div className="card" key={b.id} style={{ gridColumn: 'span 4', padding: 18 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <div className="with-logo">
                <LogoPill name={b.name} color={b.color} />
                <div>
                  <div style={{ fontWeight: 700, fontSize: 14.5 }}>{b.name}</div>
                  <Badge tone={b.type === 'Own Brand' ? 'gold' : 'gray'} noDot>{b.type}</Badge>
                </div>
              </div>
              <div className="row-actions">
                <button onClick={() => setEdit(b)}><Icon name="edit" size={15} /></button>
                <button className="del" onClick={() => window.confirm(`Delete ${b.name}?`) && remove('brands', b.id)}><Icon name="trash" size={15} /></button>
              </div>
            </div>
            <div className="kv"><span className="k">Products</span><span className="v">{b.products}</span></div>
            <div className="kv"><span className="k">Total Stock</span><span className="v">{b.stock.toLocaleString('en-IN')} units</span></div>
            <div className="kv"><span className="k">Sales (period)</span><span className="v">{inrShort(b.revenue)}</span></div>
            <div className="kv"><span className="k">GSTIN</span><span className="v" style={{ fontSize: 12 }}>{b.gstin || '—'}</span></div>
            <div className="tiny" style={{ marginTop: 10 }}><Icon name="suppliers" size={13} style={{ verticalAlign: -2 }} /> {b.contact} · {b.phone}</div>
          </div>
        ))}
      </div>

      {edit && (
        <Modal title={brandMap[edit.id] ? 'Edit Brand' : 'Add Brand'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="brandForm">Save Brand</button></>}>
          <form id="brandForm" onSubmit={save} className="form-grid">
            <Field label="Brand Name" full><input className="inp" name="name" defaultValue={edit.name} required /></Field>
            <Field label="Brand Type"><select className="sel" name="type" defaultValue={edit.type}><option>Own Brand</option><option>Third-party Brand</option></select></Field>
            <Field label="Brand Color"><input className="inp" type="color" name="color" defaultValue={edit.color} style={{ height: 38, padding: 4 }} /></Field>
            <Field label="Contact"><input className="inp" name="contact" defaultValue={edit.contact} /></Field>
            <Field label="Phone"><input className="inp" name="phone" defaultValue={edit.phone} /></Field>
            <Field label="GSTIN" full><input className="inp" name="gstin" defaultValue={edit.gstin} placeholder="33XXXXX0000X1Z5" /></Field>
          </form>
        </Modal>
      )}
    </div>
  )
}
