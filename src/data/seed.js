// ============================================================
// KKK Oil Factory ERP — Seed / Sample Data
// All money in INR. Dates ISO. This mirrors the SQL seed.
// ============================================================

export const ROLES = {
  admin:        { label: 'Admin / Owner',     access: '*' },
  factory:      { label: 'Factory Manager',   access: ['dashboard','production','inventory','logistics','products','reports'] },
  production:   { label: 'Production Manager', access: ['dashboard','production','inventory','reports'] },
  sales:        { label: 'Sales Team',         access: ['dashboard','sales','customers','billing','reports'] },
  inventory:    { label: 'Inventory Manager',  access: ['dashboard','inventory','products','brands','reports'] },
  purchase:     { label: 'Purchase Manager',   access: ['dashboard','purchase','suppliers','inventory','reports'] },
  logistics:    { label: 'Logistics / Dispatch',access: ['dashboard','logistics','sales','reports'] },
  accountant:   { label: 'Accountant',         access: ['dashboard','billing','sales','purchase','reports'] },
}

export const USERS = [
  { id: 'U1', name: 'Karuppasamy K', role: 'admin',     email: 'owner@kkkoil.in',     phone: '+91 98430 11111' },
  { id: 'U2', name: 'Murugan S',     role: 'factory',    email: 'factory@kkkoil.in',   phone: '+91 98430 22222' },
  { id: 'U3', name: 'Prakash R',     role: 'production', email: 'prod@kkkoil.in',      phone: '+91 98430 33333' },
  { id: 'U4', name: 'Anitha M',      role: 'sales',      email: 'sales@kkkoil.in',     phone: '+91 98430 44444' },
  { id: 'U5', name: 'Vignesh T',     role: 'inventory',  email: 'stock@kkkoil.in',     phone: '+91 98430 55555' },
  { id: 'U6', name: 'Selvam P',      role: 'purchase',   email: 'purchase@kkkoil.in',  phone: '+91 98430 66666' },
  { id: 'U7', name: 'Ramesh K',      role: 'logistics',  email: 'dispatch@kkkoil.in',  phone: '+91 98430 77777' },
  { id: 'U8', name: 'Lakshmi V',     role: 'accountant', email: 'accounts@kkkoil.in',  phone: '+91 98430 88888' },
]

export const BRANDS = [
  { id: 'B1', name: 'KKK Gold',        type: 'Own Brand',        color: '#e3a92e', contact: 'KKK Oils, Dharmapuri', phone: '+91 98430 11111', gstin: '33ABCKK1234F1Z5' },
  { id: 'B2', name: 'Anjali Oils',     type: 'Third-party Brand',color: '#2563eb', contact: 'Anjali Foods, Salem',  phone: '+91 90000 22222', gstin: '33ANJAL5678G1Z2' },
  { id: 'B3', name: 'Sakthi Pure',     type: 'Third-party Brand',color: '#1f8a5b', contact: 'Sakthi Agro, Erode',   phone: '+91 90000 33333', gstin: '33SAKTH9012H1Z9' },
  { id: 'B4', name: 'Annai Naturals',  type: 'Third-party Brand',color: '#7c3aed', contact: 'Annai Trading, Hosur', phone: '+91 90000 44444', gstin: '33ANNAI3456J1Z1' },
]

export const OIL_TYPES = ['Groundnut Oil','Gingelly Oil','Coconut Oil','Sunflower Oil','Palm Oil','Castor Oil']
export const PACK_SIZES = ['500 ml','1 L','2 L','5 L','15 L Tin','15 kg Tin','Barrel']
export const UNIT_TYPES = ['Bottle','Tin','Can','Barrel','Carton']

