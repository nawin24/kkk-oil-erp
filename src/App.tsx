import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/AuthContext'
import Layout from './components/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Brands from './pages/Brands'
import Products from './pages/Products'
import PriceManagement from './pages/PriceManagement'
import PriceHistory from './pages/PriceHistory'
import ErpBilling from './pages/ErpBilling'
import BillingHistory from './pages/BillingHistory'
import Purchase from './pages/Purchase'
import Inventory from './pages/Inventory'
import Production from './pages/Production'
import Sales from './pages/Sales'
import Logistics from './pages/Logistics'
import Counter from './pages/Counter'
import Billing from './pages/Billing'
import Customers from './pages/Customers'
import Suppliers from './pages/Suppliers'
import Reports from './pages/Reports'
import Settings from './pages/Settings'

function ProtectedRoute({ module, children }: { module: string; children: JSX.Element }) {
  const { can } = useAuth()
  if (!can(module)) {
    return <Navigate to="/" replace />
  }
  return children
}

function SuperAdminRoute({ children }: { children: JSX.Element }) {
  const { isSuperAdmin, isNonGstSession } = useAuth()
  if (!isSuperAdmin || !isNonGstSession) {
    return <Navigate to="/" replace />
  }
  return children
}

export default function App() {
  const { user, isCashier } = useAuth()
  if (!user) return <Login />

  const isNonGstSession = user.activeMode === 'NON_GST'

  return (
    <Layout>
      <Routes>
        <Route
          path="/"
          element={
            isCashier ? (
              <Navigate to="/gst-billing" replace />
            ) : (
              <Dashboard />
            )
          }
        />
        <Route path="/brands" element={<ProtectedRoute module="brands"><Brands /></ProtectedRoute>} />
        <Route path="/products" element={<ProtectedRoute module="products"><Products /></ProtectedRoute>} />
        <Route path="/price-management" element={<ProtectedRoute module="price_management"><PriceManagement /></ProtectedRoute>} />
        <Route path="/price-history" element={<ProtectedRoute module="price_history"><PriceHistory /></ProtectedRoute>} />

        {/* GST Billing & History */}
        <Route path="/gst-billing" element={<ProtectedRoute module="billing"><ErpBilling forcedBillingType="GST" /></ProtectedRoute>} />
        <Route path="/erp-billing" element={<ProtectedRoute module="billing"><ErpBilling forcedBillingType="GST" /></ProtectedRoute>} />
        <Route path="/gst-history" element={<ProtectedRoute module="billing"><BillingHistory forcedBillingType="GST" /></ProtectedRoute>} />
        <Route path="/billing-history" element={<ProtectedRoute module="billing"><BillingHistory forcedBillingType="GST" /></ProtectedRoute>} />

        {/* Non-GST Billing & History (Exclusive to Super Admin) */}
        <Route path="/non-gst" element={<SuperAdminRoute><ErpBilling forcedBillingType="NON_GST" /></SuperAdminRoute>} />
        <Route path="/non-gst-billing" element={<SuperAdminRoute><ErpBilling forcedBillingType="NON_GST" /></SuperAdminRoute>} />
        <Route path="/non-gst-history" element={<SuperAdminRoute><BillingHistory forcedBillingType="NON_GST" /></SuperAdminRoute>} />

        <Route path="/purchase" element={<ProtectedRoute module="purchase"><Purchase /></ProtectedRoute>} />
        <Route path="/inventory" element={<ProtectedRoute module="inventory"><Inventory /></ProtectedRoute>} />
        <Route path="/production" element={<ProtectedRoute module="production"><Production /></ProtectedRoute>} />
        <Route path="/sales" element={<ProtectedRoute module="sales"><Sales /></ProtectedRoute>} />
        <Route path="/logistics" element={<ProtectedRoute module="logistics"><Logistics /></ProtectedRoute>} />
        <Route path="/counter" element={<ProtectedRoute module="billing"><Counter /></ProtectedRoute>} />
        <Route path="/billing" element={<ProtectedRoute module="billing"><Billing /></ProtectedRoute>} />
        <Route path="/customers" element={<ProtectedRoute module="customers"><Customers /></ProtectedRoute>} />
        <Route path="/suppliers" element={<ProtectedRoute module="suppliers"><Suppliers /></ProtectedRoute>} />
        <Route path="/reports" element={<ProtectedRoute module="reports"><Reports /></ProtectedRoute>} />
        <Route path="/settings" element={<ProtectedRoute module="settings"><Settings /></ProtectedRoute>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Layout>
  )
}


