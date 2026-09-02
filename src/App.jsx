import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/AuthContext.jsx'
import Layout from './components/Layout.jsx'
import Login from './pages/Login.jsx'
import Dashboard from './pages/Dashboard.jsx'
import Brands from './pages/Brands.jsx'
import Products from './pages/Products.jsx'
import Purchase from './pages/Purchase.jsx'
import Inventory from './pages/Inventory.jsx'
import Production from './pages/Production.jsx'
import Sales from './pages/Sales.jsx'
import Logistics from './pages/Logistics.jsx'
import Billing from './pages/Billing.jsx'
import Customers from './pages/Customers.jsx'
import Suppliers from './pages/Suppliers.jsx'
import Reports from './pages/Reports.jsx'
import Settings from './pages/Settings.jsx'

export default function App() {
  const { user } = useAuth()
  if (!user) return <Login />

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/brands" element={<Brands />} />
        <Route path="/products" element={<Products />} />
        <Route path="/purchase" element={<Purchase />} />
        <Route path="/inventory" element={<Inventory />} />
        <Route path="/production" element={<Production />} />
        <Route path="/sales" element={<Sales />} />
        <Route path="/logistics" element={<Logistics />} />
        <Route path="/billing" element={<Billing />} />
        <Route path="/customers" element={<Customers />} />
        <Route path="/suppliers" element={<Suppliers />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Layout>
  )
}