// 20 products
export const PRODUCTS = [
  { id:'P01', brandId:'B1', name:'KKK Gold Groundnut Oil 1L',   oilType:'Groundnut Oil', pack:'1 L',     unit:'Bottle', sku:'KKK-GN-1L',  hsn:'1508', gst:5,  cost:165, price:198, mrp:215, minStock:200, stock:540 },
  { id:'P02', brandId:'B1', name:'KKK Gold Groundnut Oil 5L',   oilType:'Groundnut Oil', pack:'5 L',     unit:'Can',    sku:'KKK-GN-5L',  hsn:'1508', gst:5,  cost:790, price:945, mrp:999, minStock:80,  stock:120 },
  { id:'P03', brandId:'B1', name:'KKK Gold Gingelly Oil 1L',    oilType:'Gingelly Oil',  pack:'1 L',     unit:'Bottle', sku:'KKK-GL-1L',  hsn:'1515', gst:5,  cost:230, price:275, mrp:299, minStock:150, stock:310 },
  { id:'P04', brandId:'B1', name:'KKK Gold Gingelly Oil 500ml', oilType:'Gingelly Oil',  pack:'500 ml',  unit:'Bottle', sku:'KKK-GL-500', hsn:'1515', gst:5,  cost:120, price:145, mrp:159, minStock:200, stock:95  },
  { id:'P05', brandId:'B1', name:'KKK Gold Coconut Oil 1L',     oilType:'Coconut Oil',   pack:'1 L',     unit:'Bottle', sku:'KKK-CN-1L',  hsn:'1513', gst:5,  cost:190, price:228, mrp:245, minStock:150, stock:402 },
  { id:'P06', brandId:'B1', name:'KKK Gold Coconut Oil 5L Tin', oilType:'Coconut Oil',   pack:'5 L',     unit:'Tin',    sku:'KKK-CN-5L',  hsn:'1513', gst:5,  cost:920, price:1100,mrp:1150,minStock:60,  stock:48  },
  { id:'P07', brandId:'B1', name:'KKK Gold Sunflower Oil 1L',   oilType:'Sunflower Oil', pack:'1 L',     unit:'Bottle', sku:'KKK-SF-1L',  hsn:'1512', gst:5,  cost:128, price:152, mrp:165, minStock:250, stock:680 },
  { id:'P08', brandId:'B1', name:'KKK Gold Sunflower Oil 15L',  oilType:'Sunflower Oil', pack:'15 L Tin',unit:'Tin',    sku:'KKK-SF-15L', hsn:'1512', gst:5,  cost:1850,price:2190,mrp:2299,minStock:40,  stock:72  },
  { id:'P09', brandId:'B2', name:'Anjali Groundnut Oil 1L',     oilType:'Groundnut Oil', pack:'1 L',     unit:'Bottle', sku:'ANJ-GN-1L',  hsn:'1508', gst:5,  cost:170, price:205, mrp:220, minStock:120, stock:260 },
  { id:'P10', brandId:'B2', name:'Anjali Sunflower Oil 1L',     oilType:'Sunflower Oil', pack:'1 L',     unit:'Bottle', sku:'ANJ-SF-1L',  hsn:'1512', gst:5,  cost:130, price:158, mrp:170, minStock:150, stock:88  },
  { id:'P11', brandId:'B2', name:'Anjali Palm Oil 15L Tin',     oilType:'Palm Oil',      pack:'15 L Tin',unit:'Tin',    sku:'ANJ-PL-15L', hsn:'1511', gst:5,  cost:1450,price:1690,mrp:1750,minStock:50,  stock:130 },
  { id:'P12', brandId:'B3', name:'Sakthi Pure Gingelly 1L',     oilType:'Gingelly Oil',  pack:'1 L',     unit:'Bottle', sku:'SAK-GL-1L',  hsn:'1515', gst:5,  cost:235, price:282, mrp:305, minStock:100, stock:175 },
  { id:'P13', brandId:'B3', name:'Sakthi Pure Coconut 500ml',   oilType:'Coconut Oil',   pack:'500 ml',  unit:'Bottle', sku:'SAK-CN-500', hsn:'1513', gst:5,  cost:98,  price:122, mrp:135, minStock:200, stock:240 },
  { id:'P14', brandId:'B3', name:'Sakthi Pure Groundnut 2L',    oilType:'Groundnut Oil', pack:'2 L',     unit:'Can',    sku:'SAK-GN-2L',  hsn:'1508', gst:5,  cost:330, price:392, mrp:415, minStock:90,  stock:64  },
  { id:'P15', brandId:'B3', name:'Sakthi Pure Sunflower 5L',    oilType:'Sunflower Oil', pack:'5 L',     unit:'Can',    sku:'SAK-SF-5L',  hsn:'1512', gst:5,  cost:640, price:760, mrp:799, minStock:70,  stock:150 },
  { id:'P16', brandId:'B4', name:'Annai Coconut Oil 1L',        oilType:'Coconut Oil',   pack:'1 L',     unit:'Bottle', sku:'ANN-CN-1L',  hsn:'1513', gst:5,  cost:195, price:235, mrp:255, minStock:120, stock:210 },
  { id:'P17', brandId:'B4', name:'Annai Palm Oil Barrel',       oilType:'Palm Oil',      pack:'Barrel',  unit:'Barrel', sku:'ANN-PL-BRL', hsn:'1511', gst:5,  cost:14500,price:16800,mrp:17500,minStock:8, stock:14 },
  { id:'P18', brandId:'B4', name:'Annai Castor Oil 1L',         oilType:'Castor Oil',    pack:'1 L',     unit:'Bottle', sku:'ANN-CS-1L',  hsn:'1515', gst:12, cost:175, price:215, mrp:235, minStock:80,  stock:36  },
  { id:'P19', brandId:'B1', name:'KKK Gold Groundnut 15kg Tin', oilType:'Groundnut Oil', pack:'15 kg Tin',unit:'Tin',   sku:'KKK-GN-15K', hsn:'1508', gst:5,  cost:2350,price:2780,mrp:2899,minStock:30,  stock:54  },
  { id:'P20', brandId:'B1', name:'KKK Gold Coconut 15kg Tin',   oilType:'Coconut Oil',   pack:'15 kg Tin',unit:'Tin',    sku:'KKK-CN-15K', hsn:'1513', gst:5,  cost:2700,price:3180,mrp:3299,minStock:25,  stock:18 },
]

