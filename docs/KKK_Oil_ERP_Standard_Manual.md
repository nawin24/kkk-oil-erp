# KKK Oil Factory — Standard GST & All Roles Operational Manual
## Complete Path-Wise, Button-Wise & Functional System Manual for Web & Mobile
**Version:** 2.5.0 (Production Release)  
**Enterprise:** KKK Oil Factory, Tamil Nadu, India  
**System Classification:** Enterprise Resource Planning (ERP), Manufacturing Floor Operations, Statutory GST Invoicing & Supply Chain Management  
**Target Audience:** Super Admin, ERP Administrator, Plant Manager, Billing Cashier, Production Supervisor, Logistics Supervisor & Driver, Warehouse Incharge  
**Supported Platforms:** Web Browser (Chrome/Edge/Safari/Firefox), Mobile App (Android APK & iOS)

---

## 1. Executive Summary & Application Overview

**KKK Oil Factory Enterprise ERP** is a high-performance industrial management and tax-compliant billing software specifically developed for commercial oil mills, seed expeller crushing plants, and distribution depots.

The platform links physical manufacturing operations—raw seed intake, moisture testing, weighbridge recording, expeller milling batches, oil settling, bulk silo tank dip monitoring, and packaged SKU inventory—with commercial business functions including statutory B2B GST invoicing (HSN 1508/1515/2306), high-speed retail POS counter checkout, customer credit ledgers, multi-tier pricing, and logistics fleet dispatch.

### Supported Platforms & Responsive Layout Engine
- **Web & Desktop Workspace (Screen Width ≥ 860px)**:
  - **Left Application Drawer (244px)**: Categorized navigation (`MAIN`, `BILLING & OPERATIONS`, `MASTERS`, `PEOPLE & SETTINGS`), brand emblem, company state identifier, logged-in user card, and sign-out action.
  - **Top Application Bar**: Global search bar, Quick-action shortcuts, Active Role tone badge, Notification bell, and User profile avatar menu.
  - **Body Workspace**: Responsive data grids, statistical metric cards, tabbed billing layouts, and floating action buttons.
- **Mobile Application Workspace (Screen Width < 860px)**:
  - **Top Mobile Header**: Brand logo, screen title, hamburger drawer trigger, and role badge.
  - **Bottom Navigation Bar (5 Primary Stations)**:
    1. `Dashboard` (Index 0): Key operational metrics and quick actions.
    2. `Billing POS` (Index 1): High-speed counter sales or B2B invoicing.
    3. `Inventory` (Index 2): Bulk tank dip levels and packaged finished stock.
    4. `History` (Index 3): Invoices, reprints, and cancellations.
    5. `More Modules` (Index 4): Draggable modal sheet providing instant access to all 15 ERP modules.
  - **Force Desktop Mode**: Topbar toggle button (`Desktop View`) that allows mobile/tablet users to force full desktop layout for complex multi-column billing tables.

---

## 2. Role-Based Access Control (RBAC) Matrix

The system enforces strict operational boundaries to prevent unauthorized price alterations, financial overrides, or inventory tampering:

| Role Key | Display Name | Tone Badge | Access Scope | Operational Modules & Responsibilities |
| :--- | :--- | :---: | :---: | :--- |
| `super_admin` | **Super Admin** | Gold | `*` (Full System) | Executive command, master pricing approval, GST & Non-GST station toggles, employee administration, financial audit, and database backups. |
| `admin` | **ERP Administrator** | Gold | 15 Core Modules | Master catalog configuration, employee account creation, customer credit limits, inventory adjustments, and company profile. |
| `manager` | **Plant / Shift Manager** | Blue | 12 Operations Modules | Day-to-day mill operations, cashier shift reconciliation, expeller yield validation, customer statements, and purchase orders. |
| `cashier` | **Billing Cashier / POS** | Green | Sales & Invoicing | High-speed POS counter billing, B2B GST tax invoices, payment collection (Cash/UPI/NEFT/Cheque/Credit), thermal receipts, and customer ledger viewing. |
| `production_staff` | **Production Supervisor** | Amber | Manufacturing Floor | Machine run logging, raw seed input (Groundnut/Sesame/Mustard), filtered oil recovery tracking, oil cake byproduct bagging, and machine maintenance. |
| `logistics_staff` / `driver` | **Logistics Driver** | Purple | Fleet & Dispatch | Gate pass verification, vehicle loading, driver trip sheets, delivery route execution, and Proof of Delivery (POD) mobile confirmation. |
| `inventory_incharge` | **Warehouse Head** | Forest | Inventory & Silos | Bulk tank dip stick measurements, packaged SKU counts, packing material tracking (tins/bottles/pouches), and stock transfer notes. |

---

## 3. Path-by-Path & Button-by-Button System Manual

### 3.1. Authentication & Session Gate (`/login`)
- **Route Path**: `/login`
- **Internal Route**: `login`
- **Purpose**: Authenticates personnel, securely decrypts access tokens, sets active role context, and restores last active station.
- **Visual Interface**:
  - **Desktop Layout**: Unified dark brown brand panel (`#3A1501`) featuring high-resolution gold KKK logo on the left; clean white login card on the right.
  - **Mobile Layout**: Vertical flow with gold KKK logo header, brand badge, and centered login card.
- **Input Fields**:
  1. `Username` (Text): Staff username (`admin`, `admin_staff`, `mgr`, `cashier`, `driver`).
  2. `Password` (Password): Cryptographically verified staff password.
  3. `Password Visibility Toggle` (Eye Icon): Toggles between obscured dots and readable text.
