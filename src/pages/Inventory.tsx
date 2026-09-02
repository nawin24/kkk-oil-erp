import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Badge, Toolbar, StatCard, Card, EmptyState, Modal, Field } from '../components/ui'
import Icon from '../components/Icon'
import { StockBarChart } from '../components/Charts'
import { GODOWNS } from '../data/seed'
import { inr, inrShort, num, csvExport } from '../utils/helpers'

export default function Inventory() {
  const { products, rawMaterials, brandMap, metrics, upsert } = useData()
  const [tab, setTab] = useState('finished')
  const [q, setQ] = useState('')
  const [adjust, setAdjust] = useState(null)

  const finished = useMemo(() => products.filter((p) =>
    !q || p.name.toLowerCase().includes(q.toLowerCase())), [products, q])
  const raw = useMemo(() => rawMaterials.filter((r) =>
    !q || r.name.toLowerCase().includes(q.toLowerCase())), [rawMaterials, q])

  const chartData = [...products].sort((a, b) => b.stock - a.stock).slice(0, 8)
    .map((p) => ({ name: p.name.replace('KKK Gold ', '').slice(0, 16), stock: p.stock }))

  const saveAdjust = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    const delta = +f.get('qty')
    const op = f.get('op')
    if (adjust.type === 'finished') {
      const p = products.find((x) => x.id === adjust.id)
      upsert('products', { ...p, stock: Math.max(0, p.stock + (op === 'in' ? delta : -delta)) })
    } else {
      const r = rawMaterials.find((x) => x.id === adjust.id)
      upsert('rawMaterials', { ...r, stock: Math.max(0, r.stock + (op === 'in' ? delta : -delta)) })
    }
    setAdjust(null)
  }

  return (
    <div className="page">
      <PageHeader title="Inventory" subtitle="Finished goods, raw & packing materials — godown-wise stock tracking.">
        <button className="btn" onClick={() => csvExport(tab === 'finished' ? 'finished_stock.csv' : 'raw_stock.csv', tab === 'finished' ? finished : raw)}><Icon name="download" /> Stock Report</button>
      </PageHeader>

      <div className="stat-grid">
        <StatCard icon="box" tone="blue" label="Total Inventory Value" value={inrShort(metrics.inventoryValue)} delta="finished + raw" deltaDir="flat" />
        <StatCard icon="layers" tone="gold" label="Finished Goods" value={inrShort(metrics.finishedValue)} delta={`${products.length} SKUs`} deltaDir="flat" />
        <StatCard icon="factory" tone="teal" label="Raw & Packing" value={inrShort(metrics.rawValue)} delta={`${rawMaterials.length} items`} deltaDir="flat" />
        <StatCard icon="alert" tone="red" label="Low Stock" value={`${metrics.lowStock.length + metrics.lowRaw.length} items`} delta="reorder soon" deltaDir="down" />
      </div>

      <div className="grid-2 mb-16">
        <Card title="Stock by Product" sub="Top 8 by units">
          <div style={{ padding: '14px 12px' }}><StockBarChart data={chartData} /></div>
        </Card>
        <Card title="Godown Summary" sub="Stock split by location">
          <div className="card-pad">
            {GODOWNS.map((g) => {
              const items = rawMaterials.filter((r) => r.godown === g)
              const val = items.reduce((s, r) => s + r.stock * r.cost, 0)
              const pct = metrics.rawValue ? (val / metrics.rawValue) * 100 : 0
              return (
                <div key={g} style={{ marginBottom: 16 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 6 }}>
                    <span style={{ fontWeight: 600 }}><Icon name="inventory" size={14} style={{ verticalAlign: -2 }} /> {g}</span>
                    <span className="muted">{inrShort(val)} · {items.length} items</span>
                  </div>
                  <div className="bar"><span style={{ width: `${pct}%` }} /></div>
                </div>
              )
            })}
            <div className="kv" style={{ marginTop: 8 }}><span className="k">Finished goods (Main Godown)</span><span className="v">{inrShort(metrics.finishedValue)}</span></div>
          </div>
        </Card>
      </div>

      <div className="toolbar">
        <div className="pill-tabs">
          <button className={tab === 'finished' ? 'active' : ''} onClick={() => setTab('finished')}>Finished Goods</button>
          <button className={tab === 'raw' ? 'active' : ''} onClick={() => setTab('raw')}>Raw & Packing</button>
        </div>
        <div className="field-search" style={{ marginLeft: 'auto' }}>
          <Icon name="search" size={16} style={{ color: 'var(--text-3)' }} />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search item…" />
        </div>
      </div>

      <div className="card table-wrap">
        {tab === 'finished' ? (
          <table className="tbl">
            <thead><tr><th>Product</th><th>Brand</th><th className="num">Current Stock</th><th className="num">Min Level</th><th>Status</th><th className="num">Stock Value</th><th></th></tr></thead>
            <tbody>
              {finished.map((p) => {
                const low = p.stock <= p.minStock
                return (
                  <tr key={p.id}>
                    <td className="cell-strong">{p.name}</td>
                    <td className="muted">{brandMap[p.brandId]?.name}</td>
                    <td className="num cell-strong">{num(p.stock)} {p.unit}s</td>
                    <td className="num muted">{num(p.minStock)}</td>
                    <td>{low ? <Badge tone="red">Low Stock</Badge> : <Badge tone="green">In Stock</Badge>}</td>
                    <td className="num">{inr(p.stock * p.cost)}</td>
                    <td><div className="row-actions"><button onClick={() => setAdjust({ id: p.id, name: p.name, type: 'finished' })} title="Adjust stock"><Icon name="edit" size={15} /></button></div></td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        ) : (
          <table className="tbl">
            <thead><tr><th>Material</th><th>Godown</th><th className="num">Current</th><th className="num">Min Level</th><th>Status</th><th className="num">Value</th><th></th></tr></thead>
            <tbody>
              {raw.map((r) => {
                const low = r.stock <= r.minStock
                return (
                  <tr key={r.id}>
                    <td className="cell-strong">{r.name}</td>
                    <td className="muted">{r.godown}</td>
                    <td className="num cell-strong">{num(r.stock)} {r.unit}</td>
                    <td className="num muted">{num(r.minStock)}</td>
                    <td>{low ? <Badge tone="amber">Reorder</Badge> : <Badge tone="green">OK</Badge>}</td>
                    <td className="num">{inr(r.stock * r.cost)}</td>
                    <td><div className="row-actions"><button onClick={() => setAdjust({ id: r.id, name: r.name, type: 'raw' })} title="Adjust stock"><Icon name="edit" size={15} /></button></div></td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
        {((tab === 'finished' && !finished.length) || (tab === 'raw' && !raw.length)) && <EmptyState text="No items found" />}
      </div>

      {adjust && (
        <Modal title={`Stock Adjustment · ${adjust.name}`} onClose={() => setAdjust(null)}
          footer={<><button className="btn" onClick={() => setAdjust(null)}>Cancel</button><button className="btn btn-primary" form="adjForm">Apply</button></>}>
          <form id="adjForm" onSubmit={saveAdjust} className="form-grid">
            <Field label="Movement Type"><select className="sel" name="op" defaultValue="in"><option value="in">Stock Inward (+)</option><option value="out">Stock Outward (−)</option></select></Field>
            <Field label="Quantity"><input className="inp" type="number" name="qty" defaultValue={0} autoFocus /></Field>
            <Field label="Reason / Note" full><input className="inp" name="note" placeholder="e.g. production output, damage, transfer" /></Field>
          </form>
        </Modal>
      )}
    </div>
  )
}
