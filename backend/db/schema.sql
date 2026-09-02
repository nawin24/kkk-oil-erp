-- ============================================================
-- KKK Oil Factory ERP — PostgreSQL schema
-- 21 tables covering the full factory flow.
-- Run:  psql -d kkk_erp -f schema.sql
-- ============================================================

DROP TABLE IF EXISTS notifications, dispatches, drivers, vehicles, payments, invoices,
  sales_order_items, sales_orders, customers, production_items, production_batches,
  stock_movements, inventory, purchase_items, purchases, suppliers, products, brands,
  expenses, users, roles CASCADE;

-- ---------- Auth ----------
CREATE TABLE roles (
  id          SERIAL PRIMARY KEY,
  key         VARCHAR(40) UNIQUE NOT NULL,
  label       VARCHAR(80) NOT NULL,
  permissions JSONB NOT NULL DEFAULT '[]'      -- ['dashboard','sales',...] or ['*']
);

CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  name          VARCHAR(120) NOT NULL,
  email         VARCHAR(160) UNIQUE NOT NULL,
  phone         VARCHAR(30),
  password_hash VARCHAR(255) NOT NULL,
  role_id       INT REFERENCES roles(id),
  active        BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMP DEFAULT now()
);

-- ---------- Catalog ----------
CREATE TABLE brands (
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(120) NOT NULL,
  type      VARCHAR(30) NOT NULL CHECK (type IN ('Own Brand','Third-party Brand')),
  color     VARCHAR(10) DEFAULT '#2563eb',
  logo_url  TEXT,
  contact   VARCHAR(160),
  phone     VARCHAR(30),
  gstin     VARCHAR(20),
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE products (
  id          SERIAL PRIMARY KEY,
  brand_id    INT REFERENCES brands(id) ON DELETE SET NULL,
  name        VARCHAR(180) NOT NULL,
  oil_type    VARCHAR(60),
  pack_size   VARCHAR(30),
  unit_type   VARCHAR(20),
  sku         VARCHAR(40) UNIQUE NOT NULL,
  hsn         VARCHAR(12),
  gst_pct     NUMERIC(5,2) DEFAULT 5,
  cost_price  NUMERIC(12,2) DEFAULT 0,
  sell_price  NUMERIC(12,2) DEFAULT 0,
  mrp         NUMERIC(12,2) DEFAULT 0,
  min_stock   NUMERIC(12,2) DEFAULT 0,
  stock       NUMERIC(12,2) DEFAULT 0,
  created_at  TIMESTAMP DEFAULT now()
);

-- ---------- Suppliers & Purchase ----------
CREATE TABLE suppliers (
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(160) NOT NULL,
  material  VARCHAR(120),
  contact   VARCHAR(120),
  phone     VARCHAR(30),
  gstin     VARCHAR(20),
  address   TEXT,
  rating    NUMERIC(2,1) DEFAULT 4,
  due       NUMERIC(14,2) DEFAULT 0
);

CREATE TABLE purchases (
  id           SERIAL PRIMARY KEY,
  po_no        VARCHAR(30) UNIQUE NOT NULL,
  supplier_id  INT REFERENCES suppliers(id),
  po_date      DATE NOT NULL,
  qc_status    VARCHAR(20) DEFAULT 'Pending' CHECK (qc_status IN ('Pending','Passed','Failed')),
  inward       BOOLEAN DEFAULT FALSE,
  pay_status   VARCHAR(20) DEFAULT 'Unpaid' CHECK (pay_status IN ('Unpaid','Partial','Paid')),
  total        NUMERIC(14,2) DEFAULT 0,
  created_at   TIMESTAMP DEFAULT now()
);

CREATE TABLE purchase_items (
  id           SERIAL PRIMARY KEY,
  purchase_id  INT REFERENCES purchases(id) ON DELETE CASCADE,
  material     VARCHAR(120) NOT NULL,
  qty          NUMERIC(14,2),
  unit         VARCHAR(12),
  rate         NUMERIC(12,2),
  gst_pct      NUMERIC(5,2) DEFAULT 5
);

-- ---------- Inventory ----------
CREATE TABLE inventory (
  id          SERIAL PRIMARY KEY,
  item_type   VARCHAR(20) NOT NULL CHECK (item_type IN ('finished','raw','packing','damaged','returned')),
  ref_id      INT,                              -- product_id for finished goods
  name        VARCHAR(160) NOT NULL,
  godown      VARCHAR(60) DEFAULT 'Main Godown',
  unit        VARCHAR(12),
  stock       NUMERIC(14,2) DEFAULT 0,
  min_stock   NUMERIC(14,2) DEFAULT 0,
  cost        NUMERIC(12,2) DEFAULT 0,
  batch_no    VARCHAR(30),
  mfg_date    DATE,
  exp_date    DATE
);

CREATE TABLE stock_movements (
  id          SERIAL PRIMARY KEY,
  item_type   VARCHAR(20),
  ref_id      INT,
  direction   VARCHAR(8) CHECK (direction IN ('in','out','adjust','transfer')),
  qty         NUMERIC(14,2),
  reason      VARCHAR(160),
  from_godown VARCHAR(60),
  to_godown   VARCHAR(60),
  created_by  INT REFERENCES users(id),
  created_at  TIMESTAMP DEFAULT now()
);

-- ---------- Production ----------
CREATE TABLE production_batches (
  id          SERIAL PRIMARY KEY,
  batch_no    VARCHAR(30) UNIQUE NOT NULL,
  product_id  INT REFERENCES products(id),
  planned_qty NUMERIC(12,2),
  output_qty  NUMERIC(12,2) DEFAULT 0,
  wastage     NUMERIC(12,2) DEFAULT 0,
  status      VARCHAR(20) DEFAULT 'Planned' CHECK (status IN ('Planned','In Progress','Completed')),
  start_date  DATE,
  mfg_date    DATE,
  exp_date    DATE,
  raw_cost    NUMERIC(14,2) DEFAULT 0,
  pack_cost   NUMERIC(14,2) DEFAULT 0,
  labour_cost NUMERIC(14,2) DEFAULT 0,
  created_at  TIMESTAMP DEFAULT now()
);

CREATE TABLE production_items (        -- raw/packing materials consumed in a batch
  id          SERIAL PRIMARY KEY,
  batch_id    INT REFERENCES production_batches(id) ON DELETE CASCADE,
  material    VARCHAR(120),
  qty         NUMERIC(14,2),
  unit        VARCHAR(12)
);

-- ---------- Customers & Sales ----------
CREATE TABLE customers (
  id           SERIAL PRIMARY KEY,
  name         VARCHAR(160) NOT NULL,
  cust_type    VARCHAR(20) CHECK (cust_type IN ('Dealer','Distributor','Wholesale','Retail')),
  contact      VARCHAR(120),
  phone        VARCHAR(30),
  gstin        VARCHAR(20),
  address      TEXT,
  area         VARCHAR(80),
  route        VARCHAR(20),
  credit_limit NUMERIC(14,2) DEFAULT 0,
  outstanding  NUMERIC(14,2) DEFAULT 0,
  brand_pref   VARCHAR(120)
);

CREATE TABLE sales_orders (
  id           SERIAL PRIMARY KEY,
  so_no        VARCHAR(30) UNIQUE NOT NULL,
  customer_id  INT REFERENCES customers(id),
  order_date   DATE NOT NULL,
  salesperson  VARCHAR(120),
  dispatch     VARCHAR(30) DEFAULT 'Order Received',
  pay_status   VARCHAR(20) DEFAULT 'Pending' CHECK (pay_status IN ('Pending','Partial','Paid')),
  discount     NUMERIC(14,2) DEFAULT 0,
  sub_total    NUMERIC(14,2) DEFAULT 0,
  gst_total    NUMERIC(14,2) DEFAULT 0,
  grand_total  NUMERIC(14,2) DEFAULT 0,
  created_at   TIMESTAMP DEFAULT now()
);

CREATE TABLE sales_order_items (
  id          SERIAL PRIMARY KEY,
  so_id       INT REFERENCES sales_orders(id) ON DELETE CASCADE,
  product_id  INT REFERENCES products(id),
  qty         NUMERIC(12,2),
  rate        NUMERIC(12,2),
  gst_pct     NUMERIC(5,2),
  discount    NUMERIC(12,2) DEFAULT 0
);

-- ---------- Billing ----------
CREATE TABLE invoices (
  id          SERIAL PRIMARY KEY,
  inv_no      VARCHAR(30) UNIQUE NOT NULL,
  so_id       INT REFERENCES sales_orders(id),
  inv_type    VARCHAR(20) DEFAULT 'Tax Invoice',   -- Proforma / Tax Invoice / Delivery Challan
  inv_date    DATE DEFAULT CURRENT_DATE,
  taxable     NUMERIC(14,2),
  gst_total   NUMERIC(14,2),
  grand_total NUMERIC(14,2),
  pay_status  VARCHAR(20) DEFAULT 'Pending'
);

CREATE TABLE payments (
  id          SERIAL PRIMARY KEY,
  party_type  VARCHAR(12) CHECK (party_type IN ('customer','supplier')),
  party_id    INT,
  ref_no      VARCHAR(40),                    -- invoice / PO reference
  amount      NUMERIC(14,2),
  mode        VARCHAR(20) DEFAULT 'Cash',
  pay_date    DATE DEFAULT CURRENT_DATE,
  note        TEXT
);

-- ---------- Logistics ----------
CREATE TABLE vehicles (
  id        SERIAL PRIMARY KEY,
  reg_no    VARCHAR(20) UNIQUE NOT NULL,
  type      VARCHAR(40),
  capacity  VARCHAR(40)
);

CREATE TABLE drivers (
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(120) NOT NULL,
  phone     VARCHAR(30),
  license   VARCHAR(40)
);

CREATE TABLE dispatches (
  id           SERIAL PRIMARY KEY,
  dsp_no       VARCHAR(30) UNIQUE NOT NULL,
  so_id        INT REFERENCES sales_orders(id),
  vehicle_id   INT REFERENCES vehicles(id),
  driver_id    INT REFERENCES drivers(id),
  route        VARCHAR(120),
  status       VARCHAR(30) DEFAULT 'Ready for Dispatch',
  transport_cost NUMERIC(12,2) DEFAULT 0,
  pod          BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMP DEFAULT now()
);

-- ---------- Accounts ----------
CREATE TABLE expenses (
  id        SERIAL PRIMARY KEY,
  voucher   VARCHAR(30),
  head      VARCHAR(40),                       -- Transport / Labour / Electricity / Production / Misc
  note      TEXT,
  amount    NUMERIC(14,2),
  exp_date  DATE DEFAULT CURRENT_DATE
);

-- ---------- Notifications ----------
CREATE TABLE notifications (
  id        SERIAL PRIMARY KEY,
  kind      VARCHAR(40),                       -- low_stock / payment_due / dispatch / expiry ...
  message   TEXT,
  severity  VARCHAR(10) DEFAULT 'info',
  is_read   BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT now()
);

-- ---------- Helpful indexes ----------
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_soitems_so ON sales_order_items(so_id);
CREATE INDEX idx_soitems_prod ON sales_order_items(product_id);
CREATE INDEX idx_sales_customer ON sales_orders(customer_id);
CREATE INDEX idx_purchase_supplier ON purchases(supplier_id);
CREATE INDEX idx_dispatch_so ON dispatches(so_id);
