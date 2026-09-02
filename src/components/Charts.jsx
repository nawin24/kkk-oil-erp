import {
  AreaChart, Area, BarChart, Bar, LineChart, Line, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts'
import { inrShort } from '../utils/helpers.js'

const GRID = '#eef0ed'
const AXIS = { fontSize: 11, fill: '#8b948d' }
export const PIE_COLORS = ['#e3a92e', '#1f8a5b', '#2563eb', '#7c3aed', '#d97706', '#0d9488', '#dc2626']

const tipStyle = {
  background: '#10231b', border: 'none', borderRadius: 10, color: '#fff',
  fontSize: 12, padding: '8px 12px', boxShadow: '0 8px 24px rgba(0,0,0,.2)',
}

export function SalesTrendChart({ data }) {
  return (
    <ResponsiveContainer width="100%" height={250}>
      <AreaChart data={data} margin={{ top: 10, right: 8, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="gSales" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#e3a92e" stopOpacity={0.35} />
            <stop offset="100%" stopColor="#e3a92e" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke={GRID} vertical={false} />
        <XAxis dataKey="day" tick={AXIS} axisLine={false} tickLine={false} />
        <YAxis tick={AXIS} axisLine={false} tickLine={false} tickFormatter={inrShort} width={56} />
        <Tooltip contentStyle={tipStyle} formatter={(v) => [inrShort(v), 'Sales']} cursor={{ stroke: '#e3a92e', strokeWidth: 1 }} />
        <Area type="monotone" dataKey="sales" stroke="#b7791f" strokeWidth={2.5} fill="url(#gSales)" />
      </AreaChart>
    </ResponsiveContainer>
  )
}

export function MonthlyBarChart({ data }) {
  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={data} margin={{ top: 10, right: 8, left: 0, bottom: 0 }} barGap={4}>
        <CartesianGrid strokeDasharray="3 3" stroke={GRID} vertical={false} />
        <XAxis dataKey="month" tick={AXIS} axisLine={false} tickLine={false} />
        <YAxis tick={AXIS} axisLine={false} tickLine={false} tickFormatter={inrShort} width={56} />
        <Tooltip contentStyle={tipStyle} formatter={(v, n) => [inrShort(v), n === 'sales' ? 'Sales' : 'Purchase']} cursor={{ fill: 'rgba(16,35,27,.04)' }} />
        <Legend iconType="circle" wrapperStyle={{ fontSize: 12, paddingTop: 8 }} />
        <Bar dataKey="purchase" name="Purchase" fill="#cfd6cf" radius={[5, 5, 0, 0]} maxBarSize={26} />
        <Bar dataKey="sales" name="Sales" fill="#e3a92e" radius={[5, 5, 0, 0]} maxBarSize={26} />
      </BarChart>
    </ResponsiveContainer>
  )
}

export function BrandPie({ data }) {
  return (
    <ResponsiveContainer width="100%" height={230}>
      <PieChart>
        <Pie data={data} dataKey="value" nameKey="name" innerRadius={52} outerRadius={86} paddingAngle={2} stroke="none">
          {data.map((e, i) => <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />)}
        </Pie>
        <Tooltip contentStyle={tipStyle} formatter={(v, n) => [inrShort(v), n]} />
      </PieChart>
    </ResponsiveContainer>
  )
}

export function StockBarChart({ data }) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={data} layout="vertical" margin={{ top: 4, right: 16, left: 8, bottom: 4 }}>
        <CartesianGrid strokeDasharray="3 3" stroke={GRID} horizontal={false} />
        <XAxis type="number" tick={AXIS} axisLine={false} tickLine={false} />
        <YAxis type="category" dataKey="name" tick={{ fontSize: 11, fill: '#5b665f' }} axisLine={false} tickLine={false} width={120} />
        <Tooltip contentStyle={tipStyle} cursor={{ fill: 'rgba(16,35,27,.04)' }} />
        <Bar dataKey="stock" name="Units" fill="#1f8a5b" radius={[0, 5, 5, 0]} maxBarSize={18} />
      </BarChart>
    </ResponsiveContainer>
  )
}

export function ProductionLineChart({ data }) {
  return (
    <ResponsiveContainer width="100%" height={250}>
      <LineChart data={data} margin={{ top: 10, right: 8, left: 0, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke={GRID} vertical={false} />
        <XAxis dataKey="label" tick={AXIS} axisLine={false} tickLine={false} />
        <YAxis tick={AXIS} axisLine={false} tickLine={false} width={42} />
        <Tooltip contentStyle={tipStyle} />
        <Line type="monotone" dataKey="output" name="Output" stroke="#2563eb" strokeWidth={2.5} dot={{ r: 3 }} />
        <Line type="monotone" dataKey="wastage" name="Wastage" stroke="#dc2626" strokeWidth={2} dot={{ r: 3 }} strokeDasharray="4 3" />
      </LineChart>
    </ResponsiveContainer>
  )
}

export function MiniDonut({ data }) {
  const total = data.reduce((s, d) => s + d.value, 0)
  return (
    <ResponsiveContainer width="100%" height={180}>
      <PieChart>
        <Pie data={data} dataKey="value" innerRadius={46} outerRadius={70} paddingAngle={2} stroke="none">
          {data.map((e, i) => <Cell key={i} fill={e.color || PIE_COLORS[i % PIE_COLORS.length]} />)}
        </Pie>
        <Tooltip contentStyle={tipStyle} formatter={(v, n) => [`${v} (${Math.round(v / total * 100)}%)`, n]} />
      </PieChart>
    </ResponsiveContainer>
  )
}
