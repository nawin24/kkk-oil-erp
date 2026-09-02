import {
  createContext, useContext, useState, useMemo, useCallback, useEffect,
  type ReactNode,
} from 'react'
import {
  collection, getDocs, setDoc, deleteDoc, doc, writeBatch,
} from 'firebase/firestore'
import * as seed from '../data/seed'
import { db as fdb, isFirebaseConfigured } from '../firebase/config'
import { orderTotals, orderProfit, monthKey, isSameDay, todayISO } from '../utils/helpers'
import { COMPANY as DEFAULT_COMPANY } from '../utils/invoice'
import type { Dataset, CollectionKey, Company } from '../types'

const DataContext = createContext<any>(null)
const LS_KEY = 'kkk_erp_data_v1'
const CONFIG_KEY = 'kkk_erp_config_v1'

const COLLECTIONS: CollectionKey[] = [
  'brands', 'products', 'rawMaterials', 'suppliers', 'purchases',
  'production', 'customers', 'sales', 'dispatches', 'expenses',
]

const HISTORY_KEY = 'kkk_erp_price_history_v1'
const AUDIT_KEY = 'kkk_erp_audit_v1'

const initial = (): Dataset => ({
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
  priceHistory: [],
  auditLogs: [],
})

const emptyDataset = (): Dataset => ({
  brands: [], products: [], rawMaterials: [], suppliers: [], purchases: [],
  production: [], customers: [], sales: [], dispatches: [], expenses: [],
  priceHistory: [], auditLogs: [],
})

function loadLocal(): Dataset {
  try {
    const saved = localStorage.getItem(LS_KEY)
    if (saved) {
      const parsed = JSON.parse(saved)
      const existingProdIds = new Set((parsed.products || []).map((p: any) => p.id))
      const missingProducts = seed.PRODUCTS.filter((sp) => !existingProdIds.has(sp.id))

      const existingBrandIds = new Set((parsed.brands || []).map((b: any) => b.id))
      const missingBrands = seed.BRANDS.filter((sb) => !existingBrandIds.has(sb.id))

      return {
        ...initial(),
        ...parsed,
        products: [...(parsed.products || []), ...missingProducts],
        brands: [...(parsed.brands || []), ...missingBrands],
        priceHistory: parsed.priceHistory || loadExtra(HISTORY_KEY),
        auditLogs: parsed.auditLogs || loadExtra(AUDIT_KEY),
      }
    }
  } catch { /* ignore */ }
  return { ...initial(), priceHistory: loadExtra(HISTORY_KEY), auditLogs: loadExtra(AUDIT_KEY) }
}

function loadExtra(key: string): any[] {
  try {
    const saved = localStorage.getItem(key)
    if (saved) return JSON.parse(saved)
  } catch { /* ignore */ }
  return []
}

function loadConfig(): { company: Company } {
  try {
    const saved = localStorage.getItem(CONFIG_KEY)
    if (saved) {
      const parsed = JSON.parse(saved)
      return { company: { ...DEFAULT_COMPANY, ...(parsed.company || {}) } }
    }
  } catch { /* ignore */ }
  return { company: { ...DEFAULT_COMPANY } }
}

