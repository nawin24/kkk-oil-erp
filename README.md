# kkk-oil-erp

A Horizon-ERP–style management system for KKK Oil Factory (Dharmapuri) — purchase,
production, inventory, sales, billing, logistics, GST reports and role-based access.
Built with **React + TypeScript + Vite** and a **Firebase** (Firestore + Auth) backend.

## Getting started

```bash
npm install
npm run dev
```

Open http://localhost:5173. **Sign in with `admin` / `admin123`** (a default owner account created
on first run). Then head to **Settings** to set your company details, add your own staff logins, and
either keep the sample data or **Start fresh (empty)** to enter your own products, customers and bills.

### Daily billing — the Counter
**Billing Counter** (in the sidebar) is the fast POS screen: search a product, click to add it, adjust
quantity, pick a payment mode (Cash / UPI / Card / Credit), then **Save** or **Save & Print**. Each bill
is a GST sales invoice — it reduces finished-goods stock, and credit bills raise the customer's
outstanding. **Save & Print** produces an A4 GST tax invoice with your company header (CGST/SGST or IGST,
amount in words) ready for paper or *Save as PDF*.

Data is saved permanently in your browser (localStorage). Connect Firebase (below) for a shared,
multi-device backend.

## Connecting Firebase (real backend)

The app runs in two modes automatically:

- **Demo mode** (default) — data is stored in your browser's localStorage.
- **Live mode** — when Firebase credentials are present, all data reads/writes go to Cloud Firestore.

To switch to live mode:

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Firestore Database** and **Authentication → Email/Password**.
3. In Project settings → Your apps, register a Web app and copy the config values.
4. Copy `.env.example` to `.env` and fill in the `VITE_FIREBASE_*` values.
5. Deploy the Firestore security rules: `firebase deploy --only firestore:rules`
   (see [`firestore.rules`](firestore.rules) — any signed-in user can read/write the ERP collections).
6. Restart `npm run dev`. Open **Settings → Data & Firebase → Seed Firestore with sample data**
   to populate your Firestore collections.

Once connected, everything written in the app — including invoices created in **Billing → New
Invoice** — write-throughs to Cloud Firestore automatically.

Firestore collections used: `brands`, `products`, `rawMaterials`, `suppliers`, `purchases`,
`production`, `customers`, `sales`, `dispatches`, `expenses`.

## Modules

Dashboard, Brands, Products, Purchase, Inventory, Production, Sales, Logistics,
Billing (GST invoicing — create invoices & print/Save-as-PDF tax invoices), Customers,
Suppliers, Reports & GST, and Settings — with role-based access
(Admin, Factory Manager, Production, Sales, Inventory, Purchase, Logistics, Accountant).

## Project structure

```
src/
  firebase/config.ts      Firebase init + demo/live mode detection
  context/AuthContext.tsx Role-based session & permissions
  context/DataContext.tsx Data layer (seed/localStorage ↔ Firestore) + analytics
  data/seed.ts            Sample dataset
  types.ts                Domain types
  components/             Layout, Sidebar, Topbar, Icon, Charts, shared UI
  pages/                  One file per module
  utils/helpers.ts        ₹ / date / GST helpers
```

## Scripts

- `npm run dev` — start the dev server
- `npm run build` — typecheck (`tsc --noEmit`) + production build
- `npm run preview` — preview the production build
- `npm run typecheck` — TypeScript check only

## Notes

This project was migrated from a JavaScript build to TypeScript + Firebase. Any leftover
legacy `.jsx`/`.js` files from the old build are unused (Vite is configured to prefer the
`.tsx`/`.ts` sources) and can be safely deleted.
