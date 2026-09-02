import { createContext, useContext, useState, useMemo, useCallback } from 'react'
import * as seed from '../data/seed.js'
import { orderTotals, orderProfit, monthKey, isSameDay, todayISO } from '../utils/helpers.js'

const DataContext = createContext(null)
const LS_KEY = 'kkk_erp_data_v1'

const initial = () => ({
  brands: seed.BRANDS,
  products: seed.PRODUCTS,
  rawMaterials: seed.RAW_MATERIALS,
  suppliers: seed.SUPPLIERS,
  purchases: seed.PURCHASES,
  production: seed.PRODUCTION,
  customers: seed.CUSTOMERS,
  sales: seed.SALES,
  dispatches: seed.DISPATCHES,
  expenses: seed.EXPENSES,
})

function load() {
  try {
    const saved = localStorage.getItem(LS_KEY)
    if (saved) return JSON.parse(saved)
  } catch (e) { /* ignore */ }
  return initial()
}

export function DataProvider({ children }) {
  const [db, setDb] = useState(load)

  const persist = useCallback((next) => {
    setDb(next)
    localStorage.setItem(LS_KEY, JSON.stringify(next))
  }, [])

  // Generic CRUD on a collection key
  const upsert = useCallback((key, record) => {
    persist({
      ...db,
      [key]: db[key].some((r) => r.id === record.id)
        ? db[key].map((r) => (r.id === record.id ? record : r))
        : [record, ...db[key]],
    })
  }, [db, persist])

  const remove = useCallback((key, id) => {
    persist({ ...db, [key]: db[key].filter((r) => r.id !== id) })
  }, [db, persist])

  const resetDemo = useCallback(() => persist(initial()), [persist])

  // ---------- Lookups ----------
  const productMap = useMemo(() => Object.fromEntries(db.products.map((p) => [p.id, p])), [db.products])
  const brandMap = useMemo(() => Object.fromEntries(db.brands.map((b) => [b.id, b])), [db.brands])
  const customerMap = useMemo(() => Object.fromEntries(db.customers.map((c) => [c.id, c])), [db.customers])
  const supplierMap = useMemo(() => Object.fromEntries(db.suppliers.map((s) => [s.id, s])), [db.suppliers])

  // ---------- Derived analytics ----------
  const metrics = useMemo(() => {
    const today = todayISO()
    const thisMonth = monthKey(today)

    let todaySales = 0, monthSales = 0, totalRevenue = 0, totalProfit = 0, customerOutstanding = 0
    db.sales.forEach((so) => {
      const { total } = orderTotals(so.items, productMap)
      totalRevenue += total
      totalProfit += orderProfit(so.items, productMap)
      if (isSameDay(so.date, today)) todaySales += total
      if (monthKey(so.date) === thisMonth) monthSales += total
    })
    db.customers.forEach((c) => { customerOutstanding += c.outstanding })

    // inventory value (finished + raw)
    const finishedValue = db.products.reduce((s, p) => s + p.stock * p.cost, 0)
    const rawValue = db.rawMaterials.reduce((s, r) => s + r.stock * r.cost, 0)
    const inventoryValue = finishedValue + rawValue

    const lowStock = db.products.filter((p) => p.stock <= p.minStock)
    const lowRaw = db.rawMaterials.filter((r) => r.stock <= r.minStock)

    const pendingProduction = db.production.filter((b) => b.status !== 'Completed')
    const pendingDispatch = db.sales.filter((s) => !['Delivered', 'Returned'].includes(s.dispatch))

    const purchaseDue = db.suppliers.reduce((s, sup) => s + sup.due, 0)
    const totalExpense = db.expenses.reduce((s, e) => s + e.amount, 0)

    // brand-wise sales
    const brandSales = {}
    db.sales.forEach((so) => {
      so.items.forEach((it) => {
        const p = productMap[it.productId]
        if (!p) return
        const b = brandMap[p.brandId]
        brandSales[b.name] = (brandSales[b.name] || 0) + it.qty * it.rate
      })
    })

    // product-wise sales (top)
    const prodSales = {}
    db.sales.forEach((so) => {
      so.items.forEach((it) => {
        prodSales[it.productId] = (prodSales[it.productId] || 0) + it.qty * it.rate
      })
    })

    // dispatch status counts
    const dispatchStatus = {}
    db.sales.forEach((so) => { dispatchStatus[so.dispatch] = (dispatchStatus[so.dispatch] || 0) + 1 })

    return {
      todaySales, monthSales, totalRevenue, totalProfit, customerOutstanding,
      inventoryValue, finishedValue, rawValue,
      lowStock, lowRaw, pendingProduction, pendingDispatch,
      purchaseDue, totalExpense, brandSales, prodSales, dispatchStatus,
    }
  }, [db, productMap, brandMap])

  // 7-day sales trend (synthetic shape based on real orders)
  const salesTrend = useMemo(() => {
    const days = []
    for (let i = 6; i >= 0; i--) {
      const d = new Date()
      d.setDate(d.getDate() - i)
      const iso = d.toISOString().slice(0, 10)
      let sales = 0
      db.sales.forEach((so) => {
        if (isSameDay(so.date, iso)) sales += orderTotals(so.items, productMap).total
      })
      // seed a baseline so the chart is never flat-empty on demo
      const base = [82000, 96000, 71000, 118000, 104000, 132000, 0][6 - i]
      days.push({ day: d.toLocaleDateString('en-IN', { weekday: 'short' }), sales: sales || base })
    }
    return days
  }, [db.sales, productMap])

  // monthly purchase vs sales (6 months synthetic + current real)
  const monthlyTrend = useMemo(() => {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']
    const purchaseBase = [620, 580, 710, 660, 740, 690]
    const salesBase = [780, 820, 760, 910, 980, Math.round(metrics.monthSales / 1000) || 1040]
    return labels.map((m, i) => ({ month: m, purchase: purchaseBase[i] * 1000, sales: salesBase[i] * 1000 }))
  }, [metrics.monthSales])

  const value = {
    ...db,
    productMap, brandMap, customerMap, supplierMap,
    metrics, salesTrend, monthlyTrend,
    activity: seed.STATIC_ACTIVITY,
    upsert, remove, resetDemo,
  }

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>
}

export const useData = () => useContext(DataContext)