export const GODOWNS = ['Main Godown','Dispatch Yard','Cold Store']

export const RAW_MATERIALS = [
  { id:'R1', name:'Groundnut Seeds',  unit:'kg',    stock:8400,  minStock:3000, cost:95,  godown:'Main Godown' },
  { id:'R2', name:'Sesame / Gingelly Seeds', unit:'kg', stock:2100, minStock:1500, cost:165, godown:'Main Godown' },
  { id:'R3', name:'Copra (Coconut)',  unit:'kg',    stock:5200,  minStock:2000, cost:140, godown:'Main Godown' },
  { id:'R4', name:'Crude Sunflower Oil', unit:'L',  stock:1200,  minStock:2500, cost:118, godown:'Cold Store' },
  { id:'R5', name:'1L PET Bottles',   unit:'pcs',   stock:14000, minStock:8000, cost:7,   godown:'Main Godown' },
  { id:'R6', name:'5L Cans',          unit:'pcs',   stock:1800,  minStock:1000, cost:28,  godown:'Main Godown' },
  { id:'R7', name:'15L Tins',         unit:'pcs',   stock:640,   minStock:500,  cost:62,  godown:'Main Godown' },
  { id:'R8', name:'Brand Labels',     unit:'pcs',   stock:42000, minStock:20000,cost:0.8, godown:'Main Godown' },
  { id:'R9', name:'Carton Boxes',     unit:'pcs',   stock:3200,  minStock:2000, cost:14,  godown:'Main Godown' },
]

