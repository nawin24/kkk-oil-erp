# KKK Oil Factory — Dedicated Non-GST Billing Station Manual

<p align="center"><img src="screenshots/kkk_logo_gold.png" alt="KKK Oil Factory Logo" width="320"></p>

## Operational Guide for Non-Tax Regional Trade, Mandi Cash Settlements & Private Godown Stock
**Version:** 2.5.0 (Dedicated Station Release)  
**Enterprise:** KKK Oil Factory, Tamil Nadu, India  
**Station Classification:** Non-Tax Commercial Trade, Farmer Mandi Settlement, Private Warehouse Stock & Unbranded Loose Oil Sales  
**Target Personnel:** Super Admin (`super_admin`), Super Admin Non-GST (`super_admin_nongst`), Designated Non-Tax Billing Operators  
**Supported Platforms:** Web Browser (Clean URL: `/nongst-billing`, `/nongst-history`, `/nongst-counter`), Mobile Tablet & Android Handheld App

---

## 1. Station Executive Overview & Legal Boundaries

The **Dedicated Non-GST Billing Station** is an isolated operational subsystem within the KKK Oil Factory Enterprise ERP. It is engineered specifically to handle commercial transactions that fall outside statutory GST tax reporting under Indian agricultural and mandi commerce regulations.

### Foundational Purpose of the Non-GST Station
1. **Direct Farm-Gate Seed Procurement**: Indian agricultural law exempts small, unregistered farmers selling raw agricultural produce (raw groundnut pods, sesame seeds, copra, mustard seeds) directly at the farm gate or village collection centers from GST registration. The Non-GST station provides accurate weight and cash settlement tracking without generating statutory tax invoices.
2. **Unbranded Loose Oil Counter Sales**: Traditional regional oil mills supply unbranded cold-pressed oil in customer-provided containers, tins, or bulk cans. These sales require instant cash memos and stock reduction without mandatory buyer GSTIN registration.
3. **Private Godown & Unprocessed Stock Segregation**: Factory processing often involves lots held in private godowns before formal cleaning, de-stoning, and commercial grading. The Non-GST station tracks physical stocks in these private godowns independently from statutory tax-audited inventory.
4. **Strict Audit Firewall**: To guarantee that statutory GST returns (GSTR-1, GSTR-3B) submitted to the Government are 100% compliant and uncontaminated, the Non-GST station maintains an absolute data barrier. All transactions generated in this station are assigned unique `NG-` prefixed voucher numbers, calculate tax strictly at **0.0%**, and are completely excluded from statutory tax ledgers.

---

## 2. Station Access Control & Visual Identity

To eliminate any possibility of staff confusion or accidental cross-billing between tax and non-tax transactions, the Non-GST station enforces distinct visual branding and strict role gating:

### Access Authorization (RBAC)
- **Authorized Roles**: Accessible **only** by `super_admin` and `super_admin_nongst`.
- **Unauthorized Roles**: Standard cashiers, logistics staff, and general factory supervisors cannot open or operate the Non-GST station.
- **Session Guard**: The ERP's routing engine immediately redirects unauthorized staff attempts to access `/nongst-billing` back to standard `/billing` or `/dashboard`.

### Distinct Visual Theme
- **Color Palette**: Deep warm amber and rich chocolate brown (`#B45309`, `#92400E`, `#3A1501`).
- **Sidebar Drawer**: Features a deep charcoal background (`#121815`) with amber active gradients and a dedicated `NON-GST BILLING STATION` navigation group.
- **On-Screen Alert Banners**: Every Non-GST screen displays a persistent amber notification banner:
  > **NON-GST BILLING STATION NOTICE**: All tax rates are locked to 0.0%. Vouchers are prefixed with `NG-` and segregated from statutory GST registers. Deductions apply exclusively to private godowns.
- **Document Watermarking**: Generated printouts are prominently titled **DELIVERY VOUCHER / CASH MEMO / ESTIMATE** and do not display tax brackets, statutory tax invoice declarations, or CGST/SGST ledger tables.

---

## 3. Dedicated Non-GST Paths, Screens & Buttons

### 3.1. Non-GST Billing Voucher Screen (`/nongst-billing`)
- **Route Path**: `/nongst-billing` (Aliases: `/non-gst-billing`, `/nongst_billing`)
- **Internal Route**: `nongst_billing`
- **Forced Parameter**: `forcedBillingType: 'NON_GST'`
- **Purpose**: Generates non-tax commercial delivery vouchers, mandi farmer settlements, and unbranded cash sales.