- **Action Buttons**:
  - `Sign In to ERP System` (Gold Button): Validates credentials, creates encrypted local session in `StorageService`, initializes reactive state via `AuthProvider`, and navigates to default screen.
  - `Super Admin (admin)` (Quick Demo Chip): Instantly populates credentials for Super Admin.
  - `ERP Admin (admin_staff)` (Quick Demo Chip): Instantly populates credentials for Administrator.
  - `Manager (mgr)` (Quick Demo Chip): Instantly populates credentials for Operations Manager.
  - `Cashier (cashier)` (Quick Demo Chip): Instantly populates credentials for Billing Cashier.

---

### 3.2. Executive & Operations Dashboard (`/dashboard`)
- **Route Path**: `/dashboard` or `/`
- **Internal Route**: `dashboard`
- **Purpose**: Real-time enterprise cockpit providing top-level KPI metrics, active manufacturing alerts, sales trends, and immediate shortcuts.
- **Key Metrics Displayed**:
  - `Today's Gross Sales` (₹): Real-time sum of all completed tax invoices and counter sales.
  - `Cash Register Balance` (₹): Net physical cash collected across all billing counters.
  - `Active Silo Tank Dip Levels` (Liters): Calibrated volume of bulk oil in main storage tanks.
  - `Low Stock SKU Alerts`: Number of finished products below safety reorder threshold.
- **Quick Action Buttons**:
  - `+ New B2B Invoice`: Navigates immediately to `/billing` (`erp_billing`).
  - `+ Quick POS Counter`: Navigates immediately to `/counter`.
  - `+ Start Milling Batch`: Opens batch creation modal or navigates to `/production`.
  - `+ Record Seed Inward`: Opens purchase intake modal or navigates to `/purchase`.
  - `+ Delivery Gate Pass`: Navigates to `/logistics`.
- **Interactive Data Components**:
  - `7-Day Sales Trend Bar Chart`: Visual comparison of daily revenue over the preceding week.
  - `Recent Vouchers Table`: Lists the 10 most recent invoices with Voucher No, Customer Name, Net Value, Payment Status badge, and `View Details` action.
  - `Critical Inventory Alert Grid`: Highlights SKUs requiring immediate production replenishment.

---

### 3.3. Standard B2B GST Invoicing (`/billing`)
- **Route Path**: `/billing` (Aliases: `/gst-billing`, `/erp-billing`)
- **Internal Route**: `erp_billing`
- **Purpose**: Generates statutory GST Tax Invoices compliant with Rule 46 of CGST Rules 2017 for wholesale dealers, distributors, supermarkets, and institutions.
- **Header Form Controls**:
  1. `Customer Selector` (Dropdown / Search): Displays registered customers with company legal name, GSTIN, and credit balance.
  2. `Billing Route` (Dropdown): Delivery route (e.g., Dharmapuri Local, Salem Highway, Coimbatore Express).
  3. `Godown Selector` (Dropdown): Source warehouse (`Main Godown`, `Packaging Godown`, `Mill Floor`).
  4. `Pricing Tier` (Radio Buttons):
     - `Retail Rate` (Single carton / standard rate)
     - `Semi-Wholesale Rate` (Medium volume discount)
     - `Bulk Wholesale Rate` (Large dealer distributor tier)
  5. `Payment Mode` (Dropdown): `Cash`, `Credit / Account`, `UPI / QR`, `Bank Transfer / NEFT`, `Cheque`.
  6. `Payment Status` (Dropdown): `Paid`, `Partial`, `Credit (Unpaid)`.
- **Fast Line Item Entry Form**:
  1. `Item Search Autocomplete` (Text Field): Real-time product search by name, SKU, or HSN code.
  2. `Quantity` (Numeric Field): Number of units / packs to bill.
  3. `Applied Unit Rate` (Numeric Field): Auto-filled from selected price tier; editable with admin permissions.
  4. `Discount %` (Numeric Field): Line item discount percentage (e.g. 2.5%).
  5. `Add to Voucher` (Gold Button): Appends item to active invoice table with automated tax calculation.
- **Invoice Items Data Table**:
  - Columns: S.No, Item Code, Product Name, Pack Volume, Quantity, Applied Rate, Discount Amt, Taxable Base, CGST %, SGST %, IGST %, Final Line Total, Actions.
  - Row Actions:
    - `+` (Increment Qty): Increases item count by 1.
    - `-` (Decrement Qty): Decreases item count by 1.
    - `Trash Icon` (Delete Line Item): Removes product from invoice table.
- **Bottom Multi-Tab Panel**:
  - **Tab 0: Dispatch Details**:
    - `PO Number` & `PO Date`: Buyer's purchase order reference.
    - `Vehicle Number`: Transport truck registration (e.g., `TN 28 BK 5521`).
    - `Driver Name`: Authorized vehicle driver.
    - `Delivery Note` & `Gate Pass No`: Internal dispatch tracking identifiers.
    - `Transporter Name`: Logistics agency.
  - **Tab 1: E-Way Bill Details**:
    - `E-Way Bill Number`: Statutory 12-digit Government portal EWB number (required for consignments > ₹50,000).
    - `EWB Date` & `Valid Until`: Consignment validity duration based on road distance.
  - **Tab 2: E-Invoice Details**:
    - `IRN (Invoice Reference Number)`: 64-character statutory hash for B2B e-invoicing.
    - `Ack No` & `Ack Date`: Portal acknowledgement timestamp.
  - **Tab 3: Tax Ledgers & Summary**:
    - Displays Gross Line Total, Total Discount, Net Taxable Value, CGST (2.5%), SGST (2.5%), IGST (5.0%), Round-Off, and Grand Total Invoice Value.
