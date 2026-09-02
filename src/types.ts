export type ID = string

export type PricingType = 'AGENCY' | 'WHOLESALE' | 'RETAIL'
export type BillingType = 'GST' | 'NON_GST'
export type AppRoleKey = 'super_admin' | 'admin' | 'manager' | 'cashier'

export interface Role {
  label: string
  access: '*' | string[]
}

export interface User {
  id: ID
  name: string
  role: string
  email: string
  phone: string
  roleLabel?: string
  access?: string | string[]
}

// A staff account that can sign in.
export interface AppUser {
  id: ID
  username: string
  name: string
  role: AppRoleKey | string
  passwordHash: string
  phone?: string
  active?: boolean
}

// Seller/company details printed on invoices.
export interface Company {
  name: string
  legal?: string
  address: string
  gstin: string
  stateCode: string
  state: string
  phone: string
  email: string
  fssai?: string
  bank?: { name: string; acc: string; ifsc: string }
}

export interface Brand {
  id: ID
  name: string
  type: string
  color: string
  contact: string
  phone: string
  gstin: string
}

export interface Product {
  id: ID
  code: string          // Product Code (synced with SKU)
  brandId: ID
  name: string
  category: string      // Category
  group?: string        // Group / Sub-category
  oilType: string
  pack: string
  unit: string
  sku: string           // SKU / Barcode
  hsn: string
  gst: number
  cost: number          // Purchase / Cost Rate
  price: number         // Generic / Retail fallback
  agencyRate: number    // Agency Rate
  wholesaleRate: number // Wholesale Rate
  retailRate: number    // Retail Rate
  mrp: number
  minStock: number
  stock: number
  status: 'Active' | 'Inactive'
  createdDate?: string
  updatedDate?: string
}

export interface PriceHistoryRecord {
  id: ID
  productId: ID
  productCode: string
  productName: string
  pricingType: PricingType
  oldRate: number
  newRate: number
  effectiveDate: string
  effectiveTime: string
  modifiedBy: string
  modifiedUserId: string
  reason?: string
  createdAt: string
}

export interface AuditRecord {
  id: ID
  user: string
  userId: string
  action: string
  module: string
  oldValue?: string
  newValue?: string
  date: string
  time: string
  createdAt: string
}

export interface RawMaterial {
  id: ID
  name: string
  unit: string
  stock: number
  minStock: number
  cost: number
  godown: string
}

export interface Supplier {
  id: ID
  name: string
  material: string
  contact: string
  phone: string
  gstin: string
  address: string
  rating: number
  due: number
}

export interface Customer {
  id: ID
  code?: string
  name: string
  type: string
  contact: string
  phone: string
  gstin: string
  address?: string
  area: string
  route: string
  priceList?: string
  creditLimit: number
  outstanding: number
  brandPref: string
}

export interface Purchase {
  id: ID
  supplierId: ID
  date: string
  material: string
  qty: number
  unit: string
  rate: number
  gst: number
  qc: string
  payStatus: string
  inward: boolean
}

export interface ProductionBatch {
  id: ID
  productId: ID
  plannedQty: number
  outputQty: number
  wastage: number
  status: string
  startDate: string
  mfgDate: string
  expDate: string
  rawCost: number
  packCost: number
  labourCost: number
}

export interface InvoiceItem {
  productId: ID
  productCode: string
  productName: string
  unit: string
  qty: number
  rate: number          // Applied effective selling rate snapshot
  mrp: number
  pricingType: PricingType
  appliedRate: number
  discPercent: number
  discAmount: number
  schemeAmount?: number
  taxableAmount: number
  gstRate: number
  gstAmount: number
  finalAmount: number
}

export interface SalesItem {
  productId: ID
  qty: number
  rate: number
  productCode?: string
  productName?: string
  unit?: string
  mrp?: number
  pricingType?: PricingType
  appliedRate?: number
  discPercent?: number
  discAmount?: number
  schemeAmount?: number
  taxableAmount?: number
  gstRate?: number
  gstAmount?: number
  finalAmount?: number
}

export interface DispatchDetails {
  poNumber?: string
  poDate?: string
  dispatchThrough?: string
  vehicleNumber?: string
  driverName?: string
  deliveryNote?: string
  gatePassNo?: string
}

export interface EWayBillDetails {
  supplyType?: string
  supplySubType?: string
  transportMode?: string
  transporterName?: string
  transporterId?: string
  transDocNo?: string
  transDocDate?: string
  transportDistance?: number
  ewbNo?: string
  ewbDate?: string
  validTill?: string
}

export interface EInvoiceDetails {
  irn?: string
  irnGenerated?: boolean
  cancellationStatus?: string
  invoiceStatus?: string
}

export interface LedgerEntry {
  ledgerName: string
  amount: number
}

export interface SalesOrder {
  id: ID
  voucherNo?: string
  voucherType?: string
  billingType: BillingType
  pricingType: PricingType
  customerId: ID
  date: string
  time?: string
  salesperson: string
  deliveryMan?: string
  godown?: string
  route?: string
  address?: string
  gstin?: string
  priceList?: string
  dispatch: string
  payStatus: string
  payMode?: string
  userId?: string
  userName?: string
  userRole?: string
  items: InvoiceItem[] | SalesItem[]
  subtotal?: number
  discountTotal?: number
  gstTotal?: number
  roundOff?: number
  grandTotal?: number
  ledgerEntries?: LedgerEntry[]
  dispatchDetails?: DispatchDetails
  ewbDetails?: EWayBillDetails
  eInvoiceDetails?: EInvoiceDetails
  status?: 'ACTIVE' | 'CANCELLED'
  cancelledBy?: string
  cancelledDate?: string
  cancelledReason?: string
  createdAt?: string
}

export interface Dispatch {
  id: ID
  soId: ID
  vehicle: string
  driver: string
  route: string
  status: string
  transport: number
  pod: boolean
}

export interface Expense {
  id: ID
  date: string
  head: string
  note: string
  amount: number
}

export interface Activity {
  id: ID
  type: string
  text: string
  time: string
  icon: string
}

// Shape of the whole in-memory / Firestore dataset.
export interface Dataset {
  brands: Brand[]
  products: Product[]
  rawMaterials: RawMaterial[]
  suppliers: Supplier[]
  purchases: Purchase[]
  production: ProductionBatch[]
  customers: Customer[]
  sales: SalesOrder[]
  dispatches: Dispatch[]
  expenses: Expense[]
  priceHistory?: PriceHistoryRecord[]
  auditLogs?: AuditRecord[]
}

export type CollectionKey = keyof Dataset

