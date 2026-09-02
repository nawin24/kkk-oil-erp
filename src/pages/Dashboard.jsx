import { useMemo } from 'react'
import { useData } from '../context/DataContext.jsx'
import { useAuth } from '../context/AuthContext.jsx'
import { StatCard, Card, Badge, PageHeader } from '../components/ui.jsx'
import Icon from '../components/Icon.jsx'
import { SalesTrendChart, MonthlyBarChart, BrandPie, MiniDonut, PIE_COLORS } from '../components/Charts.jsx'
import { inr, inrShort, num, DISPATCH_COLORS } from '../utils/helpers.js'

const ACT_ICON = {
  sale: { name: 'sales', bg: 'var(--green-soft)', fg: '#137a4d' },
  prod: { name: 'production', bg: 'var(--blue-soft)', fg: 'var(--blue)' },
  purchase: { name: 'purchase', bg: 'var(--amber-soft)', fg: 'var(--amber)' },
  dispatch: { name: 'truck', bg: 'var(--purple-soft)', fg: 'var(--purple)' },
  payment: { name: 'rupee', bg: 'var(--gold-soft)', fg: 'var(--gold-deep)' },
}

export default function Dashboard() {
  const { metrics, salesTrend, monthlyTrend, brandMap, productMap, activity, sales } = useData()
  const { user } = useAuth()

  const brandPieData = useMemo(
    () => Object.entries(metrics.brandSales).map(([name, value]) => ({ name, value })).sort((a, b) => b.value - a.value),
    [metrics.brandSales]
  )
  const topProducts = useMemo(
    () => Object.entries(metrics.prodSales).map(([id, v]) => ({ p: productMap[id], v }))
      .filter((x) => x.p).sort((a, b) => b.v - a.v).slice(0, 5),
    [metrics.prodSales, productMap]
  )
  const dispatchDonut = useMemo(
    () => Object.entries(metrics.dispatchStatus).map(([name, value], i) => ({ name, value, color: PIE_COLORS[i % PIE_COLORS.length] })),
    [metrics.dispatchStatus]
  )

  const maxProd = Math.max(...topProducts.map((x) => x.v), 1)

  return (
    <div className="page">
      <PageHeader
        title={`Welcome back, ${user.name.split(' ')[0]} 👋`}
        subtitle="Here's what's happening across KKK Oil Factory today."
      >
        <Badge tone="green">Factory online</Badge>
      </PageHeader>

      {/* Primary KPIs */}
      <div className="stat-grid">
        <StatCard icon="rupee" tone="gold" label="Today's Sales" value={inr(metrics.todaySales)} delta="vs yesterday +12%" deltaDir="up" />
        <StatCard icon="sales" tone="green" label="This Month's Sales" value={inrShort(metrics.monthSales)} delta="On track to ₹12L" deltaDir="up" />
        <StatCard icon="box" tone="blue" label="Inventory Value" value={inrShort(metrics.inventoryValue)} delta={`Raw ${inrShort(metrics.rawValue)}`} deltaDir="flat" />
        <StatCard icon="reports" tone="teal" label="Est. Gross Profit" value={inrShort(metrics.totalProfit)} delta="margin ~17%" deltaDir="up" />
      </div>

      {/* Secondary KPIs */}
      <div className="stat-grid">
        <StatCard icon="alert" tone="red" label="Low Stock Alerts" value={`${metrics.lowStock.length + metrics.lowRaw.length} items`} delta="Needs attention" deltaDir="down" />
        <StatCard icon="production" tone="amber" label="Pending Production" value={`${metrics.pendingProduction.length} batches`} delta="2 planned · 1 running" deltaDir="flat" />
        <StatCard icon="truck" tone="purple" label="Pending Dispatch" value={`${metrics.pendingDispatch.length} orders`} delta="Ready to load" deltaDir="flat" />
        <StatCard icon="rupee" tone="amber" label="Purchase Due" value={inrShort(metrics.purchaseDue)} delta="to suppliers" deltaDir="flat" />
      </div>

      {/* Charts row 1 */}
      <div className="grid-2 mb-16">
        <Card title="Sales Trend" sub="Last 7 days" action={<Badge tone="gold" noDot>Weekly</Badge>}>
          <div style={{ padding: '14px 16px 8px' }}><SalesTrendChart data={salesTrend} /></div>
        </Card>
        <Card title="Brand-wise Sales" sub="Revenue share">
          <div style={{ padding: '14px 16px' }}>
            <BrandPie data={brandPieData} />
            <div className="legend">
              {brandPieData.map((b, i) => (
                <span key={b.name}><i style={{ background: PIE_COLORS[i % PIE_COLORS.length] }} />{b.name}</span>
              ))}
            </div>
          </div>
        </Card>
      </div>

      {/* Charts row 2 */}
      <div className="grid-2 mb-16">
        <Card title="Monthly Purchase vs Sales" sub="6-month comparison">
          <div style={{ padding: '14px 16px 8px' }}><MonthlyBarChart data={monthlyTrend} /></div>
        </Card>
        <Card title="Dispatch Status" sub="Open orders">
          <div style={{ padding: '14px 16px' }}>
            <MiniDonut data={dispatchDonut} />
            <div className="legend">
              {dispatchDonut.map((d) => (
                <span key={d.name}><i style={{ background: d.color }} />{d.name} ({d.value})</span>
              ))}
            </div>
          </div>
        </Card>
      </div>

      {/* Bottom row: top products, alerts, activity */}
      <div className="grid-3">
        <Card title="Top Products" sub="By revenue">
          <div className="card-pad" style={{ paddingTop: 6 }}>
            {topProducts.map(({ p, v }) => (
              <div key={p.id} style={{ marginBottom: 13 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 5 }}>
                  <span style={{ fontWeight: 600 }}>{p.name}</span>
                  <span className="muted">{inrShort(v)}</span>
                </div>
                <div className="bar"><span style={{ width: `${(v / maxProd) * 100}%` }} /></div>
              </div>
            ))}
          </div>
        </Card>

        <Card title="Stock & Payment Alerts" sub={`${metrics.lowStock.length + metrics.lowRaw.length} low-stock`}>
          <div className="card-pad" style={{ paddingTop: 6 }}>
            {metrics.lowStock.slice(0, 3).map((p) => (
              <div className="alert-row" key={p.id}>
                <div className="alert-ico" style={{ background: 'var(--red-soft)', color: 'var(--red)' }}><Icon name="alert" size={16} /></div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{p.name}</div>
                  <div className="tiny">Stock {num(p.stock)} / min {num(p.minStock)} {p.unit}s</div>
                </div>
                <Badge tone="red" noDot>Low</Badge>
              </div>
            ))}
            {metrics.lowRaw.slice(0, 2).map((r) => (
              <div className="alert-row" key={r.id}>
                <div className="alert-ico" style={{ background: 'var(--amber-soft)', color: 'var(--amber)' }}><Icon name="layers" size={16} /></div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{r.name}</div>
                  <div className="tiny">Raw {num(r.stock)} / min {num(r.minStock)} {r.unit}</div>
                </div>
                <Badge tone="amber" noDot>Reorder</Badge>
              </div>
            ))}
          </div>
        </Card>

        <Card title="Recent Activity" sub="Live feed">
          <div className="card-pad" style={{ paddingTop: 6 }}>
            {activity.map((a) => {
              const ic = ACT_ICON[a.icon] || ACT_ICON.sale
              return (
                <div className="feed-item" key={a.id}>
                  <div className="feed-dot" style={{ background: ic.bg, color: ic.fg }}><Icon name={ic.name} size={15} /></div>
                  <div>
                    <div className="ft" dangerouslySetInnerHTML={{ __html: a.text }} />
                    <div className="fm">{a.time}</div>
                  </div>
                </div>
              )
            })}
          </div>
        </Card>
      </div>
    </div>
  )
}