- **Footer Action Buttons**:
  - `Save Invoice` (Primary Gold Button): Validates all fields, deducts stock from godown, posts debit to customer ledger, generates permanent voucher number (`V-2026-XXXX`), and stores record in Firestore.
  - `Print A4 Tax Invoice` (Blue Button): Generates statutory A4 PDF invoice complete with company GSTIN, FSSAI number, bank account details, and signature blocks.
  - `Print Thermal Receipt` (Green Button): Generates 80mm / 58mm ESC/POS thermal receipt.
  - `Clear Form` (Outline Button): Resets all fields to blank state for next invoice.

---

### 3.4. Billing History & Invoice Management (`/billing-history`)
- **Route Path**: `/billing-history` (Alias: `/bills`)
- **Internal Route**: `billing_history`
- **Purpose**: Complete audit ledger of all issued GST tax invoices with filtering, reprinting, and inventory-restoring cancellation.
- **Metric Cards**:
  - `Total Invoices Generated`: Total count of active vouchers.
  - `Gross Turnover`: Total monetary value of billed orders.
  - `Total Cash & Bank Collected`: Realized payments.
  - `Outstanding Credit Due`: Unpaid balances owed by credit customers.
- **Filter Controls**:
  - `Search Invoices` (Text Field): Real-time filtering by Voucher No (`V-2026-001`), Customer Name, or Date.
  - `Payment Filter Chips`: `All`, `Paid`, `Credit`, `Partial`.
- **Table / List Actions per Invoice**:
  - `Reprint A4` (Document Icon): Re-opens A4 PDF preview dialog for instant printing or PDF file download.
  - `Reprint Thermal` (Receipt Icon): Dispatches receipt print command directly to configured thermal printer.
  - `Cancel Bill` (Red Warning Button):
    - Triggers confirmation modal: *"Cancelling this voucher will restore all item quantities back to the warehouse inventory and reverse any customer credit outstanding."*
    - Requires mandatory staff cancellation reason.
    - Automatically credits back physical stock to godown and voids the customer ledger debit.

---

### 3.5. High-Velocity POS Counter Billing (`/counter`)
- **Route Path**: `/counter` (Alias: `/pos`)
- **Internal Route**: `counter`
- **Purpose**: Fast-lane retail point-of-sale for factory outlet walk-in customers purchasing individual bottles, pouches, and 15kg tins.
- **Visual Layout**:
  - **Left Section (Product Catalog Grid)**: High-visibility SKU buttons showing image/icon, product name, pack volume, price, and live stock indicator.
  - **Right Section (Active Cart & Cash Register)**: Real-time itemized cart, payment tender calculator, and instant checkout button.
- **Interactive Controls**:
  - `Oil Type Filter Chips`: Filter grid by Groundnut, Sesame, Coconut, Mustard, or All.
  - `Pricing Selector`: Switch cart rates between Retail, Semi-Wholesale, or Bulk Wholesale.
  - `One-Tap Add`: Tapping any product card instantly adds 1 unit to the cart (or increments existing qty).
  - `Cart Steppers` (`+` / `-`): Adjust unit quantity directly in the cart.
  - `Payment Method Chips`: `Cash`, `UPI QR`, `Card`, `Account Credit`.
  - `Tendered Cash Calculator`: Cashier types received amount; system instantly calculates `Change to Return` (₹).
- **Action Buttons**:
  - `Complete & Print Thermal` (Big Gold Button): Finalizes sale, updates inventory, and triggers automatic receipt cut on thermal printer.
  - `Complete & Print A4`: Completes transaction with A4 invoice output.
  - `Hold Cart`: Temporarily freezes cart to attend to next customer.
  - `Clear Cart`: Empties all cart lines.

---

### 3.6. Master Product Catalog (`/products`)
- **Route Path**: `/products`
- **Internal Route**: `products`
- **Purpose**: Master database of all manufactured oils, packaged SKUs, and oil cake byproducts with multi-tier pricing and safety stock thresholds.
- **Filter Bar**:
  - `Search Products` (Text): Filter by name, code, SKU, or HSN.
  - `Brand Dropdown`: Filter by KKK Pure, Gold Harvest, etc.
  - `Oil Type Dropdown`: Groundnut, Sesame, Coconut, Mustard, Sunflower.
  - `Rate Tier Selector`: View Agency, Wholesale, or Retail rates.
  - `Stock Filter`: `All`, `In Stock`, `Low Stock`, `Out of Stock`.
- **Header Actions**:
  - `+ Add New Product Master` (Gold Button): Opens comprehensive product creation modal.
  - `Export Master CSV` (Outline Button): Downloads complete product list as spreadsheet.
- **Add / Edit Product Modal (`_showAddEditDialog`)**:
  - **Section 1: Basic Specifications**:
    - `Product Name`: Display name (e.g. *Cold Pressed Groundnut Oil 15L Tin*).
    - `Product Code`: Unique system SKU ID (e.g. `PRD-GN-15L`).
    - `SKU / Barcode`: EAN/UPC barcode number for optical scanner.
    - `Brand`: Associated factory brand name.
    - `Oil Type`: Botanical commodity classification.
    - `Pack Volume & Unit`: e.g., 15 Liters, 1 Liter Bottle, 500ml Pouch, 50kg Bag.
  - **Section 2: Tiered Rates (AWR Architecture)**:
    - `Manufacturing Cost Price` (₹): Base cost to produce.
    - `Agency Rate` (₹): Large volume distributor price.
    - `Wholesale Rate` (₹): Regional wholesaler price.
    - `Retail Rate` (₹): Walk-in consumer price.
    - `MRP` (₹): Maximum Retail Price printed on packaging.
  - **Section 3: Inventory Thresholds & GST**:
    - `Initial Stock Count`: Physical starting units in warehouse.
    - `Minimum Alert Threshold`: Stock level triggering automatic reorder alerts.
    - `GST Rate (%)`: Statutory tax bracket (Default: 5%).
    - `HSN Code`: Harmonized System of Nomenclature (`1508` for groundnut, `1515` for sesame/others, `2306` for oil cake).
