import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { PageHeader, Badge, Toolbar, EmptyState } from '../components/ui'
import Icon from '../components/Icon'
import { inr, csvExport } from '../utils/helpers'

export default function PriceHistory() {
  const { priceHistory } = useData()
  const [q, setQ] = useState('')
  const [pricingTypeFilter, setPricingTypeFilter] = useState('all')

  const rows = useMemo(() => {
    return (priceHistory || []).filter((h: any) => {
      if (pricingTypeFilter !== 'all' && h.pricingType !== pricingTypeFilter) return false
      if (q && !(`${h.productName} ${h.productCode} ${h.modifiedBy}`.toLowerCase().includes(q.toLowerCase()))) return false
      return true
    })
  }, [priceHistory, q, pricingTypeFilter])

  return (
    <div className="page">
      <PageHeader
        title="Price History"
        subtitle="Complete audit trail of product price changes with effective dates, old & new rates, and user records."
      >
        <button
          className="btn"
          onClick={() =>
            csvExport(
              'price_history.csv',
              rows.map((r: any) => ({
                effectiveDate: r.effectiveDate,
                effectiveTime: r.effectiveTime,
                productCode: r.productCode,
                productName: r.productName,
                pricingType: r.pricingType,
                oldRate: r.oldRate,
                newRate: r.newRate,
                modifiedBy: r.modifiedBy,
              }))
            )
          }
        >
          <Icon name="download" /> Export History
        </button>
      </PageHeader>

      <Toolbar search={q} onSearch={setQ} placeholder="Search by product name, code, modified by…">
        <select className="sel" value={pricingTypeFilter} onChange={(e) => setPricingTypeFilter(e.target.value)}>
          <option value="all">All Pricing Types</option>
          <option value="AGENCY">Agency</option>
          <option value="WHOLESALE">Wholesale</option>
          <option value="RETAIL">Retail</option>
        </select>
        <div className="spacer" />
        <span className="tiny">{rows.length} record{rows.length === 1 ? '' : 's'}</span>
      </Toolbar>

      <div className="card table-wrap">
        <table className="tbl">
          <thead>
            <tr>
              <th>Effective Date &amp; Time</th>
              <th>Product Code</th>
              <th>Product Name</th>
              <th>Pricing Type</th>
              <th className="num">Old Rate</th>
              <th className="num">New Rate</th>
              <th className="num">Diff</th>
              <th>Modified By</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((h: any) => {
              const diff = h.newRate - h.oldRate
              return (
                <tr key={h.id}>
                  <td>
                    <div className="cell-strong">{h.effectiveDate}</div>
                    <div className="cell-sub">{h.effectiveTime || '12:00 PM'}</div>
                  </td>
                  <td className="cell-strong" style={{ color: 'var(--gold)', fontSize: 12 }}>{h.productCode}</td>
                  <td>{h.productName}</td>
                  <td>
                    <Badge tone={h.pricingType === 'AGENCY' ? 'amber' : h.pricingType === 'WHOLESALE' ? 'blue' : 'green'} noDot>
                      {h.pricingType}
                    </Badge>
                  </td>
                  <td className="num muted">{inr(h.oldRate)}</td>
                  <td className="num cell-strong">{inr(h.newRate)}</td>
                  <td className="num" style={{ color: diff >= 0 ? 'var(--green)' : 'var(--red)', fontWeight: 600 }}>
                    {diff >= 0 ? `+${inr(diff)}` : inr(diff)}
                  </td>
                  <td>
                    <div className="cell-strong" style={{ fontSize: 13 }}>{h.modifiedBy}</div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
        {!rows.length && <EmptyState icon="reports" text="No price history records found." />}
      </div>
    </div>
  )
}
