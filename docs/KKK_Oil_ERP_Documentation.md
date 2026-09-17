# KKK Oil Factory — Enterprise ERP & Billing System
## Complete System Architecture, Operations Manual & Technical Specification
**Version:** 2.4.0 (Production Release)  
**Enterprise:** KKK Oil Factory, Tamil Nadu, India  
**System Classification:** Multi-Platform Enterprise Resource Planning, Manufacturing Operations, GST Billing & Supply Chain Management  
**Supported Platforms:** Web (Chrome/Edge/Safari/Firefox), Android (APK & App Bundle), iOS (Xcode Workspace), Desktop (macOS/Windows)

---

## Executive Summary

**KKK Oil Factory Enterprise ERP** is a mission-critical, end-to-end industrial software suite specifically engineered for edible oil manufacturing mills, seed expeller processing plants, and commercial wholesale/retail distributors. 

The software bridges factory-floor physical operations (seed intake, cleaning, expeller crushing runs, oil settling, filtration, and bulk tank dips) with executive business functions (statutory GST invoicing, quick-counter point-of-sale, customer credit ledgers, procurement APMC tracking, price-margin forecasting, and multi-vehicle dispatch logistics).

### Core Differentiators
1. **Dual Billing Architecture**: Unified point-of-sale counter billing alongside B2B GST tax-invoicing with integrated HSN (1515/2306) tax calculation and optional dedicated Non-GST operational stations.
2. **Manufacturing & Expeller Yield Tracking**: Real-time crushing calculations measuring input seed quintals against filtered oil recovery percentage, oil cake byproduct yield, and processing moisture loss.
3. **Dynamic Commodity Pricing Engine**: Real-time tracking of raw oil seed mandi price fluctuations vs. finished oil retail and wholesale price lists.
4. **Resilient Offline-First Sync**: Local state caching with automatic cloud synchronization via Google Cloud Firestore and secure session persistence.
5. **Role-Based Fine-Grained Security (RBAC)**: Strict separation of privileges across Executive Super Admins, Plant Managers, Billing Cashiers, Factory Floor Supervisors, and Logistics Drivers.

---

## System Architecture & Technical Stack

```
                                +-----------------------------------+
                                |    Client Layer (Flutter 3.x)     |
                                |  Web | Android APK | iOS | macOS  |
                                +-----------------+-----------------+
                                                  |
                        +-------------------------+-------------------------+
                        |                                                   |
              +---------v---------+                               +---------v---------+
              |   AuthProvider    |                               |   DataProvider    |
              | Session / RBAC    |                               | Reactive State    |
              +---------+---------+                               +---------+---------+
                        |                                                   |
                        +-------------------------+-------------------------+
                                                  |
                                        +---------v---------+
                                        |  StorageService   |
                                        | (SharedPreferences|
                                        |   Offline Cache)  |
                                        +---------+---------+
                                                  |
                                        +---------v---------+
                                        |  FirebaseService  |
                                        | (Cloud Firestore) |
                                        +-------------------+
```

### Technical Specification
- **Frontend Architecture**: Flutter 3.x / Dart 3.12+ reactive layered architecture (UI Widgets -> State Providers -> Business Logic Models -> Storage & Cloud Services).
- **State Management**: Reactive `ChangeNotifierProvider` model via `package:provider` (`AuthProvider` and `DataProvider`).
- **Database & Sync Engine**: Google Cloud Firestore utilizing server timestamps, distributed indexes, and automated offline caching.
- **Session Persistence**: `StorageService` using encrypted local key-value stores (`SharedPreferences`) preserving authorization tokens, active roles, and company settings across hard reloads and URL routing changes.
- **Document & PDF Generation**: `package:pdf` and `package:printing` generating dual-format industrial documents (Standard 300 DPI A4 Invoices and 80mm / 58mm Thermal ESC/POS receipts).
- **URL Routing Strategy**: HTML5 Clean Path routing (`PathUrlStrategy`) eliminating hash-bang URLs on web deployments (`/dashboard`, `/billing`, `/products`, `/inventory`, `/production`, `/reports`, `/settings`).

---

## User Roles & Access Control Matrix (RBAC)