- **Row Action Buttons**:
  - `Edit Product` (Pencil Icon): Opens dialog pre-filled with current product specs.
  - `Delete Product` (Trash Icon): Opens safety verification dialog to permanently remove obsolete SKU.

---

### 3.7. Price Management & Margin Forecaster (`/price-management`)
- **Route Path**: `/price-management`
- **Internal Route**: `price_management`
- **Purpose**: Real-time commodity margin protection engine that recalculates selling price tiers based on raw seed mandi arrivals.
- **Summary Metrics**:
  - `Active Catalog SKUs`: Count of actively priced products.
  - `Average Gross Margin`: Overall mill profitability percentage.
  - `Highest Margin SKU`: Best performing retail product.
  - `Last Revision Date`: Timestamp of most recent price list update.
- **Margin Protection Calculator**:
  - Formula: `Gross Profit = Selling Rate - (Seed Purchase Cost + Milling Overhead + Packaging Cost - Cake Recovery Credit)`.
  - Calculates real-time net return per liter of oil extracted.
- **Action Buttons**:
  - `Bulk Price Adjustment` (Percentage Revision): Increases or decreases an entire product line by a set percentage (e.g., +₹5/L across all groundnut oils).
  - `Save Price Changes`: Commits updated rates to database and refreshes active billing terminals.

---

### 3.8. Historical Commodity Price Trends (`/price-history`)
- **Route Path**: `/price-history`
- **Internal Route**: `price_history`
- **Purpose**: Visual analytics tracking raw oil seed market rates (mandi auction averages) versus finished packaged oil wholesale rates over time.
- **Controls**:
  - `Time Horizon Selector`: 7 Days, 30 Days, 90 Days, 1 Year.
  - `Commodity Switcher`: Groundnut Seeds vs Refined Oil; Sesame Seeds vs Gingelly Oil.
- **Components**:
  - Trend charts depicting price divergence and margin compression.
  - Audit log table showing date, product, previous rate, new rate, and authorized staff username.

---

### 3.9. Warehouse Inventory & Tank Level Management (`/inventory`)
- **Route Path**: `/inventory` (Alias: `/stock`)
- **Internal Route**: `inventory`
- **Purpose**: Monitors bulk oil storage tanks via calibrated dip charts, tracks packaged goods stock, and manages packaging materials.
- **Bulk Storage Tanks (Visual Silo Gauges)**:
  - Displays calibrated level for:
    - Tank 1: Raw Cold-Pressed Groundnut Oil (Capacity: 25,000 L)
    - Tank 2: Sesame (Gingelly) Oil (Capacity: 15,000 L)
    - Tank 3: Coconut Pure Oil (Capacity: 10,000 L)
    - Tank 4: Filtered Polished Oil Silo (Capacity: 30,000 L)
  - Indicators: Dip stick height in centimeters (cm), computed volume in Liters (L), capacity percentage, and temperature.
- **Packaged Stock Grid**:
  - Detailed inventory counts for all finished tins, bottles, and pouches.
  - Visual status badges: `In Stock` (Green), `Low Stock` (Orange), `Depleted` (Red).
- **Action Buttons**:
  - `Adjust Physical Stock` (Button per row): Opens reconciliation modal to update physical count after physical audit count.
  - `Stock Transfer Note`: Records transfer of finished goods from factory warehouse to retail depot.
  - `Delete Item`: Removes obsolete inventory item.

---

### 3.10. Raw Seed Procurement & Mandi Inward (`/purchase`)
- **Route Path**: `/purchase` (Alias: `/inward`)
- **Internal Route**: `purchase`
- **Purpose**: Records incoming raw seed shipments from agricultural mandis, farmer groups, and brokers, including weighbridge gross/tare weights and quality checks.
- **Summary Metrics**:
  - `Total Seed Intake (kg)`: Cumulative raw material procured.
  - `Procurement Expenditure (₹)`: Total purchase value.
  - `QC Approved Volume (kg)`: Certified seed batches ready for crushing.
  - `Average Seed Rate (₹/kg)`: Weighted average intake cost.
- **Header Action Button**:
  - `+ Record Seed & Raw Material Inward` (Gold Button): Opens Goods Receipt Note (GRN) dialog.
- **Procurement Inward Dialog (`_showAddPurchaseDialog`)**:
  - `Material Name`: Groundnut Raw Pods, Sesame Seeds, Copra, Mustard Seeds, Tin Cans, HDPE Bottles.
  - `Supplier Dropdown`: Selected vendor from registered supplier master.
  - `Gross / Tare / Net Weight (kg)`: Net seed weight calculated automatically from weighbridge slip.
  - `Intake Rate (₹/kg)`: Agreed purchase rate per kilogram.
  - `Quality Control (QC) Status`:
    - `Passed (Graded)`: Seeds meet moisture and foreign matter specifications; ready for immediate crushing.
    - `Pending Lab Test`: Held in quarantine for FFA or moisture verification.
  - `Moisture Deduction (%)`: Weight deduction for excess moisture content.
- **Procurement Ledger Table**:
  - Columns: GRN ID (`PO-INW-XXXX`), Date, Supplier Firm, Material, Net Quantity (kg), Rate (₹), Total Amount (₹), QC Status badge.

---