export function DataProvider({ children }: { children: ReactNode }) {
  const [db, setDb] = useState<Dataset>(() => loadLocal())
  const [priceHistory, setPriceHistory] = useState<any[]>(() => loadExtra(HISTORY_KEY))
  const [auditLogs, setAuditLogs] = useState<any[]>(() => loadExtra(AUDIT_KEY))

  const [ready, setReady] = useState(!isFirebaseConfigured)
  const [company, setCompany] = useState<Company>(() => loadConfig().company)

  const saveCompany = useCallback((next: Company) => {
    setCompany(next)
    localStorage.setItem(CONFIG_KEY, JSON.stringify({ company: next }))
  }, [])

  useEffect(() => {
    if (!isFirebaseConfigured || !fdb) return
    let cancelled = false
    ;(async () => {
      try {
        const next: Partial<Dataset> = {}
        let anyData = false
        for (const key of COLLECTIONS) {
          const snap = await getDocs(collection(fdb!, key))
          const rows = snap.docs.map((d) => d.data()) as any[]
          if (rows.length) anyData = true
          ;(next as any)[key] = rows
        }
        if (cancelled) return

        const local = loadLocal()
        const mergedProducts = [...(next.products || [])]
        const existingProdIds = new Set(mergedProducts.map((p: any) => p.id))
        local.products.forEach((lp) => {
          if (!existingProdIds.has(lp.id)) mergedProducts.push(lp)
        })

        const mergedBrands = [...(next.brands || [])]
        const existingBrandIds = new Set(mergedBrands.map((b: any) => b.id))
        local.brands.forEach((lb) => {
          if (!existingBrandIds.has(lb.id)) mergedBrands.push(lb)
        })

        const finalDb = {
          ...local,
          ...next,
          products: mergedProducts,
          brands: mergedBrands,
        }

        setDb(finalDb)
        localStorage.setItem(LS_KEY, JSON.stringify(finalDb))
        setReady(true)
      } catch (e) {
        console.error('Firestore load failed, using seed & local data:', e)
        if (!cancelled) {
          setDb(loadLocal())
          setReady(true)
        }
      }
    })()
    return () => { cancelled = true }
  }, [])

  const persistLocal = useCallback((next: Dataset) => {
    setDb(next)
    localStorage.setItem(LS_KEY, JSON.stringify(next))
  }, [])

  const addAuditLog = useCallback((userObj: any, action: string, module: string, oldValue?: string, newValue?: string) => {
    const record = {
      id: 'AUD-' + Date.now().toString(36),
      user: userObj?.name || 'System',
      userId: userObj?.id || 'sys',
      role: userObj?.roleLabel || 'System',
      action,
      module,
      details: oldValue && newValue ? `${oldValue} → ${newValue}` : (oldValue || newValue || ''),
      timestamp: new Date().toISOString(),
    }
    setAuditLogs((prev) => {
      const next = [record, ...prev].slice(0, 200)
      localStorage.setItem(AUDIT_KEY, JSON.stringify(next))
      return next
    })
    if (isFirebaseConfigured && fdb) {
      setDoc(doc(fdb, 'auditLogs', record.id), record, { merge: true }).catch(() => {})
    }
  }, [])

  const updateProductRate = useCallback((productId: string, pricingType: string, newRate: number, effectiveDate: string, userObj?: any) => {
    const p = db.products.find((x) => x.id === productId)
    if (!p) return

    const oldRate = pricingType === 'AGENCY' ? p.agencyRate : pricingType === 'WHOLESALE' ? p.wholesaleRate : p.retailRate
    if (oldRate === newRate) return

    const historyRecord = {
      id: 'PH-' + Date.now().toString(36),
      productId,
      productName: p.name,
      pricingType,
      oldRate,
      newRate,
      effectiveDate,
      updatedBy: userObj?.name || 'Admin',
      updatedAt: new Date().toISOString(),
    }

    setPriceHistory((prev) => {
      const next = [historyRecord, ...prev]
      localStorage.setItem(HISTORY_KEY, JSON.stringify(next))
      return next
    })

    const patch: any = { updatedDate: todayISO() }
    if (pricingType === 'AGENCY') patch.agencyRate = newRate
    if (pricingType === 'WHOLESALE') patch.wholesaleRate = newRate
    if (pricingType === 'RETAIL') { patch.retailRate = newRate; patch.price = newRate }

    const updatedProduct = { ...p, ...patch }
    setDb((prev) => {
      const nextProds = prev.products.map((x) => (x.id === productId ? updatedProduct : x))
      const next = { ...prev, products: nextProds }
      localStorage.setItem(LS_KEY, JSON.stringify(next))
      return next
    })

    if (isFirebaseConfigured && fdb) {
      setDoc(doc(fdb, 'products', productId), updatedProduct, { merge: true }).catch((e) => console.error('Firestore write failed:', e))
    }

    addAuditLog(userObj, 'PRICE_CHANGE', 'PRICE_MANAGEMENT', `${pricingType}: ₹${oldRate}`, `${pricingType}: ₹${newRate} (Effective ${effectiveDate})`)
  }, [db.products, addAuditLog])

  const upsert = useCallback((key: CollectionKey, record: any) => {
    setDb((prev) => {
      const list = prev[key] as any[]
      const nextList = list.some((r) => r.id === record.id)
        ? list.map((r) => (r.id === record.id ? record : r))
        : [record, ...list]
      const next = { ...prev, [key]: nextList }
      localStorage.setItem(LS_KEY, JSON.stringify(next))
      return next
    })
    if (isFirebaseConfigured && fdb) {
      setDoc(doc(fdb, key, record.id), record, { merge: true }).catch((e) =>
        console.error('Firestore write failed:', e))
    }
  }, [])

  const remove = useCallback((key: CollectionKey, id: string) => {
    setDb((prev) => {
      const next = { ...prev, [key]: (prev[key] as any[]).filter((r) => r.id !== id) }
      if (!isFirebaseConfigured) localStorage.setItem(LS_KEY, JSON.stringify(next))
      return next
    })
    if (isFirebaseConfigured && fdb) {
      deleteDoc(doc(fdb, key, id)).catch((e) =>
        console.error('Firestore delete failed:', e))
    }
  }, [])

  const resetDemo = useCallback(() => persistLocal(initial()), [persistLocal])
  const resetEmpty = useCallback(() => persistLocal(emptyDataset()), [persistLocal])

  const seedToFirestore = useCallback(async () => {
    if (!isFirebaseConfigured || !fdb) {
      throw new Error('Connect Firebase first (add credentials to .env).')
    }
    const seeded = initial()
    const batch = writeBatch(fdb)
    for (const key of COLLECTIONS) {
      ;(seeded[key] as any[]).forEach((r) => batch.set(doc(fdb!, key, r.id), r))
    }
    await batch.commit()
    setDb(seeded)
  }, [])

  const productMap = useMemo(() => Object.fromEntries(db.products.map((p) => [p.id, p])), [db.products])
  const brandMap = useMemo(() => Object.fromEntries(db.brands.map((b) => [b.id, b])), [db.brands])
  const customerMap = useMemo(() => Object.fromEntries(db.customers.map((c) => [c.id, c])), [db.customers])
  const supplierMap = useMemo(() => Object.fromEntries(db.suppliers.map((s) => [s.id, s])), [db.suppliers])

  // Filter GST sales only for general dashboards/metrics so Non-GST data is isolated to Super Admin
  const metrics = useMemo(() => {
    const today = todayISO()
    const thisMonth = monthKey(today)

    let todaySales = 0, monthSales = 0, totalRevenue = 0, totalProfit = 0, customerOutstanding = 0
    let monthBillsCount = 0, monthSalesTotal = 0, todayBillsCount = 0
    let gstMonthBillsCount = 0, gstMonthSales = 0
    let nonGstMonthBillsCount = 0, nonGstMonthSales = 0

    const gstSales = db.sales.filter((s: any) => s.billingType !== 'NON_GST' && s.status !== 'CANCELLED')
    const allActiveSales = db.sales.filter((s: any) => s.status !== 'CANCELLED')

    gstSales.forEach((so: any) => {
      const { total } = orderTotals(so.items, productMap)
      const grand = so.grandTotal || so.total || total
      totalRevenue += grand
      totalProfit += orderProfit(so.items, productMap)
      if (isSameDay(so.date, today)) todaySales += grand
      if (monthKey(so.date) === thisMonth) {
        monthSales += grand
        gstMonthBillsCount += 1
        gstMonthSales += grand
      }
    })

    allActiveSales.forEach((so: any) => {
      const { total } = orderTotals(so.items, productMap)
      const grand = so.grandTotal || so.total || total
      const isNonGst = (so.billingType || (so.id.startsWith('NG') ? 'NON_GST' : 'GST')) === 'NON_GST'

      if (isSameDay(so.date, today)) todayBillsCount += 1
      if (monthKey(so.date) === thisMonth) {
        monthBillsCount += 1
        monthSalesTotal += grand
        if (isNonGst) {
          nonGstMonthBillsCount += 1
          nonGstMonthSales += grand
        }
      }
    })

    db.customers.forEach((c) => { customerOutstanding += c.outstanding })

    const finishedValue = db.products.reduce((s, p) => s + p.stock * p.cost, 0)
    const rawValue = db.rawMaterials.reduce((s, r) => s + r.stock * r.cost, 0)
    const inventoryValue = finishedValue + rawValue

    const lowStock = db.products.filter((p) => p.stock <= p.minStock)
    const lowRaw = db.rawMaterials.filter((r) => r.stock <= r.minStock)

    const pendingProduction = db.production.filter((b) => b.status !== 'Completed')
    const pendingDispatch = gstSales.filter((s) => !['Delivered', 'Returned'].includes(s.dispatch))

    const purchaseDue = db.suppliers.reduce((s, sup) => s + sup.due, 0)
    const totalExpense = db.expenses.reduce((s, e) => s + e.amount, 0)

    const brandSales: Record<string, number> = {}
    gstSales.forEach((so) => {
      so.items.forEach((it) => {
        const p = productMap[it.productId]
        if (!p) return
        const b = brandMap[p.brandId]
        if (!b) return
        brandSales[b.name] = (brandSales[b.name] || 0) + it.qty * it.rate
      })
    })

    const prodSales: Record<string, number> = {}
    gstSales.forEach((so) => {
      so.items.forEach((it) => {
        prodSales[it.productId] = (prodSales[it.productId] || 0) + it.qty * it.rate
      })
    })

    const dispatchStatus: Record<string, number> = {}
    gstSales.forEach((so) => { dispatchStatus[so.dispatch] = (dispatchStatus[so.dispatch] || 0) + 1 })

    return {
      todaySales, monthSales, totalRevenue, totalProfit, customerOutstanding,
      monthBillsCount, monthSalesTotal, todayBillsCount,
      gstMonthBillsCount, gstMonthSales, nonGstMonthBillsCount, nonGstMonthSales,
      inventoryValue, finishedValue, rawValue,
      lowStock, lowRaw, pendingProduction, pendingDispatch,
      purchaseDue, totalExpense, brandSales, prodSales, dispatchStatus,
    }
  }, [db, productMap, brandMap])

  const salesTrend = useMemo(() => {
    const days = []
    const gstSales = db.sales.filter((s) => s.billingType !== 'NON_GST')
    for (let i = 6; i >= 0; i--) {
      const d = new Date()
      d.setDate(d.getDate() - i)
      const iso = d.toISOString().slice(0, 10)
      let sales = 0
      gstSales.forEach((so) => {
        if (isSameDay(so.date, iso)) sales += orderTotals(so.items, productMap).total
      })
      const base = [82000, 96000, 71000, 118000, 104000, 132000, 0][6 - i]
      days.push({ day: d.toLocaleDateString('en-IN', { weekday: 'short' }), sales: sales || base })
    }
    return days
  }, [db.sales, productMap])

  const monthlyTrend = useMemo(() => {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']
    const purchaseBase = [620, 580, 710, 660, 740, 690]
    const salesBase = [780, 820, 760, 910, 980, Math.round(metrics.monthSales / 1000) || 1040]
    return labels.map((m, i) => ({ month: m, purchase: purchaseBase[i] * 1000, sales: salesBase[i] * 1000 }))
  }, [metrics.monthSales])

  const value = {
    ...db,
    priceHistory,
    auditLogs,
    ready,
    demoMode: !isFirebaseConfigured,
    company, saveCompany,
    productMap, brandMap, customerMap, supplierMap,
    metrics, salesTrend, monthlyTrend,
    activity: seed.STATIC_ACTIVITY,
    changePrice: updateProductRate, updateProductRate, addAuditLog,
    upsert, remove, resetDemo, resetEmpty, seedToFirestore,
  }

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export const useData = () => useContext(DataContext)

