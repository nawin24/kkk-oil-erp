import { useState, useMemo } from 'react'
import { useData } from '../context/DataContext'
import { useAuth } from '../context/AuthContext'
import { PageHeader, Card, Badge } from '../components/ui'
import Icon from '../components/Icon'
import { BrandPie, MonthlyBarChart, PIE_COLORS } from '../components/Charts'
import { inr, num, csvExport, orderTotals, orderProfit } from '../utils/helpers'

export default function Reports() {
  const { sales, customers, suppliers, products, production, brandMap, productMap, customerMap, metrics, monthlyTrend } = useData()
  const { isSuperAdmin } = useAuth()
  const [active, setActive] = useState('sales')

  const REPORTS = useMemo(() => {
    return [
      { key: 'sales',      label: 'Sales Report',          icon: 'sales',     desc: 'Order-wise revenue & output tax' },
      { key: 'brand',      label: 'Brand-wise Sales',      icon: 'brands',    desc: 'Revenue share by brand' },
      { key: 'product',    label: 'Product-wise Sales',    icon: 'products',  desc: 'Top selling SKUs' },
      { key: 'customer',   label: 'Customer Dues',         icon: 'customers', desc: 'Dealer dues & credit outstanding' },
      { key: 'supplier',   label: 'Supplier Payable',      icon: 'suppliers', desc: 'Payable to vendors' },
      { key: 'stock',      label: 'Stock Report',          icon: 'inventory', desc: 'Current & low stock' },
      { key: 'production', label: 'Production Report',      icon: 'production',desc: 'Batch output & yield' },
      { key: 'gst',        label: 'Tax Report',            icon: 'doc',       desc: 'Output tax breakdown' },
    ]
  }, [])

  const brandPie = useMemo(() => Object.entries(metrics.brandSales).map(([name, value]) => ({ name, value: value as number })).sort((a, b) => b.value - a.value), [metrics.brandSales])

  // Filter sales data: GST sales only vs Non-GST sales only
  const gstSalesOnly = useMemo(() => (sales || []).filter((s: any) => s.billingType !== 'NON_GST'), [sales])
  const nonGstSalesOnly = useMemo(() => (sales || []).filter((s: any) => s.billingType === 'NON_GST'), [sales])

  const data = useMemo(() => {
    switch (active) {
      case 'sales':
        return {
          cols: ['Voucher No', 'Customer', 'Date', 'Pricing', 'Total', 'GST', 'Status'],
          rows: gstSalesOnly.map((s: any) => {
            const grand = s.grandTotal || orderTotals(s.items, productMap).total
            const gstAmt = s.gstTotal || orderTotals(s.items, productMap).tax
            return [s.voucherNo || s.id, customerMap[s.customerId]?.name || s.address || 'Walk-in', s.date, s.pricingType || 'RETAIL', inr(grand), inr(gstAmt), s.payStatus]
          }),
        }
      case 'nongst':
        return {
          cols: ['Voucher No', 'Customer', 'Date', 'Pricing', 'Total', 'GST', 'Status'],
          rows: nonGstSalesOnly.map((s: any) => {
            const grand = s.grandTotal || orderTotals(s.items, productMap).total
            return [s.voucherNo || s.id, customerMap[s.customerId]?.name || s.address || 'Walk-in', s.date, s.pricingType || 'RETAIL', inr(grand), '₹0 (Non-GST)', s.payStatus]
          }),
        }
      case 'brand':
        return { cols: ['Brand', 'Revenue', 'Share'], rows: brandPie.map((b) => [b.name, inr(b.value), `${Math.round(b.value / (metrics.totalRevenue || 1) * 100)}%`]) }
      case 'product': {
        const list = Object.entries(metrics.prodSales).map(([id, v]) => ({ p: productMap[id], v: v as number })).filter((x) => x.p).sort((a, b) => b.v - a.v)
        return { cols: ['Product', 'Brand', 'Revenue'], rows: list.map((x) => [x.p.name, brandMap[x.p.brandId]?.name, inr(x.v)]) }
      }
      case 'customer':
        return { cols: ['Customer', 'Type', 'Credit Limit', 'Outstanding'], rows: customers.map((c: any) => [c.name, c.type, inr(c.creditLimit), inr(c.outstanding)]) }
      case 'supplier':
        return { cols: ['Supplier', 'Material', 'Rating', 'Due'], rows: suppliers.map((s: any) => [s.name, s.material, `${s.rating}/5`, inr(s.due)]) }
      case 'stock':
        return { cols: ['Product', 'Brand', 'Stock', 'Min', 'Status'], rows: products.map((p: any) => [p.name, brandMap[p.brandId]?.name, num(p.stock), num(p.minStock), p.stock <= p.minStock ? 'LOW' : 'OK']) }
      case 'production':
        return { cols: ['Batch', 'Product', 'Planned', 'Output', 'Status'], rows: production.map((b: any) => [b.id, productMap[b.productId]?.name, num(b.plannedQty), num(b.outputQty), b.status]) }
      case 'gst':
        return {
          cols: ['Invoice', 'Customer', 'Taxable', 'GST Tax', 'Grand Total'],
          rows: gstSalesOnly.map((s: any) => {
            const sub = s.subtotal || orderTotals(s.items, productMap).sub
            const gstAmt = s.gstTotal || orderTotals(s.items, productMap).tax
            const grand = s.grandTotal || orderTotals(s.items, productMap).total
            return [s.voucherNo || s.id, customerMap[s.customerId]?.name || 'Walk-in', inr(sub), inr(gstAmt), inr(grand)]
          }),
        }
      default: return { cols: [], rows: [] }
    }
  }, [active, gstSalesOnly, nonGstSalesOnly, customers, suppliers, products, production, productMap, customerMap, brandMap, brandPie, metrics])

  const exportCurrent = () => {
    const rows = data.rows.map((r) => Object.fromEntries(r.map((cell, i) => [data.cols[i], cell])))
    csvExport(`${active}_report.csv`, rows)
  }

  return (
    <div className="page">
      <PageHeader title="Reports & Analytics" subtitle="Comprehensive financial, tax, sales, and inventory analytics.">
        <button className="btn btn-gold" onClick={exportCurrent}><Icon name="download" /> Export Report (CSV)</button>
      </PageHeader>

      <div className="grid-12 mb-16">
        {REPORTS.map((r) => (
          <button key={r.key} onClick={() => setActive(r.key)}
            className="card" style={{ gridColumn: 'span 3', padding: 14, textAlign: 'left', cursor: 'pointer', borderColor: active === r.key ? 'var(--gold)' : 'var(--border)', boxShadow: active === r.key ? '0 0 0 3px rgba(227,169,46,.15)' : 'var(--shadow-sm)' }}>
            <div className="ico" style={{ width: 34, height: 34, borderRadius: 9, background: 'var(--gold-soft)', color: 'var(--gold-deep)', display: 'grid', placeItems: 'center', marginBottom: 9 }}><Icon name={r.icon} size={17} /></div>
            <div style={{ fontWeight: 700, fontSize: 13.5 }}>{r.label}</div>
            <div className="tiny" style={{ marginTop: 2 }}>{r.desc}</div>
          </button>
        ))}
      </div>

      {(active === 'sales' || active === 'brand') && (
        <div className="grid-2 mb-16">
          <Card title="Monthly Purchase vs Sales" sub="6 months"><div style={{ padding: '14px 16px 8px' }}><MonthlyBarChart data={monthlyTrend} /></div></Card>
          <Card title="Brand Revenue Share">
            <div style={{ padding: '14px 16px' }}>
              <BrandPie data={brandPie} />
              <div className="legend">{brandPie.map((b, i) => <span key={b.name}><i style={{ background: PIE_COLORS[i % PIE_COLORS.length] }} />{b.name}</span>)}</div>
            </div>
          </Card>
        </div>
      )}

      <Card title={REPORTS.find((r) => r.key === active)?.label} sub={`${data.rows.length} rows`}>
        <div className="table-wrap">
          <table className="tbl">
            <thead><tr>{data.cols.map((c, i) => <th key={c} className={i > 1 ? 'num' : ''}>{c}</th>)}</tr></thead>
            <tbody>
              {data.rows.map((r, ri) => (
                <tr key={ri}>{r.map((cell, ci) => (
                  <td key={ci} className={ci > 1 ? 'num' : ''}>
                    {cell === 'LOW' ? <Badge tone="red" noDot>LOW</Badge> : cell === 'OK' ? <Badge tone="green" noDot>OK</Badge> : ci === 0 ? <span className="cell-strong">{cell}</span> : cell}
                  </td>
                ))}</tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  )
}