### 3.11. Expeller Production & Milling Run Tracking (`/production`)
- **Route Path**: `/production` (Alias: `/milling`)
- **Internal Route**: `production`
- **Purpose**: Factory-floor expeller monitoring measuring raw seed crushing input against finished oil extraction, byproduct oil cake yield, and processing loss.
- **Summary Metrics**:
  - `Monthly Oil Output (Liters)`: Total filtered oil produced.
  - `Average Extraction Yield (%)`: Physical extraction efficiency.
  - `Raw Seed Crushed (kg)`: Total seed fed into expeller batteries.
  - `Active Expellers Running`: Operational machine count.
- **Header Action Button**:
  - `+ Start New Production Milling Run` (Gold Button): Launches crushing run logging dialog.
- **Production Milling Dialog (`_showAddBatchDialog`)**:
  - `Target Product`: Finished oil SKU being processed.
  - `Planned Seed Input (kg)`: Weight of seeds fed into expeller hopper.
  - `Filtered Oil Output (Liters)`: Net recovered oil pumped to settling tanks.
  - `Oil Cake Byproduct Output (kg)`: Weight of pressed cattle feed cake bagged.
  - `Processing Wastage / Moisture Loss (kg)`: Automatically computed mass balance discrepancy.
  - `Total Seed Cost (₹)`: Raw material valuation.
  - `Packaging & Consumables Cost (₹)`: Tins, labels, and cartons.
  - `Labour & Power Cost (₹)`: Factory operational overhead.
- **Extraction Yield Calculations**:
  - $	ext{Oil Extraction Yield (\%)} = \left( rac{	ext{Oil Produced (kg)}}{	ext{Seed Input (kg)}} ight) 	imes 100$
  - $	ext{Oil Cake Recovery (\%)} = \left( rac{	ext{Oil Cake Produced (kg)}}{	ext{Seed Input (kg)}} ight) 	imes 100$
  - $	ext{Processing Loss (\%)} = 100\% - (	ext{Oil Yield \%} + 	ext{Cake Yield \%})$
- **Batch Ledger Cards / Table**:
  - Shows Batch ID (`PRD-BXXXX`), Target Product, Net Output, Yield %, Date, Expiry Date, Unit Cost per Liter, and Status (`Completed`, `In Progress`).

---

### 3.12. Customer Directory & Credit Accounts (`/customers`)
- **Route Path**: `/customers`
- **Internal Route**: `customers`
- **Purpose**: Centralized customer master directory tracking retail accounts, institutional buyers, wholesale dealers, credit limits, and outstanding receivables.
- **Segment Filters**:
  - `ALL`: Complete customer list.
  - `RETAIL`: Supermarkets, local grocery shops, and walk-in accounts.
  - `DEALERS`: High-volume wholesale distributors and agency partners.
- **Header Action Button**:
  - `+ Add New Customer Account` (Gold Button): Opens customer master creation dialog.
- **Add / Edit Customer Dialog (`_showAddCustomerDialog`)**:
  - `Category Segment Toggle`: `Regular / Retail Store` vs `Dealer / Wholesaler`.
  - `Customer / Business Name`: Registered trading name.
  - `Contact Person`: Proprietor or purchasing manager name.
  - `Phone Number`: WhatsApp and SMS notification number.
  - `GSTIN`: 15-character Goods and Services Tax Identification Number (auto-validated; state code checked).
  - `Billing & Shipping Address`: Full postal delivery address.
  - `Delivery Route`: Assigned transport corridor.
  - `Credit Limit (₹)`: Maximum allowable unpaid balance before billing freeze.
  - `Default Price Tier`: Assigned price list (`RETAIL`, `WHOLESALE`, `AGENCY`).
- **Customer List Actions**:
  - `Edit Profile` (Pencil Icon): Updates customer contact details, address, or credit limits.
  - `View Statement / Ledger`: Generates chronological account statement showing invoice debits, payment credits, and current net balance.
  - `Delete Customer`: Removes inactive account (blocked if outstanding balance exists).

---

### 3.13. Supplier & Mandi Vendor Directory (`/suppliers`)
- **Route Path**: `/suppliers`
- **Internal Route**: `suppliers`
- **Purpose**: Directory of agricultural seed mandis, farmer cooperatives, tin manufacturers, bottle moulders, and label printers.
- **Summary Metrics**:
  - `Total Active Suppliers`: Count of verified vendor accounts.
  - `Outstanding Payable Balance (₹)`: Total money owed by mill to suppliers.
  - `Seed Suppliers`: Agricultural mandi vendors.
  - `Packaging Vendors`: Tin and bottle manufacturers.
- **Header Action Button**:
  - `+ Add New Supplier Vendor` (Gold Button): Opens vendor registration modal.
- **Add / Edit Supplier Dialog (`_showAddSupplierDialog`)**:
  - `Supplier Firm Name`: Legal vendor name.
  - `Materials Supplied`: Raw Seeds, 15L Tin Cans, PET Bottles, Corrugated Boxes.
  - `Contact Person` & `Phone`: Vendor contact details.
  - `GSTIN` & `Address`: Statutory registration and postal address.
  - `Opening Payable Balance (₹)`: Initial unpaid dues.
- **Supplier Directory Table**:
  - Displays firm name, material type, phone, GSTIN, and current balance due.
  - Actions: `Edit Supplier`, `Record Payment Voucher`, `Delete`.

---

### 3.14. Logistics Fleet & Dispatch Gate Passes (`/logistics`)
- **Route Path**: `/logistics` (Alias: `/dispatch`)
- **Internal Route**: `logistics`
- **Purpose**: Vehicle loading verification, delivery run-sheets, gate pass issuance, and driver Proof of Delivery (POD) confirmation.
- **Summary Metrics**:
  - `Dispatched Vehicles`: Trucks currently on delivery routes.
  - `In Transit Trips`: Active delivery runs.
  - `Pending Gate Passes`: Orders staged in loading bay.
  - `Delivered Orders`: Successfully completed deliveries.