export const SUPPLIERS = [
  { id:'S1', name:'Annamalai Agro Traders', material:'Groundnut Seeds', contact:'Annamalai',  phone:'+91 94431 10001', gstin:'33ANNAM1111A1Z5', address:'Pennagaram, Dharmapuri', rating:4.6, due:142000 },
  { id:'S2', name:'Kongu Sesame Mills',     material:'Sesame Seeds',    contact:'Periyasamy', phone:'+91 94431 10002', gstin:'33KONGU2222B1Z3', address:'Erode',               rating:4.2, due:0 },
  { id:'S3', name:'Coastal Copra Supplies', material:'Copra',           contact:'Mathew',     phone:'+91 94431 10003', gstin:'33COAST3333C1Z8', address:'Pollachi',            rating:4.8, due:88000 },
  { id:'S4', name:'SVM Packaging Co',       material:'Bottles & Cans',  contact:'Vimal',      phone:'+91 94431 10004', gstin:'33SVMPK4444D1Z1', address:'Hosur',               rating:4.0, due:31500 },
  { id:'S5', name:'Bharath Crude Oils',     material:'Crude Sunflower', contact:'Bharath',    phone:'+91 94431 10005', gstin:'33BHRTH5555E1Z6', address:'Krishnagiri',         rating:3.9, due:215000 },
]

export const CUSTOMERS = [
  { id:'C01', name:'Sri Balaji Stores',        type:'Dealer',      contact:'Balaji',   phone:'+91 99940 20001', gstin:'33BALAJ0001K1Z2', area:'Dharmapuri Town', route:'R1', creditLimit:300000, outstanding:184500, brandPref:'KKK Gold' },
  { id:'C02', name:'Annapoorna Super Market',  type:'Distributor', contact:'Senthil',  phone:'+91 99940 20002', gstin:'33ANNAP0002L1Z9', area:'Hosur',           route:'R2', creditLimit:500000, outstanding:262000, brandPref:'KKK Gold' },
  { id:'C03', name:'Murugan Provisions',       type:'Retail',      contact:'Murugan',  phone:'+91 99940 20003', gstin:'',                area:'Pennagaram',      route:'R1', creditLimit:80000,  outstanding:14200,  brandPref:'Sakthi Pure' },
  { id:'C04', name:'Sakthi Wholesale Mart',    type:'Wholesale',   contact:'Karthik',  phone:'+91 99940 20004', gstin:'33SAKWM0004M1Z5', area:'Krishnagiri',     route:'R3', creditLimit:600000, outstanding:0,      brandPref:'Anjali Oils' },
  { id:'C05', name:'Lakshmi Departmental',     type:'Retail',      contact:'Lakshmi',  phone:'+91 99940 20005', gstin:'',                area:'Harur',           route:'R4', creditLimit:100000, outstanding:48900,  brandPref:'KKK Gold' },
  { id:'C06', name:'Jaya Traders',             type:'Distributor', contact:'Jayaraman',phone:'+91 99940 20006', gstin:'33JAYAT0006N1Z1', area:'Salem',           route:'R5', creditLimit:450000, outstanding:331000, brandPref:'KKK Gold' },
  { id:'C07', name:'Vijay Stores',             type:'Dealer',      contact:'Vijay',    phone:'+91 99940 20007', gstin:'33VIJAY0007P1Z7', area:'Dharmapuri Town', route:'R1', creditLimit:250000, outstanding:96000,  brandPref:'Annai Naturals' },
  { id:'C08', name:'Green Valley Foods',       type:'Wholesale',   contact:'Suresh',   phone:'+91 99940 20008', gstin:'33GREEN0008Q1Z3', area:'Bangalore',       route:'R6', creditLimit:800000, outstanding:512000, brandPref:'KKK Gold' },
  { id:'C09', name:'Amman Provision Store',    type:'Retail',      contact:'Devi',     phone:'+91 99940 20009', gstin:'',                area:'Palacode',        route:'R4', creditLimit:60000,  outstanding:8500,   brandPref:'Sakthi Pure' },
  { id:'C10', name:'Royal Distributors',       type:'Distributor', contact:'Imran',    phone:'+91 99940 20010', gstin:'33ROYAL0010R1Z9', area:'Hosur',           route:'R2', creditLimit:700000, outstanding:0,      brandPref:'KKK Gold' },
]