The system enforces a hierarchical role structure with strict operational boundaries:

| Role Key | Display Name | Access Scope | Operational Responsibilities |
| :--- | :--- | :---: | :--- |
| `super_admin` | **Super Admin** | `*` (Full System) | Master executive oversight, financial auditing, company master configuration, GST & Non-GST station toggles, employee administration, and database export. |
| `super_admin_nongst` | **Super Admin (Non-GST)** | `*` (Dedicated Non-GST) | Independent executive station for non-tax regional trade, local mandi procurement, and dedicated private warehouse batches. |
| `admin` | **ERP Administrator** | 15 Core Modules | Master data catalog, product lines, retail/wholesale pricing tiers, factory operations, inventory adjustments, and company settings. |
| `manager` | **Plant / Shift Manager** | 12 Operations Modules | Cashier shift reconciliation, sales order approval, batch yield validation, customer credit extension, and production reports. |
| `cashier` | **Billing Cashier** | Counter & Sales | Fast-paced POS counter sales, B2B billing, payment collection (Cash, UPI, NEFT, Cheque, Credit), thermal invoice printing. |
| `inventory_incharge` | **Warehouse Head** | Inventory & Stock | Bulk tank dip measurements, packaged SKU counts, packing material tracking (tins/bottles/pouches), stock transfer notes. |
| `production_supervisor`| **Expeller Supervisor** | Production Floor | Machine run logging, raw seed feeding (Groundnut, Sesame, Mustard), oil extraction yield monitoring, cake byproduct bagging. |
| `driver` | **Logistics Driver** | Logistics & Dispatch | Delivery run-sheets, trip status updates, dispatch notes, customer sign-off, vehicle fuel and mileage logging. |

---

## Complete Functional Modules Walkthrough

### 1. POS Counter Sales (Quick Counter Billing)
- **High-Velocity Checkout**: Designed for rapid retail counter throughput with single-tap product selection and barcode scanner integration.
- **Flexible Payment Methods**: Cash (with auto change calculator), UPI QR code prompt, Debit/Credit Card, Bank Transfer, and Account Credit.
- **Instant Print**: Generates ESC/POS thermal receipts with itemized tax summaries and store branding.

### 2. Enterprise B2B GST Invoicing
- **Statutory Tax Calculations**: Automatically determines intra-state (CGST 2.5% + SGST 2.5% = 5%) vs. inter-state (IGST 5%) based on customer's 2-digit GST state code (Default: 33 for Tamil Nadu).
- **HSN & SAC Code Enforcement**: Automatically assigns HSN `1515` for refined/cold-pressed edible oils and HSN `2306` for oil cake byproducts.
- **Credit Limits & Balances**: Displays customer outstanding balance, available credit limit, and payment terms directly on the billing interface.
- **Thermal & A4 Invoice PDF**: Generates formal tax invoices compliant with Rule 46 of CGST Rules, complete with QR code, authorized signatory line, bank details, and terms of sale.

### 3. Production & Oil Crushing Run Tracking
- **Batch Processing**: Logs raw seed input batches with moisture percentage, foreign matter deduction, and expeller unit ID.
- **Yield Calculation Engine**:
  - Oil Extraction Yield (%) = `(Filtered Oil Produced (kg) / Seed Input (kg)) * 100`
  - Oil Cake Byproduct Yield (%) = `(Oil Cake Produced (kg) / Seed Input (kg)) * 100`
  - Processing Loss (%) = `100% - (Oil Yield % + Cake Yield %)`
- **Quality Inspection**: Logs initial acid value (FFA), color index, and sedimentation density before pumping to final storage silos.

### 4. Inventory & Tank Level Management
- **Bulk Silos & Tanks**: Daily dip-chart calibrated measurements for bulk crude oil tanks and polished oil storage tanks.
- **Packaged Finished SKUs**: Tracks 15 kg Tins, 15 Litre Tins, 5 Litre Cans, 1 Litre PET Bottles, and 500ml Pouches with automatic batch expiry and MRP tagging.
- **Packaging Material Inventory**: Monitors empty tin cans, HDPE bottles, corrugated shipper cartons, caps, and pre-printed labels.
- **Automated Reorder Alerts**: Visual indicators and notifications when any SKU drops below minimum safety stock levels.