- **Header Action Button**:
  - `+ Generate Dispatch Gate Pass` (Gold Button): Opens gate pass generation dialog.
- **Gate Pass Dialog (`_showNewDispatchDialog`)**:
  - `Vehicle Number`: Transport truck registration (e.g. `TN 28 BK 5521`).
  - `Driver Name`: Assigned staff driver.
  - `Delivery Destination / Route`: Target delivery cluster (e.g. `Kangeyam -> Coimbatore`).
  - `Linked Voucher / Bill No`: Associated B2B sales invoice number.
- **Gate Pass Tracking Table**:
  - Columns: Gate Pass ID (`DSP-XXXX`), Vehicle No, Driver, Route, Linked Bill, Trip Status stepper (`Dispatched` -> `In Transit` -> `Delivered`), Proof of Delivery (POD) toggle button.

---

### 3.15. Business Analytics & GST Compliance Reports (`/reports`)
- **Route Path**: `/reports` (Alias: `/analytics`)
- **Internal Route**: `reports`
- **Purpose**: Executive financial reporting, daily daybook cash balance audit, and pre-formatted GSTR-1 tax compliance summaries.
- **Financial Metric Cards**:
  - `Total Gross Turnover` (₹): Cumulative value of all sales orders.
  - `Net Taxable Value` (₹): Pre-tax revenue base.
  - `GST Tax Collected` (₹): Total statutory output tax collected.
- **B2B vs B2C Tax Categorization**:
  - `B2B Registered Supplies (GSTR-1 Table 4)`: Invoices issued to customers with validated GSTIN; ready for direct upload to GST portal.
  - `B2C Consumer Supplies (GSTR-1 Table 7)`: Walk-in counter retail sales without buyer GSTIN.
- **Tax Breakdown Summary**:
  - `CGST (Central Tax 2.5%)`: Half of intra-state tax liability.
  - `SGST (State Tax 2.5%)`: Half of intra-state tax liability.
  - `IGST (Integrated Tax 5.0%)`: Full inter-state tax liability for out-of-state dispatches.
- **HSN Summary Table (GSTR-1 Table 12)**:
  - Itemized summary grouped by HSN Code (`1508`, `1515`, `2306`), total quantity, taxable turnover, and tax amounts.
- **Action Buttons**:
  - `Export GSTR-1 Excel / CSV`: Generates portal-compatible spreadsheet for monthly tax filing.
  - `Download Daily Daybook PDF`: Comprehensive daily cash ledger report.

---

### 3.16. Employee Administration & Role Matrix (`/employees`)
- **Route Path**: `/employees` (Alias: `/staff`)
- **Internal Route**: `employees`
- **Purpose**: Staff credential management, role assignment, active/inactive status toggles, and fine-grained permissions configuration.
- **Tabs**:
  - **Tab 1: Staff Directory**:
    - Header Action: `+ Add New Employee` (Opens creation modal).
    - Search & Filter: Filter staff by name, username, phone, or active status (`All`, `Active`, `Inactive`).
    - Employee Cards / List: User avatar, full name, username, assigned role badge (with tone color), phone, email, and active status toggle.
    - Interactive Staff Controls:
      - `Password Reveal Eye Icon`: Allows authorized admins to reveal plain-text credentials for staff onboarding.
      - `Edit Staff Account`: Updates phone, email, or assigned role.
      - `Toggle Active / Inactive`: Instantly revokes system access for terminated employees without deleting audit records.
      - `Delete Staff`: Permanently deletes user account.
  - **Tab 2: Roles & Permissions Matrix**:
    - Comprehensive interactive matrix mapping all 15 ERP modules against all defined system roles.
    - Checkbox indicators showing exact Read, Write, and Admin capabilities for each role.

---

### 3.17. Enterprise Factory Settings (`/settings`)
- **Route Path**: `/settings`
- **Internal Route**: `settings`
- **Purpose**: Global enterprise configuration, statutory legal profile, printer hardware defaults, alert preferences, and database backup.
- **Configuration Cards**:
  - **Company Master Profile**:
    - `Trade Name`: Display name (e.g. *KKK Oil Factory*).
    - `Legal Entity Name`: Statutory business name registered on GST portal.
    - `Registered Office & Mill Address`: Official factory address printed on invoice headers.
    - `GSTIN`: 15-digit GST identification number.
    - `State & State Code`: Default state (e.g. *Tamil Nadu*, Code: `33`).
    - `FSSAI License Number`: Food Safety and Standards Authority of India manufacturing registration.
    - `Official Phone & Email`: Printed on invoice contact blocks.
    - `Banking Details`: Bank Name, Account Number, and IFSC Code for customer RTGS/NEFT payment remittances.
    - `Save Company Profile` (Gold Button): Saves profile updates across cloud and local storage.
  - **Hardware & Printer Settings**:
    - `Default Invoice Format`: Radio options for `A4 Standard Laser / Deskjet`, `80mm ESC/POS Thermal`, or `58mm Portable POS`.
    - `Auto-Print on Save`: Toggle to immediately open print dialog when an invoice is saved.
    - `Default Copies`: Number of invoice copies (e.g. Original for Buyer, Duplicate for Transporter, Triplicate for Mill).
  - **Automated System Alerts**:
    - Toggles for Low Stock Alert, Pending Payment Reminders, Pending Dispatches, Production Delays, Supplier Due Dates, and Credit Limit Breaches.
  - **Data Management & Backup**:
    - `Export Database Backup (JSON)`: Full dump of customers, products, sales, and batches.
    - `Reset Seed Data`: Factory reset option for demonstration environments.