#### Header Form Controls
1. `Customer Selector` (Dropdown / Search): Displays buyers registered in the customer directory. Shows their dedicated **Non-GST Outstanding Balance** (completely separate from their statutory GST balance).
2. `Billing Route` (Dropdown): Target distribution route (e.g., *Dharmapuri Local*, *Salem Highway*, *Namakkal Mandi*).
3. `Godown Selector` (Dropdown): Defaults to `Private Godown` (or `Local Mandi Yard`). Ensures stock deductions do not affect statutory tax-audited inventory in `Main Godown`.
4. `Pricing Tier` (Radio Buttons):
   - `Retail Rate` (Counter price)
   - `Semi-Wholesale Rate` (Medium volume discount)
   - `Bulk Wholesale Rate` (Large volume commodity rate)
5. `Payment Mode` (Dropdown): `Cash`, `Credit / Account`, `UPI / QR`.
6. `Payment Status` (Dropdown): `Paid`, `Partial`, `Credit (Unpaid)`.

#### Fast Line Item Entry Form
1. `Item Search Autocomplete` (Text Field): Real-time product search by code or name.
2. `Quantity` (Numeric Field): Units or kilograms to bill.
3. `Applied Unit Rate` (Numeric Field): Rate per unit (₹). Auto-fills from selected pricing tier; editable by Super Admin.
4. `Discount %` (Numeric Field): Percentage discount (if applicable).
5. `Add to Voucher` (Amber Button): Inserts product into voucher table.

#### Non-Tax Line Items Table
- **Columns**: S.No, Product Code, Product Name, Unit/Pack, Qty, Applied Rate, Discount Amt, Net Taxable Base, GST Rate, GST Amount, Final Line Total, Actions.
- **Strict 0.0% GST Engine**:
  - $	ext{Gross Line Total} = 	ext{Qty} 	imes 	ext{Rate}$
  - $	ext{Discount Amount} = 	ext{Gross} 	imes \left(rac{	ext{Disc \%}}{100}
ight)$
  - $	ext{Net Amount} = 	ext{Gross} - 	ext{Discount Amount}$
  - $	ext{GST Rate} \equiv 0.0\%$ (Locked)
  - $	ext{GST Amount} \equiv ₹0.00$ (Locked)
  - $	ext{Final Line Total} = 	ext{Net Amount}$
- **Row Actions**:
  - `+` (Increment Qty): Increases item count by 1.
  - `-` (Decrement Qty): Decreases item count by 1.
  - `Trash Icon`: Removes item from voucher table.

#### Dispatch & Transport Details (Bottom Tab)
- `PO / Memo Number`: Internal reference or farmer weighment slip number.
- `Vehicle Number`: Delivery truck or tractor registration (e.g. `TN 28 BK 5521`).
- `Driver Name`: Transport driver name.
- `Delivery Note`: Internal transit instructions.
- *Note: Statutory E-Way Bill and E-Invoice tabs are automatically suppressed and disabled in Non-GST mode.*

#### Action Buttons
- `Save Voucher` (Primary Amber Button):
  - Validates voucher inputs.
  - Generates unique voucher number prefixed with `NG-` (e.g. `NG-2026-0001`).
  - Deducts physical item quantities from `Private Godown` stock.
  - Posts debit entry to customer's Non-GST credit ledger.
  - Saves record to Firestore database under non-GST partition.
- `Print A4 Delivery Voucher` (Blue Button):
  - Renders formal A4 delivery voucher / estimate PDF.
  - Excludes customer GSTIN, tax brackets, and statutory declaration text.
  - Displays company header, itemized quantities, net total, and signature line.
- `Print Thermal Receipt` (Green Button):
  - Dispatches 80mm / 58mm ESC/POS receipt to thermal printer for immediate handover to customer or driver.
- `Clear Form` (Outline Button):
  - Clears all form fields for the next transaction.

---

### 3.2. Non-GST Billing History & Cancellation (`/nongst-history`)
- **Route Path**: `/nongst-history` (Aliases: `/non-gst-history`, `/nongst_history`)
- **Internal Route**: `nongst_history`
- **Forced Parameter**: `forcedBillingType: 'NON_GST'`
- **Purpose**: Dedicated audit repository containing all issued Non-GST vouchers with search, reprint, and stock-restoring cancellation.

