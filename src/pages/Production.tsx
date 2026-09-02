import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Badge, StatCard, Card, Modal, Field, EmptyState } from '../components/ui'
import Icon from '../components/Icon'
import { ProductionLineChart } from '../components/Charts'
import { inr, inrShort, fmtDate, num, csvExport, uid, todayISO, PROD_COLORS } from '../utils/helpers'

const FLOW = ['Raw Material', 'Processing', 'Filtering', 'Packing', 'Labelling', 'Finished Goods']

export default function Production() {
  const { production, products, productMap, upsert, remove } = useData()
  const [edit, setEdit] = useState(null)

  const rows = production.map((b) => {
    const p = productMap[b.productId]
    const totalCost = b.rawCost + b.packCost + b.labourCost
    const costPerUnit = b.outputQty ? totalCost / b.outputQty : 0
    const yieldPct = b.plannedQty ? Math.round((b.outputQty / b.plannedQty) * 100) : 0
    return { ...b, product: p, totalCost, costPerUnit, yieldPct }
  })

  const completed = rows.filter((b) => b.status === 'Completed')
  const totalOutput = completed.reduce((s, b) => s + b.outputQty, 0)
  const totalCost = completed.reduce((s, b) => s + b.totalCost, 0)
  const totalWastage = completed.reduce((s, b) => s + b.wastage, 0)

  const chartData = completed.map((b) => ({ label: b.id.replace('BATCH-', '#'), output: b.outputQty, wastage: b.wastage }))

  const blank = { id: uid('BATCH'), productId: products[0]?.id, plannedQty: 0, outputQty: 0, wastage: 0, status: 'Planned', startDate: todayISO(), mfgDate: '', expDate: '', rawCost: 0, packCost: 0, labourCost: 0 }

  const save = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    const status = f.get('status')
    const record = {
      id: edit.id, productId: f.get('productId'),
      plannedQty: +f.get('plannedQty'), outputQty: +f.get('outputQty'), wastage: +f.get('wastage'),
      status, startDate: f.get('startDate'), mfgDate: f.get('mfgDate'), expDate: f.get('expDate'),
      rawCost: +f.get('rawCost'), packCost: +f.get('packCost'), labourCost: +f.get('labourCost'),
    }
    upsert('production', record)
    // Business logic: completing a batch increases finished goods stock
    const wasCompleted = production.find((b) => b.id === edit.id)?.status === 'Completed'
    if (status === 'Completed' && !wasCompleted && record.outputQty > 0) {
      const p = products.find((x) => x.id === record.productId)
      if (p) upsert('products', { ...p, stock: p.stock + record.outputQty })
    }
    setEdit(null)
  }

  return (
    <div className="page">
      <PageHeader title="Production" subtitle="Batch planning, raw consumption, yield & cost — seed to finished goods.">
        <button className="btn" onClick={() => csvExport('production.csv', rows.map(({ product, ...r }) => ({ ...r, product: product?.name })))}><Icon name="download" /> Batch Report</button>
        <button className="btn btn-gold" onClick={() => setEdit(blank)}><Icon name="plus" /> New Batch</button>
      </PageHeader>

      <div className="stat-grid">
        <StatCard icon="production" tone="blue" label="Completed Output" value={`${num(totalOutput)} units`} delta={`${completed.length} batches`} deltaDir="up" />
        <StatCard icon="rupee" tone="gold" label="Production Cost" value={inrShort(totalCost)} delta="raw + pack + labour" deltaDir="flat" />
        <StatCard icon="alert" tone="red" label="Total Wastage" value={`${totalWastage} units`} delta="across batches" deltaDir="down" />
        <StatCard icon="clock" tone="amber" label="In Pipeline" value={`${rows.filter((b) => b.status !== 'Completed').length} batches`} delta="planned / running" deltaDir="flat" />
      </div>

      {/* Workflow strip */}
      <Card title="Production Workflow" sub="Standard process line">
        <div className="card-pad" style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          {FLOW.map((step, i) => (
            <div key={step} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--surface-2)', border: '1px solid var(--border)', padding: '8px 13px', borderRadius: 10 }}>
                <span style={{ width: 22, height: 22, borderRadius: '50%', background: 'var(--forest)', color: '#fff', display: 'grid', placeItems: 'center', fontSize: 11, fontWeight: 700 }}>{i + 1}</span>
                <span style={{ fontSize: 12.5, fontWeight: 600 }}>{step}</span>
              </div>
              {i < FLOW.length - 1 && <Icon name="arrowUp" size={14} style={{ transform: 'rotate(90deg)', color: 'var(--text-3)' }} />}
            </div>
          ))}
        </div>
      </Card>

      <div className="grid-2" style={{ margin: '16px 0' }}>
        <Card title="Output vs Wastage" sub="Completed batches">
          <div style={{ padding: '14px 12px' }}>{chartData.length ? <ProductionLineChart data={chartData} /> : <EmptyState text="No completed batches yet" />}</div>
        </Card>
        <Card title="Yield Performance" sub="Output ÷ planned">
          <div className="card-pad">
            {completed.map((b) => (
              <div key={b.id} style={{ marginBottom: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 5 }}>
                  <span style={{ fontWeight: 600 }}>{b.id} · {b.product?.oilType}</span>
                  <span className="muted">{b.yieldPct}% yield</span>
                </div>
                <div className="bar"><span style={{ width: `${b.yieldPct}%`, background: b.yieldPct >= 90 ? 'linear-gradient(90deg,#1f8a5b,#137a4d)' : undefined }} /></div>
              </div>
            ))}
          </div>
        </Card>
      </div>

      <div className="card table-wrap">
        <table className="tbl">
          <thead><tr>
            <th>Batch No</th><th>Product</th><th>Status</th><th className="num">Planned</th><th className="num">Output</th>
            <th className="num">Yield</th><th>Mfg / Exp</th><th className="num">Cost</th><th className="num">₹/Unit</th><th></th>
          </tr></thead>
          <tbody>
            {rows.map((b) => (
              <tr key={b.id}>
                <td className="cell-strong">{b.id}</td>
                <td>{b.product?.name}</td>
                <td><Badge tone={PROD_COLORS[b.status]} noDot>{b.status}</Badge></td>
                <td className="num">{num(b.plannedQty)}</td>
                <td className="num cell-strong">{num(b.outputQty)}</td>
                <td className="num">{b.yieldPct ? `${b.yieldPct}%` : '—'}</td>
                <td className="muted" style={{ fontSize: 12 }}>{b.mfgDate ? `${fmtDate(b.mfgDate)} → ${fmtDate(b.expDate)}` : '—'}</td>
                <td className="num">{b.totalCost ? inr(b.totalCost) : '—'}</td>
                <td className="num muted">{b.costPerUnit ? inr(b.costPerUnit) : '—'}</td>
                <td><div className="row-actions">
                  <button onClick={() => setEdit(b)}><Icon name="edit" size={15} /></button>
                  <button className="del" onClick={() => window.confirm('Delete batch?') && remove('production', b.id)}><Icon name="trash" size={15} /></button>
                </div></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {edit && (
        <Modal lg title={production.some((b) => b.id === edit.id) ? 'Edit Batch' : 'New Production Batch'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="batchForm">Save Batch</button></>}>
          <form id="batchForm" onSubmit={save} className="form-grid">
            <Field label="Batch Number"><input className="inp" name="batchNo" defaultValue={edit.id} disabled /></Field>
            <Field label="Product"><select className="sel" name="productId" defaultValue={edit.productId}>{products.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}</select></Field>
            <Field label="Planned Qty"><input className="inp" type="number" name="plannedQty" defaultValue={edit.plannedQty} /></Field>
            <Field label="Output Qty"><input className="inp" type="number" name="outputQty" defaultValue={edit.outputQty} /></Field>
            <Field label="Wastage (units)"><input className="inp" type="number" name="wastage" defaultValue={edit.wastage} /></Field>
            <Field label="Status"><select className="sel" name="status" defaultValue={edit.status}><option>Planned</option><option>In Progress</option><option>Completed</option></select></Field>
            <Field label="Start Date"><input className="inp" type="date" name="startDate" defaultValue={edit.startDate} /></Field>
            <Field label="Mfg Date"><input className="inp" type="date" name="mfgDate" defaultValue={edit.mfgDate} /></Field>
            <Field label="Expiry Date"><input className="inp" type="date" name="expDate" defaultValue={edit.expDate} /></Field>
            <Field label="Raw Material Cost"><input className="inp" type="number" name="rawCost" defaultValue={edit.rawCost} /></Field>
            <Field label="Packing Cost"><input className="inp" type="number" name="packCost" defaultValue={edit.packCost} /></Field>
            <Field label="Labour Cost"><input className="inp" type="number" name="labourCost" defaultValue={edit.labourCost} /></Field>
            <div className="form-row full"><div className="tiny" style={{ background: 'var(--green-soft)', color: '#137a4d', padding: '8px 12px', borderRadius: 8 }}><Icon name="check" size={13} style={{ verticalAlign: -2 }} /> Marking a batch <b>Completed</b> automatically adds the output to finished goods stock.</div></div>
          </form>
        </Modal>
      )}
    </div>
  )
}
