import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext.jsx'
import { PageHeader, Badge, Modal, Field, StatCard, Card, EmptyState } from '../components/ui.jsx'
import Icon from '../components/Icon.jsx'
import { inr, inrShort, num, csvExport, orderTotals, DISPATCH_COLORS } from '../utils/helpers.js'

const STAGES = ['Order Received', 'Packing Pending', 'Ready for Dispatch', 'Loaded', 'In Transit', 'Delivered', 'Returned']

export default function Logistics() {
  const { dispatches, sales, customerMap, productMap, upsert, remove } = useData()
  const [edit, setEdit] = useState(null)

  const rows = useMemo(() => dispatches.map((d) => {
    const so = sales.find((s) => s.id === d.soId)
    const cust = so ? customerMap[so.customerId] : null
    const total = so ? orderTotals(so.items, productMap).total : 0
    return { ...d, so, cust, total }
  }), [dispatches, sales, customerMap, productMap])

  const transportCost = dispatches.reduce((s, d) => s + d.transport, 0)
  const delivered = dispatches.filter((d) => d.status === 'Delivered').length
  const inTransit = dispatches.filter((d) => d.status === 'In Transit').length

  // pipeline counts from sales orders
  const pipeline = STAGES.map((st) => ({ st, count: sales.filter((s) => s.dispatch === st).length }))

  const save = (e) => {
    e.preventDefault()
    const f = new FormData(e.target)
    const status = f.get('status')
    upsert('dispatches', {
      id: edit.id, soId: f.get('soId'), vehicle: f.get('vehicle'), driver: f.get('driver'),
      route: f.get('route'), status, transport: +f.get('transport'), pod: f.get('pod') === 'on',
    })
    // keep linked sales order dispatch status in sync
    const so = sales.find((s) => s.id === f.get('soId'))
    if (so && so.dispatch !== status) upsert('sales', { ...so, dispatch: status })
    setEdit(null)
  }

  const blank = { id: `DSP-${9000 + dispatches.length + 1}`, soId: sales[0]?.id, vehicle: '', driver: '', route: '', status: 'Ready for Dispatch', transport: 0, pod: false }

  return (
    <div className="page">
      <PageHeader title="Logistics & Dispatch" subtitle="Vehicle assignment, route, delivery status and proof of delivery.">
        <button className="btn" onClick={() => csvExport('dispatches.csv', rows.map(({ so, cust, ...r }) => ({ ...r, customer: cust?.name })))}><Icon name="download" /> Logistics Report</button>
        <button className="btn btn-gold" onClick={() => setEdit(blank)}><Icon name="plus" /> New Dispatch</button>
      </PageHeader>

      <div className="stat-grid">
        <StatCard icon="truck" tone="purple" label="Active Dispatches" value={`${dispatches.length}`} delta={`${inTransit} in transit`} deltaDir="flat" />
        <StatCard icon="check" tone="green" label="Delivered" value={`${delivered} trips`} delta="POD collected" deltaDir="up" />
        <StatCard icon="rupee" tone="gold" label="Transport Cost" value={inrShort(transportCost)} delta="period total" deltaDir="flat" />
        <StatCard icon="alert" tone="red" label="Returns" value={`${sales.filter((s) => s.dispatch === 'Returned').length}`} delta="goods returned" deltaDir="down" />
      </div>

      <Card title="Dispatch Pipeline" sub="Orders by stage">
        <div className="card-pad" style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          {pipeline.map((p) => (
            <div key={p.st} style={{ flex: '1 1 120px', minWidth: 120, border: '1px solid var(--border)', borderRadius: 12, padding: '12px 14px', background: 'var(--surface-2)' }}>
              <div style={{ fontSize: 22, fontWeight: 800 }}>{p.count}</div>
              <Badge tone={DISPATCH_COLORS[p.st]} noDot>{p.st}</Badge>
            </div>
          ))}
        </div>
      </Card>

      <div className="card table-wrap" style={{ marginTop: 16 }}>
        <table className="tbl">
          <thead><tr>
            <th>Dispatch No</th><th>Order / Customer</th><th>Vehicle</th><th>Driver</th><th>Route</th>
            <th className="num">Invoice Value</th><th className="num">Transport</th><th>Status</th><th>POD</th><th></th>
          </tr></thead>
          <tbody>
            {rows.map((d) => (
              <tr key={d.id}>
                <td className="cell-strong">{d.id}</td>
                <td><div className="cell-strong">{d.soId}</div><div className="cell-sub">{d.cust?.name}</div></td>
                <td className="muted">{d.vehicle}</td>
                <td>{d.driver}</td>
                <td className="muted">{d.route}</td>
                <td className="num">{inr(d.total)}</td>
                <td className="num muted">{inr(d.transport)}</td>
                <td><Badge tone={DISPATCH_COLORS[d.status]} noDot>{d.status}</Badge></td>
                <td>{d.pod ? <Badge tone="green">Yes</Badge> : <Badge tone="gray">No</Badge>}</td>
                <td><div className="row-actions">
                  <button onClick={() => setEdit(d)}><Icon name="edit" size={15} /></button>
                  <button className="del" onClick={() => window.confirm('Delete dispatch?') && remove('dispatches', d.id)}><Icon name="trash" size={15} /></button>
                </div></td>
              </tr>
            ))}
          </tbody>
        </table>
        {!rows.length && <EmptyState icon="truck" text="No dispatches" />}
      </div>

      {edit && (
        <Modal title={dispatches.some((d) => d.id === edit.id) ? 'Update Dispatch' : 'New Dispatch'} onClose={() => setEdit(null)}
          footer={<><button className="btn" onClick={() => setEdit(null)}>Cancel</button><button className="btn btn-primary" form="dspForm">Save Dispatch</button></>}>
          <form id="dspForm" onSubmit={save} className="form-grid">
            <Field label="Linked Sales Order" full><select className="sel" name="soId" defaultValue={edit.soId}>{sales.map((s) => <option key={s.id} value={s.id}>{s.id} · {customerMap[s.customerId]?.name}</option>)}</select></Field>
            <Field label="Vehicle No"><input className="inp" name="vehicle" defaultValue={edit.vehicle} placeholder="TN-29-AB-1234" /></Field>
            <Field label="Driver"><input className="inp" name="driver" defaultValue={edit.driver} /></Field>
            <Field label="Route"><input className="inp" name="route" defaultValue={edit.route} /></Field>
            <Field label="Transport Cost"><input className="inp" type="number" name="transport" defaultValue={edit.transport} /></Field>
            <Field label="Dispatch Status"><select className="sel" name="status" defaultValue={edit.status}>{STAGES.map((s) => <option key={s}>{s}</option>)}</select></Field>
            <Field label="Proof of Delivery"><label style={{ display: 'flex', gap: 8, alignItems: 'center', fontWeight: 500, fontSize: 13 }}><input type="checkbox" name="pod" defaultChecked={edit.pod} /> POD received</label></Field>
            <div className="form-row full"><div className="tiny" style={{ background: 'var(--blue-soft)', color: 'var(--blue)', padding: '8px 12px', borderRadius: 8 }}><Icon name="truck" size={13} style={{ verticalAlign: -2 }} /> Updating status here also updates the linked sales order and reduces stock when loaded.</div></div>
          </form>
        </Modal>
      )}
    </div>
  )
}