#### Summary Metric Cards
- `Total Non-GST Vouchers`: Total count of active `NG-` vouchers.
- `Non-Tax Turnover (₹)`: Cumulative monetary value of non-tax sales.
- `Cash Collections (₹)`: Realized cash receipts from non-tax trade.
- `Outstanding Non-GST Credit (₹)`: Unpaid balances owed on non-tax accounts.

#### Filter & Search Controls
- `Search Vouchers` (Text Field): Real-time search by voucher number (e.g. `NG-2026-001`), customer name, or date.
- `Payment Status Filter Chips`: `All`, `Paid`, `Credit`, `Partial`.

#### Table Actions per Voucher Row
- `Reprint A4` (Document Icon): Re-opens A4 delivery voucher PDF preview for re-printing or digital sharing.
- `Reprint Thermal` (Receipt Icon): Dispatches receipt copy directly to thermal printer.
- `Cancel Voucher` (Red Warning Button):
  - Opens cancellation modal: *"Cancelling this voucher will restore all item quantities back to the warehouse inventory and reverse any customer credit outstanding."*
  - Requires mandatory cancellation reason.
  - **Instantly restores quantities back to Private Godown inventory**.
  - **Reverses the debit in the customer's Non-GST ledger balance**.
  - Marks voucher as `Cancelled` in non-tax audit records.

---

### 3.3. High-Speed Non-GST Retail POS Counter (`/nongst-counter`)
- **Route Path**: `/nongst-counter`
- **Internal Route**: `nongst_counter`
- **Billing Type**: `NON_GST`
- **Purpose**: Fast-lane cash counter for retail walk-in customers buying loose or unbranded oil without statutory tax invoicing.

#### Features & Controls
- **One-Tap Product Grid**: Quick SKU buttons filtered by oil type.
- **Zero-Tax POS Cart**: Automatically applies 0.0% GST rate to all added items.
- **Cash Tendered Calculator**: Cashier enters received cash; system calculates change to return.
- **Instant Print**: Generates compact thermal cash receipt without tax breakdown.

---

## 4. Dual Customer Ledger & Credit Architecture

To maintain strict accounting integrity and prevent statutory audit complications, the KKK Oil ERP enforces a **Dual Ledger System** for all customer accounts:

```
                            +-------------------------------+
                            |       Customer Account        |
                            | (e.g., Sri Murugan Stores)    |
                            +---------------+---------------+
                                            |
                    +-----------------------+-----------------------+
                    |                                               |
        +-----------v-----------+                       +-----------v-----------+
        |  Statutory GST Ledger |                       |  Private Non-GST      |
        |      (Official)       |                       |       Ledger          |
        +-----------+-----------+                       +-----------+-----------+
        | • Invoices: V-2026-XX |                       | • Vouchers: NG-2026-XX|
        | • Statutory Tax (5%)  |                       | • Zero Tax (0.0%)     |
        | • Official Bank RTGS  |                       | • Cash & Local Mandi  |
        | • Exported to GSTR-1  |                       | • Internal Audit Only |
        +-----------------------+                       +-----------------------+
```

### Ledger Separation Rules
1. **No Cross-Settlement**: A cash payment received against a Non-GST voucher (`NG-`) cannot be credited against a statutory GST tax invoice (`V-`).
2. **Distinct Balance Tracking**: The customer directory shows two separate columns:
   - `GST Statutory Balance (₹)`: Reported in company audited financials.
   - `Non-GST Outstanding (₹)`: Managed exclusively on the Non-GST station.
3. **Credit Limit Enforcement**: Each ledger maintains independent credit thresholds to prevent financial exposure.

---

## 5. Private Godown & Inventory Separation

Physical inventory is strictly segregated between statutory tax-audited stock and private operational stock:

| Godown Identifier | Designation | Applicable Station | Audited in GSTR-1? |
| :--- | :--- | :---: | :---: |
| `Main Godown` | Statutory Warehouse | `/billing`, `/counter` | **Yes** (Formal Stock Register) |
| `Packaging Godown` | Finished Packaged SKUs | `/billing`, `/counter` | **Yes** (Tax Valuation) |
| `Private Godown` | Unbranded / Mandi Stock | `/nongst-billing`, `/nongst-counter` | **No** (Internal Factory Floor) |
| `Local Mandi Yard` | Raw Uncleaned Seed Intake | `/nongst-billing` | **No** (Pre-Processing Holding) |