---

## 4. Master Button & Action Reference Index

| Button Label | Screen Location | Visual Type | Action / Behavior |
| :--- | :--- | :---: | :--- |
| `Sign In to ERP System` | `/login` | Gold Elevated | Authenticates username & password, starts session, navigates to home route. |
| `+ New B2B Invoice` | `/dashboard` | Outline Icon | Fast-tracks navigation to `/billing` with fresh invoice form. |
| `+ Quick POS Counter` | `/dashboard` | Outline Icon | Opens high-speed retail checkout screen (`/counter`). |
| `+ Start Milling Batch` | `/dashboard`, `/production` | Gold Elevated | Opens production batch logging modal to record crushing run. |
| `+ Record Seed Inward` | `/dashboard`, `/purchase` | Gold Elevated | Opens weighbridge seed procurement modal to record incoming raw material. |
| `+ Add to Voucher` | `/billing` | Gold Elevated | Appends line item from item entry form into active invoice table. |
| `Save Invoice` | `/billing` | Gold Elevated | Validates form, creates sales order, deducts inventory, posts customer debit. |
| `Print A4 Tax Invoice` | `/billing`, `/billing-history` | Blue Elevated | Renders 300 DPI statutory GST tax invoice PDF with download & print controls. |
| `Print Thermal Receipt` | `/billing`, `/counter` | Green Elevated | Dispatches formatted 80mm / 58mm thermal receipt directly to receipt printer. |
| `Clear Form` | `/billing` | Outline Button | Clears all customer, dispatch, and item fields for the next transaction. |
| `Reprint A4` | `/billing-history` | Document Icon | Re-opens A4 PDF preview dialog for historical invoice. |
| `Reprint Thermal` | `/billing-history` | Receipt Icon | Sends historical invoice to thermal printer. |
| `Cancel Bill` | `/billing-history` | Red Warning | Prompts for cancellation reason, restores stock to godown, reverses ledger debit. |
| `Complete & Print Thermal`| `/counter` | Gold Large | Finalizes POS transaction, records payment, cuts thermal receipt. |
| `Hold Cart` | `/counter` | Outline Button | Temporarily parks active customer cart in local memory. |
| `+ Add New Product Master`| `/products` | Gold Elevated | Opens modal dialog to define new SKU, tier rates, and stock thresholds. |
| `Export Master CSV` | `/products` | Outline Button | Generates and downloads spreadsheet file containing all active products. |
| `Save Stock` | `/inventory` | Primary Elevated| Commits audited physical stock count into inventory master. |
| `Save Inward Entry` | `/purchase` | Gold Elevated | Saves incoming raw seed batch, records supplier payable, updates QC ledger. |
| `Record Milling Run` | `/production` | Gold Elevated | Saves crushing batch, calculates yield %, adds finished oil to silo tank. |
| `+ Add Customer Account` | `/customers` | Gold Elevated | Registers new customer profile with credit limit, GSTIN, and price tier. |
| `+ Add Supplier Vendor` | `/suppliers` | Gold Elevated | Registers new vendor profile with materials, contact info, and payable balance.|
| `Issue Gate Pass` | `/logistics` | Gold Elevated | Links vehicle, driver, and sales invoice to generate formal dispatch gate pass.|
| `+ Add New Employee` | `/employees` | Gold Elevated | Creates new staff user account with username, password, and assigned role. |
| `Save Company Profile` | `/settings` | Gold Elevated | Updates legal business name, address, GSTIN, FSSAI, and bank details. |

---

## 5. End-to-End Standard Operating Procedures (SOPs)

### SOP 1: Cashier Day-Start & POS Counter Billing
1. **Morning Sign-In**: Open browser or mobile app, navigate to `/login`, enter cashier credentials (`cashier`), and click `Sign In`.
2. **Access POS Screen**: The system automatically directs cashier to `/counter`. Verify cash drawer opening balance.
3. **Serving Walk-in Customers**:
   - Tap product icons (e.g. *1L Groundnut Oil Bottle*, *500ml Sesame Pouch*) to add items to cart.
   - Adjust quantities using `+` and `-` stepper buttons.
   - If customer purchases 5+ tins, switch price tier chip to `Semi-Wholesale Rate`.
   - Ask for payment method: Tap `Cash` or `UPI QR`.
   - If cash, enter amount tendered into `Cash Received` field; verify displayed `Change to Return`.
   - Click `Complete & Print Thermal`. Hand printed receipt and packaged oil to customer.
4. **Shift Closing**: Navigate to `/billing-history`, filter by today's date and cashier name, verify physical cash against `Total Cash Collected`, and submit day-end cash bag to Manager.

### SOP 2: B2B Wholesale Tax Invoice with Delivery Dispatch
1. **Initiate Invoice**: Navigate to `/billing` (`erp_billing`).
2. **Select Customer**: Choose buyer from `Customer Selector` dropdown. Verify displayed credit limit and available balance.
3. **Verify Route & Godown**: Confirm dispatch godown (`Main Godown`) and destination route.
4. **Set Pricing Tier**: Select `Bulk Wholesale Rate` or `Semi-Wholesale Rate`.
5. **Add Line Items**:
   - In `Item Search`, type product code (e.g. `PRD-GN-15L`).
   - Enter quantity (e.g., `50` tins).
   - Verify rate and discount % (if negotiated).
   - Click `+ Add to Voucher`. Confirm taxable value and CGST/SGST (or IGST for out-of-state buyers) in items table.
