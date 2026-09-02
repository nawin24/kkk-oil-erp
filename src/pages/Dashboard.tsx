import { useMemo } from 'react'
import { useData } from '../context/DataContext'
import { useAuth } from '../context/AuthContext'
import { StatCard, Card, Badge, PageHeader } from '../components/ui'
import Icon from '../components/Icon'
import { SalesTrendChart, MonthlyBarChart, BrandPie, MiniDonut, PIE_COLORS } from '../components/Charts'
import { inr, inrShort, num, DISPATCH_COLORS } from '../utils/helpers'

const ACT_ICON = {
  sale: { name: 'sales', bg: 'var(--green-soft)', fg: '#137a4d' },
  prod: { name: 'production', bg: 'var(--blue-soft)', fg: 'var(--blue)' },
  purchase: { name: 'purchase', bg: 'var(--amber-soft)', fg: 'var(--amber)' },
  dispatch: { name: 'truck', bg: 'var(--purple-soft)', fg: 'var(--purple)' },
  payment: { name: 'rupee', bg: 'var(--gold-soft)', fg: 'var(--gold-deep)' },
}

export default function Dashboard() {
  const { metrics, salesTrend, monthlyTrend, brandMap, productMap, customerMap, activity, sales, products } = useData()
  const { user, isSuperAdmin, isManager, isCashier, isNonGstSession } = useAuth()

  const brandPieData = useMemo(
    () => Object.entries(metrics.brandSales).map(([name, value]) => ({ name, value: value as number })).sort((a, b) => b.value - a.value),
    [metrics.brandSales]
  )
  const topProducts = useMemo(
    () => Object.entries(metrics.prodSales).map(([id, v]) => ({ p: productMap[id], v: v as number }))
      .filter((x) => x.p).sort((a, b) => b.v - a.v).slice(0, 5),
    [metrics.prodSales, productMap]
  )
  const dispatchDonut = useMemo(
    () => Object.entries(metrics.dispatchStatus).map(([name, value], i) => ({ name, value: value as number, color: PIE_COLORS[i % PIE_COLORS.length] })),
    [metrics.dispatchStatus]
  )

  const maxProd = Math.max(...topProducts.map((x) => x.v), 1)

  // Manager-specific Cashier Activity Breakdown
  const cashierStats = useMemo(() => {
    const map: Record<string, { name: string; count: number; total: number; cash: number; credit: number }> = {}
    ;(sales || []).forEach((s: any) => {
      const sp = s.salesperson || s.userName || 'Default Cashier'
      if (!map[sp]) map[sp] = { name: sp, count: 0, total: 0, cash: 0, credit: 0 }
      const amt = s.grandTotal || s.total || 0
      map[sp].count += 1
      map[sp].total += amt
      if (s.payMode === 'Credit' || s.payStatus === 'Pending') {
        map[sp].credit += amt
      } else {
        map[sp].cash += amt
      }
    })
    return Object.values(map)
  }, [sales])

  return (
    <div className="page">
      <PageHeader
        title={`Welcome back, ${user?.name ? user.name.split(' ')[0] : 'Admin'} 👋`}
        subtitle={isNonGstSession ? "Non-GST Executive Control & Billing Analytics" : isSuperAdmin ? "Super Admin Executive Control & Billing Analytics" : isManager ? "Manager Overview & Cashier Sales Performance Center" : "Here's what's happening across KKK Oil Factory today."}
      >
        <Badge tone={isNonGstSession ? "purple" : isSuperAdmin ? "gold" : "green"}>{user?.roleLabel || 'Factory'} Mode</Badge>
      </PageHeader>

      {/* SUPER ADMIN EXECUTIVE SECTION */}
      {isSuperAdmin && (
        <div style={{ marginBottom: 20 }}>
          {/* Super Admin KPI Cards: Monthly Bills Count & Total Amount Sold */}
          <div className="stat-grid" style={{ marginBottom: 16 }}>
            <StatCard icon="billing" tone="gold" label="No. of Bills (This Month)" value={`${metrics.monthBillsCount || 0} Bills`} delta={`${metrics.todayBillsCount || 0} generated today`} deltaDir="up" />
            <StatCard icon="rupee" tone="green" label="Amount Sold (This Month)" value={inr(metrics.monthSalesTotal || metrics.monthSales)} delta="Total revenue as of now" deltaDir="up" />
            {isNonGstSession ? (
              <>
                <StatCard icon="sales" tone="teal" label="GST Sales (This Month)" value={inr(metrics.gstMonthSales || metrics.monthSales)} delta={`${metrics.gstMonthBillsCount || 0} GST bills`} deltaDir="up" />
                <StatCard icon="reports" tone="purple" label="Non-GST Sales (This Month)" value={inr(metrics.nonGstMonthSales || 0)} delta={`${metrics.nonGstMonthBillsCount || 0} Non-GST bills`} deltaDir="flat" />
              </>
            ) : (
              <>
                <StatCard icon="box" tone="blue" label="Inventory Value" value={inrShort(metrics.inventoryValue)} delta={`Raw ${inrShort(metrics.rawValue)}`} deltaDir="flat" />
                <StatCard icon="reports" tone="teal" label="Est. Gross Profit" value={inrShort(metrics.totalProfit)} delta="margin ~17%" deltaDir="up" />
              </>
            )}
          </div>

          {/* Super Admin Monthly Billing Breakdown Card — Visible ONLY under Non-GST Session */}
          {isNonGstSession && (
            <div className="card mb-16" style={{ padding: 16, border: '2px solid var(--gold)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <h4 style={{ fontSize: 14, fontWeight: 800, textTransform: 'uppercase', color: 'var(--gold)', margin: 0 }}>
                  👑 Super Admin Monthly Sales &amp; Bills Summary (As of Now)
                </h4>
                <div style={{ display: 'flex', gap: 6 }}>
                  <a href="/gst-history" className="btn btn-sm btn-gold">GST History</a>
                  <a href="/non-gst-history" className="btn btn-sm btn-primary">Non-GST History</a>
                </div>
              </div>
              <div className="table-wrap">
                <table className="tbl" style={{ fontSize: 13 }}>
                  <thead>
                    <tr style={{ background: 'var(--surface-2)' }}>
                      <th>Billing Stream</th>
                      <th className="num">No. of Bills Generated</th>
                      <th className="num">Total Amount Sold (Current Month)</th>
                      <th>Inventory Status</th>
                      <th>Quick Voucher Station</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td className="cell-strong"><Badge tone="green" noDot>GST Tax Billing</Badge></td>
                      <td className="num cell-strong">{metrics.gstMonthBillsCount || 0} bills</td>
                      <td className="num cell-strong" style={{ color: 'var(--gold)' }}>{inr(metrics.gstMonthSales || metrics.monthSales)}</td>
                      <td><span className="tiny muted">Shared Products Stock</span></td>
                      <td><a href="/gst-billing" className="btn btn-sm">Open GST Billing</a></td>
                    </tr>
                    <tr>
                      <td className="cell-strong"><Badge tone="purple" noDot>Non-GST Billing</Badge></td>
                      <td className="num cell-strong">{metrics.nonGstMonthBillsCount || 0} bills</td>
                      <td className="num cell-strong" style={{ color: 'var(--purple)' }}>{inr(metrics.nonGstMonthSales || 0)}</td>
                      <td><span className="tiny muted">Shared Products Stock</span></td>
                      <td><a href="/non-gst-billing" className="btn btn-sm btn-primary">Open Non-GST Billing</a></td>
                    </tr>
                    <tr style={{ background: 'var(--gold-soft)', fontWeight: 800 }}>
                      <td style={{ color: 'var(--gold-deep)' }}>TOTAL COMBINED (AS OF NOW)</td>
                      <td className="num" style={{ color: 'var(--gold-deep)', fontSize: 14 }}>{metrics.monthBillsCount || 0} bills</td>
                      <td className="num" style={{ color: 'var(--gold-deep)', fontSize: 16 }}>{inr(metrics.monthSalesTotal || metrics.monthSales)}</td>
                      <td colSpan={2} style={{ color: 'var(--gold-deep)', fontSize: 12 }}>Combined Month Sales Snapshot</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* MANAGER SPECIFIC VIEW */}
      {isManager && (
        <div style={{ marginBottom: 20 }}>
          {/* Manager Quick Action Banner */}
          <div className="card" style={{ padding: 16, marginBottom: 16, background: 'var(--gold-soft)', border: '1px solid var(--gold)' }}>
            <h3 style={{ fontSize: 15, fontWeight: 800, color: 'var(--gold-deep)', marginBottom: 6 }}>
              📋 Manager Control Dashboard
            </h3>
            <p className="tiny" style={{ color: 'var(--text)', marginBottom: 12 }}>
              Monitor cashier sales performance, inspect live bills, verify product inventory levels, and manage sales orders.
            </p>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <a href="/erp-billing" className="btn btn-sm btn-gold"><Icon name="rupee" size={14} /> Open ERP Billing</a>
              <a href="/billing-history" className="btn btn-sm"><Icon name="billing" size={14} /> Billing History</a>
              <a href="/products" className="btn btn-sm"><Icon name="products" size={14} /> Product Master</a>
              <a href="/inventory" className="btn btn-sm"><Icon name="inventory" size={14} /> Inventory Stock</a>
              <a href="/reports" className="btn btn-sm"><Icon name="reports" size={14} /> Sales Reports</a>
            </div>
          </div>

          {/* Cashiers Performance Table for Manager */}
          <div className="card mb-16" style={{ padding: 16 }}>
            <h4 style={{ fontSize: 14, fontWeight: 700, textTransform: 'uppercase', color: 'var(--gold)', marginBottom: 12 }}>
              💳 Cashier Performance &amp; Sales Summary
            </h4>
            <div className="table-wrap">
              <table className="tbl">
                <thead>
                  <tr>
                    <th>Cashier / Staff</th>
                    <th className="num">Bills Issued</th>
                    <th className="num">Cash / Paid Collections</th>
                    <th className="num">Credit / Dues Sales</th>
                    <th className="num">Total Sales Generated</th>
                  </tr>
                </thead>
                <tbody>
                  {cashierStats.map((c, i) => (
                    <tr key={i}>
                      <td className="cell-strong">{c.name}</td>
                      <td className="num">{c.count} bills</td>
                      <td className="num" style={{ color: 'var(--green)', fontWeight: 600 }}>{inr(c.cash)}</td>
                      <td className="num" style={{ color: 'var(--red)' }}>{inr(c.credit)}</td>
                      <td className="num cell-strong" style={{ fontSize: 14, color: 'var(--gold)' }}>{inr(c.total)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

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
            {metrics.lowStock.slice(0, 3).map((p: any) => (
              <div className="alert-row" key={p.id}>
                <div className="alert-ico" style={{ background: 'var(--red-soft)', color: 'var(--red)' }}><Icon name="alert" size={16} /></div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{p.name}</div>
                  <div className="tiny">Stock {num(p.stock)} / min {num(p.minStock)} {p.unit}s</div>
                </div>
                <Badge tone="red" noDot>Low</Badge>
              </div>
            ))}
            {metrics.lowRaw.slice(0, 2).map((r: any) => (
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
            {activity.map((a: any) => {
              const ic = ACT_ICON[a.icon as keyof typeof ACT_ICON] || ACT_ICON.sale
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