### Inventory Deduction Logic
- When saving an invoice at `/billing`: Stock is deducted **only** from `Main Godown`.
- When saving a voucher at `/nongst-billing`: Stock is deducted **only** from `Private Godown`.
- When cancelling a voucher at `/nongst-history`: Restored quantities return **only** to `Private Godown`.

---

## 6. Step-by-Step Non-GST Operating Procedures

### SOP 1: Issuing a Non-GST Commercial Delivery Voucher
1. **Access Station**: Log in as `admin` (Super Admin). In the left sidebar, locate the amber section labeled `NON-GST BILLING STATION` and click `Non-GST Billing Voucher` (or navigate directly to `/nongst-billing`).
2. **Verify Banner**: Ensure the amber alert banner is visible at the top: *"NON-GST BILLING STATION — All tax rates are locked to 0.0%..."*
3. **Select Buyer**: Choose buyer from `Customer Selector`. Verify their current Non-GST balance.
4. **Select Godown**: Ensure `Godown` is set to `Private Godown`.
5. **Add Items**:
   - In `Item Search`, enter product name (e.g. *Cold Pressed Groundnut Oil 15L Tin*).
   - Enter quantity (e.g., `20` tins).
   - Verify rate per unit (e.g., ₹2,850).
   - Click `+ Add to Voucher`. Confirm in the items table that GST % is `0.0%` and GST Amount is `₹0.00`.
6. **Enter Transport Details**:
   - Click bottom tab `Dispatch Details`.
   - Enter vehicle number and driver name for transit verification.
7. **Save & Print**:
   - Click `Save Voucher`. System generates permanent voucher ID `NG-2026-XXXX`, deducts 20 tins from Private Godown, and records customer debit.
   - Click `Print A4 Delivery Voucher`. Hand printed delivery memo to driver.

### SOP 2: Reconciling & Reprinting Past Non-GST Vouchers
1. Navigate to `/nongst-history`.
2. Locate voucher using the search box (enter `NG-2026-0042` or customer name).
3. Review status badge (`Paid`, `Credit`, `Partial`).
4. Click `Reprint A4` to view and re-download the formal delivery memo, or click `Reprint Thermal` to emit a thermal POS copy.

### SOP 3: Cancelling a Non-GST Voucher (Order Cancellation / Mistake)
1. In `/nongst-history`, locate the voucher to cancel.
2. Click the red `Cancel Voucher` button on the voucher row.
3. In the dialog, review the warning: *"Cancelling this voucher will restore all item quantities back to the warehouse inventory and reverse any customer credit outstanding."*
4. Enter mandatory staff cancellation reason (e.g., *Customer cancelled delivery before loading*).
5. Click `Confirm Cancellation`.
6. System immediately credits stock back to `Private Godown` and removes debit from customer's Non-GST account.

---

## 7. Mobile App Non-GST Workflows

The KKK Oil ERP mobile application provides complete operational agility for field managers and mandi purchasing agents on Android tablets and smartphones:

### Mobile Navigation
- When authenticated as Super Admin, the mobile app's bottom navigation `Billing` icon switches directly to the Non-GST station if Non-GST mode is active.
- Tapping `More Modules` (three dots) displays the amber-highlighted `Non-GST Billing Voucher` and `Non-GST History` shortcuts.
- Responsive layout provides full touch-screen product selection and steppers.

### Portable Bluetooth Receipt Printing
- Mandi agents can pair handheld 58mm Bluetooth thermal printers to issue immediate printed delivery receipts to farmers or transport drivers in rural yards.

---

## 8. Audit Compliance & Statutory Safeguards

### Mandatory Compliance Rules
1. **Never Mix Invoice Books**: Official statutory GST tax invoices must always be created at `/billing` with `V-` prefixes. Non-tax transactions must always be created at `/nongst-billing` with `NG-` prefixes.
2. **Statutory GSTR-1 Exclusion**: The system's tax export engine at `/reports` automatically filters for `billingType == 'GST'`. Non-GST vouchers (`NG-`) are **never** exported to Government tax portals.
3. **Daily Cash Balancing**: Cash collected at `/nongst-billing` and `/nongst-counter` must be reconciled in a separate physical cash register box from official statutory billing cash.
4. **Periodic Stock Audits**: Physical audits of `Private Godown` must be conducted separately from `Main Godown` stock counts.

---
*© 2026 KKK Oil Factory. All rights reserved. Dedicated Non-GST Operational Manual.*