6. **Enter Dispatch Details**:
   - Click `Bottom Tab 0 (Dispatch Details)`.
   - Enter Vehicle Number (`TN 28 BK 5521`), Driver Name, and Buyer PO reference.
   - If total order exceeds ₹50,000, click `Tab 1 (E-Way Bill)` and input Government portal EWB number.
7. **Save & Print**:
   - Click `Save Invoice`. System records order, deducts 50 tins from inventory, and updates customer credit ledger.
   - Click `Print A4 Tax Invoice`. Print duplicate copies (Original for Buyer, Transporter Copy).
   - Hand documents to loading supervisor.

### SOP 3: Raw Seed Inward & Weighbridge Intake
1. **Truck Arrival**: Loaded truck arrives from agricultural mandi with raw groundnut pods.
2. **Weighbridge Weighing**: Driver weighs loaded truck on mill weighbridge (Gross Weight).
3. **Quarantine Inspection**: Factory QC technician takes 5 grab samples from bags to measure moisture percentage and kernel damage.
4. **Record Inward in ERP**:
   - Navigate to `/purchase`. Click `+ Record Seed & Raw Material Inward`.
   - Select supplier from dropdown.
   - Enter material: `Groundnut Raw Pods`.
   - Enter net seed weight (Gross - Tare weight from weighbridge slip).
   - Enter agreed mandi rate per kg (₹).
   - Set QC Status: Select `Passed (Graded)` if moisture is ≤ 8%; select `Pending Lab Test` if excess moisture requires yard drying.
   - Click `Save Inward Entry`. System logs Goods Receipt Note (GRN) and credits supplier payable account.

### SOP 4: Expeller Milling Run & Yield Calculation
1. **Feed Preparation**: Production supervisor allocates 5,000 kg of graded groundnut seeds from seed godown to expeller battery #1.
2. **Crushing Run**: Machine operators run expellers, extracting raw crude oil through filter presses into settling tanks, and bagging pressed oil cake.
3. **Record Milling Run in ERP**:
   - Navigate to `/production`. Click `+ Start New Production Milling Run`.
   - Select Target Product: `Cold Pressed Groundnut Oil (Bulk)`.
   - Planned Seed Input: Enter `5000` kg.
   - Filtered Oil Output: Enter measured tank volume (e.g., `2150` Liters / `1978` kg).
   - Oil Cake Output: Enter total bagged cattle feed cake (e.g., `2850` kg).
   - Wastage: System calculates moisture/sediment loss (`172` kg / 3.44%).
   - Total Seed Cost: Enter total raw procurement cost.
   - Click `Record Milling Run`.
4. **System Verification**: System checks that Extraction Yield matches benchmark (40% - 43% for groundnut) and updates bulk silo tank volume in `/inventory`.

---

## 6. Mobile Application User Guide

The KKK Oil ERP mobile application provides complete operational freedom for factory floor managers, delivery drivers, and counter billers on Android tablets and smartphones.

### Mobile Navigation Controls
- **Bottom Navigation Bar**:
  - `Dashboard`: View real-time factory metrics and active alerts on the go.
  - `Billing POS`: Immediate mobile counter billing with touch-optimized product buttons.
  - `Inventory`: Walk through warehouse aisles and enter physical stock counts directly.
  - `History`: Check recent dispatches, search past orders, and reprint thermal slips.
  - `More Modules`: Tap the three-dot icon to open a swipeable bottom sheet providing instant access to Products, Production, Purchases, Customers, Suppliers, Reports, and Settings.
- **Force Desktop Mode**:
  - When accessing complex multi-column billing tables on a tablet, tap the `Desktop View` toggle in the top app bar to display the full multi-panel desktop layout without scrolling restrictions.
- **Bluetooth Thermal Printing**:
  - Connect portable 58mm / 80mm Bluetooth thermal printers. Receipts can be printed directly from the loading bay or delivery truck.
- **Digital Proof of Delivery (POD)**:
  - In `/logistics`, drivers can tap `POD Received` upon delivery at the customer store to confirm physical receipt of goods in real time.

---

## 7. Troubleshooting & Frequently Asked Questions (FAQ)

### Q1: Why is an invoice blocked from saving?
**Answer**: Check the following:
1. Ensure a customer is selected.
2. Ensure at least one line item is added to the voucher table.
3. If payment status is set to `Credit`, verify that the order value does not cause the customer's outstanding balance to exceed their defined `Credit Limit`.

### Q2: How does intra-state vs. inter-state GST calculate automatically?
**Answer**: The system inspects the first 2 digits of the customer's GSTIN against the mill's state code (Tamil Nadu: `33`). If the customer GSTIN begins with `33`, intra-state tax applies (CGST 2.5% + SGST 2.5% = 5%). If the customer GSTIN begins with any other state code (e.g. `29` for Karnataka, `32` for Kerala), inter-state tax applies (IGST 5.0%).

### Q3: What happens when an invoice is cancelled?
**Answer**: In `/billing-history`, clicking `Cancel Bill` requires entering a staff reason. Upon confirmation, the ERP:
1. Restores the exact product quantities back to the source godown.
2. Reverses the debit in the customer's credit ledger.
3. Marks the voucher as `Cancelled` in audit reports while preserving the voucher number for sequential GST audit compliance.

### Q4: How do I change product rates during commodity price surges?
**Answer**: Super Admins and Admins can navigate to `/price-management`, select the target product line, enter the updated rates for Retail, Wholesale, or Agency tiers, and click `Save Price Changes`. All billing terminals immediately reflect the new prices.

---
*© 2026 KKK Oil Factory. All rights reserved. Enterprise Internal Operational Manual.*