export const PURCHASES = [
  { id:'PO-2401', supplierId:'S1', date:'2026-05-28', material:'Groundnut Seeds', qty:4000, unit:'kg', rate:95, gst:5, qc:'Passed',  payStatus:'Partial', inward:true },
  { id:'PO-2402', supplierId:'S3', date:'2026-06-01', material:'Copra',           qty:3000, unit:'kg', rate:140,gst:5, qc:'Passed',  payStatus:'Paid',    inward:true },
  { id:'PO-2403', supplierId:'S5', date:'2026-06-03', material:'Crude Sunflower', qty:2000, unit:'L',  rate:118,gst:5, qc:'Pending', payStatus:'Unpaid',  inward:false },
  { id:'PO-2404', supplierId:'S4', date:'2026-06-05', material:'1L PET Bottles',  qty:10000,unit:'pcs',rate:7,  gst:18,qc:'Passed',  payStatus:'Partial', inward:true },
  { id:'PO-2405', supplierId:'S2', date:'2026-06-07', material:'Sesame Seeds',    qty:1500, unit:'kg', rate:165,gst:5, qc:'Passed',  payStatus:'Paid',    inward:true },
  { id:'PO-2406', supplierId:'S1', date:'2026-06-09', material:'Groundnut Seeds', qty:2500, unit:'kg', rate:96, gst:5, qc:'Pending', payStatus:'Unpaid',  inward:false },
]

export const PRODUCTION = [
  { id:'BATCH-501', productId:'P01', plannedQty:600, outputQty:540, wastage:18, status:'Completed',   startDate:'2026-05-30', mfgDate:'2026-06-01', expDate:'2027-06-01', rawCost:89100,  packCost:6480,  labourCost:4200 },
  { id:'BATCH-502', productId:'P05', plannedQty:420, outputQty:402, wastage:9,  status:'Completed',   startDate:'2026-06-02', mfgDate:'2026-06-03', expDate:'2027-06-03', rawCost:76380,  packCost:4824,  labourCost:3600 },
  { id:'BATCH-503', productId:'P07', plannedQty:700, outputQty:680, wastage:12, status:'Completed',   startDate:'2026-06-04', mfgDate:'2026-06-05', expDate:'2027-06-05', rawCost:87040,  packCost:8160,  labourCost:4900 },
  { id:'BATCH-504', productId:'P03', plannedQty:350, outputQty:0,   wastage:0,  status:'In Progress', startDate:'2026-06-10', mfgDate:'', expDate:'', rawCost:0, packCost:0, labourCost:0 },
  { id:'BATCH-505', productId:'P19', plannedQty:80,  outputQty:0,   wastage:0,  status:'Planned',     startDate:'2026-06-13', mfgDate:'', expDate:'', rawCost:0, packCost:0, labourCost:0 },
]