### 5. Dynamic Pricing & Margin Management
- **Live Mandi Seed Tracking**: Tracks historical procurement costs per quintal across key agricultural mandis.
- **Tiered Price Engine**:
  - Counter Retail Rate (Single unit walk-in price)
  - Semi-Wholesale Rate (5 to 49 units)
  - Bulk Wholesale Rate (50+ units / Dealer pricing)
- **Margin Protection Calculator**: Computes gross profit margins per liter considering current raw seed costs and oil cake recovery offset.

### 6. Procurement & Vendor Management
- **Farmer & Mandi Purchasing**: Records gross vehicle weight, tare weight, net seed weight, bag counts, moisture deductions, and APMC market committee cess.
- **Supplier Ledger**: Comprehensive credit/debit transaction history, purchase orders, goods receipt notes (GRN), and payable aging schedules.

### 7. Customer Relationship & Credit Ledger
- **Customer Profiles**: Stores GSTIN, legal business name, billing address, dispatch destination, credit limit, and payment terms (e.g., Net 15, Net 30).
- **Ledger Statement**: Exports chronological customer statements with invoice debits, payment receipts, and balance summaries.

### 8. Logistics & Dispatch Tracking
- **Trip Scheduling**: Links sales invoices to vehicle registration, driver details, and delivery route.
- **E-Way Bill Integration**: Records 12-digit E-Way Bill numbers and validity dates for consignments exceeding statutory thresholds (Rs. 50,000).
- **Status Lifecycle**: `Pending` -> `Loaded` -> `In Transit` -> `Delivered` with digital proof of delivery.

### 9. Business Analytics & Financial Reports
- **Daily Daybook**: Summarizes cash collections, bank deposits, credit sales, and vendor disbursements.
- **GST Compliance Reports**: Pre-formatted GSTR-1 summaries categorized by B2B supplies (Table 4), B2C large/small (Table 5/7), and HSN summary (Table 12).
- **Stock Valuation**: Real-time inventory valuation based on weighted average cost methods.

### 10. System Administration & Factory Settings
- **Enterprise Profile**: Configuration of company legal name, trade name, registered address, GSTIN, FSSAI manufacturing license number, bank account details (IFSC, Account Number), and custom invoice terms.
- **Hardware Integration**: Default printer selection (A4 Laser vs. 80mm ESC/POS thermal printer), paper roll margin adjustments, and barcode scanner preferences.

---

## Deployment & Production Build Guide

### 1. Web Deployment (Firebase Hosting)
```bash
# Clean and fetch dependencies
flutter clean
flutter pub get

# Compile optimized CanvasKit production web build
flutter build web --release --web-renderer canvaskit

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### 2. Android APK & App Bundle
```bash
# Build standalone universal APK for direct plant tablet installation
flutter build apk --release

# Build Google Play App Bundle (AAB) for private internal distribution
flutter build appbundle --release
```
*Generated APK location:* `build/app/outputs/flutter-apk/app-release.apk`

### 3. iOS Xcode Build
```bash
# Ensure CocoaPods dependencies are installed
cd ios && pod install && cd ..

# Build iOS release bundle
flutter build ios --release
```

---

## Standard Operating Procedures (SOPs) & FAQs

### Daily Opening Procedure (Cashier / Plant Shift)
1. Launch app and sign in using designated staff credentials.
2. Verify system date, company profile, and active pricing tiers.
3. Check thermal printer paper roll and verify connection via a test print.
4. Review opening cash balance on the Counter POS screen.

### Shift Closing & Reconciliation
1. Navigate to **Reports -> Daybook**.
2. Compare physical cash drawer count with system cash sales total.
3. Reconcile UPI digital settlements against bank merchant statement.
4. Super Admin or Manager approves closing shift summary.

### Troubleshooting Network Drops
- The application automatically buffers transactions locally when internet connectivity drops.
- A yellow sync indicator will appear on the top navigation bar.
- Transactions automatically synchronize to Cloud Firestore once connection is restored. Do not force close the app while offline transactions are pending sync.