export const SALES = [
  { id:'SO-3001', customerId:'C01', date:'2026-06-10', salesperson:'Anitha M', dispatch:'Delivered',        payStatus:'Paid',    items:[{productId:'P01',qty:120,rate:198},{productId:'P05',qty:40,rate:228}] },
  { id:'SO-3002', customerId:'C02', date:'2026-06-10', salesperson:'Anitha M', dispatch:'In Transit',       payStatus:'Pending', items:[{productId:'P07',qty:200,rate:152},{productId:'P08',qty:15,rate:2190}] },
  { id:'SO-3003', customerId:'C06', date:'2026-06-09', salesperson:'Anitha M', dispatch:'Loaded',           payStatus:'Pending', items:[{productId:'P01',qty:150,rate:198},{productId:'P03',qty:60,rate:275}] },
  { id:'SO-3004', customerId:'C08', date:'2026-06-09', salesperson:'Anitha M', dispatch:'Ready for Dispatch',payStatus:'Pending',items:[{productId:'P02',qty:30,rate:945},{productId:'P19',qty:20,rate:2780}] },
  { id:'SO-3005', customerId:'C04', date:'2026-06-08', salesperson:'Anitha M', dispatch:'Delivered',        payStatus:'Paid',    items:[{productId:'P09',qty:100,rate:205},{productId:'P11',qty:25,rate:1690}] },
  { id:'SO-3006', customerId:'C07', date:'2026-06-08', salesperson:'Anitha M', dispatch:'Packing Pending',  payStatus:'Pending', items:[{productId:'P16',qty:80,rate:235},{productId:'P18',qty:30,rate:215}] },
  { id:'SO-3007', customerId:'C03', date:'2026-06-07', salesperson:'Anitha M', dispatch:'Delivered',        payStatus:'Paid',    items:[{productId:'P12',qty:40,rate:282},{productId:'P13',qty:60,rate:122}] },
  { id:'SO-3008', customerId:'C05', date:'2026-06-07', salesperson:'Anitha M', dispatch:'Delivered',        payStatus:'Partial', items:[{productId:'P03',qty:50,rate:275},{productId:'P05',qty:30,rate:228}] },
  { id:'SO-3009', customerId:'C10', date:'2026-06-06', salesperson:'Anitha M', dispatch:'Order Received',   payStatus:'Pending', items:[{productId:'P07',qty:300,rate:152}] },
  { id:'SO-3010', customerId:'C02', date:'2026-06-05', salesperson:'Anitha M', dispatch:'Returned',         payStatus:'Pending', items:[{productId:'P15',qty:40,rate:760}] },
]

export const DISPATCHES = [
  { id:'DSP-9001', soId:'SO-3001', vehicle:'TN-29-AB-1234', driver:'Kumar',    route:'R1 — Town',       status:'Delivered',         transport:1200, pod:true },
  { id:'DSP-9002', soId:'SO-3002', vehicle:'TN-29-BC-5678', driver:'Ravi',     route:'R2 — Hosur',      status:'In Transit',        transport:3500, pod:false },
  { id:'DSP-9003', soId:'SO-3003', vehicle:'TN-29-CD-9012', driver:'Saravanan',route:'R5 — Salem',      status:'Loaded',            transport:2800, pod:false },
  { id:'DSP-9004', soId:'SO-3004', vehicle:'TN-29-DE-3456', driver:'Mani',     route:'R6 — Bangalore',  status:'Ready for Dispatch',transport:5200, pod:false },
  { id:'DSP-9005', soId:'SO-3005', vehicle:'TN-29-EF-7890', driver:'Kumar',    route:'R3 — Krishnagiri',status:'Delivered',         transport:2100, pod:true },
]

export const EXPENSES = [
  { id:'EXP-1', date:'2026-06-09', head:'Transport',  note:'Diesel + driver bata', amount:18400 },
  { id:'EXP-2', date:'2026-06-08', head:'Labour',     note:'Packing line weekly wages', amount:42000 },
  { id:'EXP-3', date:'2026-06-07', head:'Electricity',note:'Factory EB bill', amount:31500 },
  { id:'EXP-4', date:'2026-06-06', head:'Maintenance',note:'Expeller servicing', amount:9800 },
  { id:'EXP-5', date:'2026-06-05', head:'Misc',       note:'Office + stationery', amount:4200 },
]

// Notifications are derived at runtime in DataContext, but a few static ones:
export const STATIC_ACTIVITY = [
  { id:'A1', type:'sale',     text:'Sales order <b>SO-3001</b> delivered to Sri Balaji Stores', time:'10 min ago', icon:'sale' },
  { id:'A2', type:'prod',     text:'Batch <b>BATCH-503</b> completed — 680 units of Sunflower 1L', time:'1 hour ago', icon:'prod' },
  { id:'A3', type:'purchase', text:'Purchase <b>PO-2406</b> raised to Annamalai Agro Traders', time:'3 hours ago', icon:'purchase' },
  { id:'A4', type:'dispatch', text:'Vehicle <b>TN-29-BC-5678</b> dispatched to Hosur route', time:'4 hours ago', icon:'dispatch' },
  { id:'A5', type:'payment',  text:'Payment ₹1,84,500 received from Sri Balaji Stores', time:'Yesterday', icon:'payment' },
]
