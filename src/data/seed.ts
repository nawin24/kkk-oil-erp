import type { Product, SalesOrder } from '../types'

// ============================================================
// KKK Oil Factory ERP — Seed / Sample Data
// All money in INR. Dates ISO. This mirrors the SQL seed.
// ============================================================

export const ROLES = {
  super_admin:        { label: 'Super Admin (GST)',       access: '*' },
  super_admin_nongst: { label: 'Super Admin (Non-GST)',   access: '*' },
  admin:              { label: 'Admin / Owner',           access: ['dashboard','products','price_management','price_history','inventory','customers','suppliers','purchase','production','sales','logistics','billing','reports','settings'] },
  manager:            { label: 'Manager',                 access: ['dashboard','products','price_history','inventory','customers','suppliers','purchase','production','sales','logistics','billing','reports'] },
  cashier:            { label: 'Cashier',                 access: ['billing','inventory','customers'] },
}

export const USERS = [
  { id: 'U1', name: 'Super Administrator', role: 'super_admin', email: 'superadmin@kkkoil.in', phone: '+91 98430 11111' },
  { id: 'U2', name: 'Karuppasamy K',        role: 'admin',       email: 'admin@kkkoil.in',      phone: '+91 98430 22222' },
  { id: 'U3', name: 'Prakash R (Manager)',   role: 'manager',     email: 'manager@kkkoil.in',    phone: '+91 98430 33333' },
  { id: 'U4', name: 'Anitha M (Cashier)',    role: 'cashier',     email: 'cashier@kkkoil.in',    phone: '+91 98430 44444' },
]

export const BRANDS = [
  { id: 'B1', name: 'KKK Gold',        type: 'Own Brand',        color: '#e3a92e', contact: 'KKK Oils, Dharmapuri', phone: '+91 98430 11111', gstin: '33ABCKK1234F1Z5' },
  { id: 'B2', name: 'Anjali Oils',     type: 'Third-party Brand',color: '#2563eb', contact: 'Anjali Foods, Salem',  phone: '+91 90000 22222', gstin: '33ANJAL5678G1Z2' },
  { id: 'B3', name: 'Sakthi Pure',     type: 'Third-party Brand',color: '#1f8a5b', contact: 'Sakthi Agro, Erode',   phone: '+91 90000 33333', gstin: '33SAKTH9012H1Z9' },
  { id: 'B4', name: 'Annai Naturals',  type: 'Third-party Brand',color: '#7c3aed', contact: 'Annai Trading, Hosur', phone: '+91 90000 44444', gstin: '33ANNAI3456J1Z1' },
  { id: 'B5', name: 'Ruchi',           type: 'Third-party Brand',color: '#d97706', contact: 'Ruchi Soya, Chennai',  phone: '+91 90000 55555', gstin: '33RUCHI5555K1Z8' },
  { id: 'B6', name: 'Sunrich',         type: 'Third-party Brand',color: '#0d9488', contact: 'Sunrich Oils, Erode', phone: '+91 90000 66666', gstin: '33SUNRC6666L1Z4' },
  { id: 'B7', name: 'RBD Palmolein',   type: 'Bulk Brand',       color: '#dc2626', contact: 'RBD Refineries, Cuddalore', phone: '+91 90000 77777', gstin: '33RBDPL7777M1Z1' },
  { id: 'B8', name: 'Sivam Lamp Oil',  type: 'Own Brand',        color: '#b7791f', contact: 'Sivam Oils, Dharmapuri', phone: '+91 98430 88888', gstin: '33SVMOL8888N1Z7' },
  { id: 'B9', name: 'Vanaspathi',      type: 'BESS Brand',       color: '#475569', contact: 'BESS Bakeries, Trichy', phone: '+91 90000 99999', gstin: '33VSPTH9999P1Z3' },
  { id: 'B10', name: 'Castor Oil',     type: 'Pure Oil Brand',   color: '#059669', contact: 'Castor Mills, Salem',   phone: '+91 90000 12345', gstin: '33CSTOR1234Q1Z9' },
  { id: 'B11', name: 'CSK Coldpressed', type: 'Coldpressed Brand',color: '#9333ea', contact: 'CSK Organics, Karur', phone: '+91 90000 23456', gstin: '33CSKOG2345R1Z5' },
  { id: 'B12', name: 'VVD Gold',       type: 'Third-party Brand',color: '#ea580c', contact: 'VVD Gold, Tuticorin', phone: '+91 90000 34567', gstin: '33VVDGD3456S1Z2' },
  { id: 'B13', name: 'Provisions & Salt', type: 'General Goods', color: '#64748b', contact: 'Kristal Supplies, Salem', phone: '+91 90000 45678', gstin: '33PRVSN4567T1Z8' },
]

export const OIL_TYPES = ['Groundnut Oil','Gingelly Oil','Coconut Oil','Sunflower Oil','Palm Oil','Castor Oil','Lamp Oil','Vanaspathi','Rice Bran Oil','Multi Source Oil']
export const PACK_SIZES = ['500 ml','1 L','2 L','5 L','15 L Tin','15 kg Tin','Barrel','850 G Pouch','425 G Pouch','Pouch','Tin','Can','Bag']
export const UNIT_TYPES = ['Bottle','Tin','Can','Barrel','Carton','Pouch','Pcs','Bag','Pkt','kg']

// Master Products list with AWR Rates (Agency, Wholesale, Retail)
export const PRODUCTS: Product[] = [
  { id:'P01', code:'PRD-101', brandId:'B1', name:'KKK Gold Groundnut Oil 1L',   category:'Edible Oils', oilType:'Groundnut Oil', pack:'1 L',     unit:'Bottle', sku:'KKK-GN-1L',  hsn:'1508', gst:5,  cost:165, agencyRate:180, wholesaleRate:190, retailRate:198, price:198, mrp:215, minStock:200, stock:540, status:'Active' },
  { id:'P02', code:'PRD-102', brandId:'B1', name:'KKK Gold Groundnut Oil 5L',   category:'Edible Oils', oilType:'Groundnut Oil', pack:'5 L',     unit:'Can',    sku:'KKK-GN-5L',  hsn:'1508', gst:5,  cost:790, agencyRate:880, wholesaleRate:910, retailRate:945, price:945, mrp:999, minStock:80,  stock:120, status:'Active' },
  { id:'P03', code:'PRD-103', brandId:'B1', name:'KKK Gold Gingelly Oil 1L',    category:'Edible Oils', oilType:'Gingelly Oil',  pack:'1 L',     unit:'Bottle', sku:'KKK-GL-1L',  hsn:'1515', gst:5,  cost:230, agencyRate:250, wholesaleRate:265, retailRate:275, price:275, mrp:299, minStock:150, stock:310, status:'Active' },
  { id:'P04', code:'PRD-104', brandId:'B1', name:'KKK Gold Gingelly Oil 500ml', category:'Edible Oils', oilType:'Gingelly Oil',  pack:'500 ml',  unit:'Bottle', sku:'KKK-GL-500', hsn:'1515', gst:5,  cost:120, agencyRate:130, wholesaleRate:138, retailRate:145, price:145, mrp:159, minStock:200, stock:95,  status:'Active' },
  { id:'P05', code:'PRD-105', brandId:'B1', name:'KKK Gold Coconut Oil 1L',     category:'Edible Oils', oilType:'Coconut Oil',   pack:'1 L',     unit:'Bottle', sku:'KKK-CN-1L',  hsn:'1513', gst:5,  cost:190, agencyRate:205, wholesaleRate:218, retailRate:228, price:228, mrp:245, minStock:150, stock:402, status:'Active' },
  { id:'P06', code:'PRD-106', brandId:'B1', name:'KKK Gold Coconut Oil 5L Tin', category:'Edible Oils', oilType:'Coconut Oil',   pack:'5 L',     unit:'Tin',    sku:'KKK-CN-5L',  hsn:'1513', gst:5,  cost:920, agencyRate:1000,wholesaleRate:1050,retailRate:1100,price:1100,mrp:1150,minStock:60, stock:48,  status:'Active' },
  { id:'P07', code:'PRD-107', brandId:'B1', name:'KKK Gold Sunflower Oil 1L',   category:'Edible Oils', oilType:'Sunflower Oil', pack:'1 L',     unit:'Bottle', sku:'KKK-SF-1L',  hsn:'1512', gst:5,  cost:128, agencyRate:138, wholesaleRate:145, retailRate:152, price:152, mrp:165, minStock:250, stock:680, status:'Active' },
  { id:'P08', code:'PRD-108', brandId:'B1', name:'KKK Gold Sunflower Oil 15L',  category:'Edible Oils', oilType:'Sunflower Oil', pack:'15 L Tin',unit:'Tin',    sku:'KKK-SF-15L', hsn:'1512', gst:5,  cost:1850,agencyRate:2000,wholesaleRate:2100,retailRate:2190,price:2190,mrp:2299,minStock:40, stock:72,  status:'Active' },
  { id:'P09', code:'PRD-109', brandId:'B2', name:'Anjali Groundnut Oil 1L',     category:'Edible Oils', oilType:'Groundnut Oil', pack:'1 L',     unit:'Bottle', sku:'ANJ-GN-1L',  hsn:'1508', gst:5,  cost:170, agencyRate:185, wholesaleRate:195, retailRate:205, price:205, mrp:220, minStock:120, stock:260, status:'Active' },
  { id:'P10', code:'PRD-110', brandId:'B2', name:'Anjali Sunflower Oil 1L',     category:'Edible Oils', oilType:'Sunflower Oil', pack:'1 L',     unit:'Bottle', sku:'ANJ-SF-1L',  hsn:'1512', gst:5,  cost:130, agencyRate:142, wholesaleRate:150, retailRate:158, price:158, mrp:170, minStock:150, stock:88,  status:'Active' },
  { id:'P11', code:'PRD-111', brandId:'B2', name:'Anjali Palm Oil 15L Tin',     category:'Edible Oils', oilType:'Palm Oil',      pack:'15 L Tin',unit:'Tin',    sku:'ANJ-PL-15L', hsn:'1511', gst:5,  cost:1450,agencyRate:1550,wholesaleRate:1620,retailRate:1690,price:1690,mrp:1750,minStock:50, stock:130, status:'Active' },
  { id:'P12', code:'PRD-112', brandId:'B3', name:'Sakthi Pure Gingelly 1L',     category:'Edible Oils', oilType:'Gingelly Oil',  pack:'1 L',     unit:'Bottle', sku:'SAK-GL-1L',  hsn:'1515', gst:5,  cost:235, agencyRate:255, wholesaleRate:270, retailRate:282, price:282, mrp:305, minStock:100, stock:175, status:'Active' },
  { id:'P13', code:'PRD-113', brandId:'B3', name:'Sakthi Pure Coconut 500ml',   category:'Edible Oils', oilType:'Coconut Oil',   pack:'500 ml',  unit:'Bottle', sku:'SAK-CN-500', hsn:'1513', gst:5,  cost:98,  agencyRate:108, wholesaleRate:115, retailRate:122, price:122, mrp:135, minStock:200, stock:240, status:'Active' },
  { id:'P14', code:'PRD-114', brandId:'B3', name:'Sakthi Pure Groundnut 2L',    category:'Edible Oils', oilType:'Groundnut Oil', pack:'2 L',     unit:'Can',    sku:'SAK-GN-2L',  hsn:'1508', gst:5,  cost:330, agencyRate:355, wholesaleRate:375, retailRate:392, price:392, mrp:415, minStock:90,  stock:64,  status:'Active' },
  { id:'P15', code:'PRD-115', brandId:'B3', name:'Sakthi Pure Sunflower 5L',    category:'Edible Oils', oilType:'Sunflower Oil', pack:'5 L',     unit:'Can',    sku:'SAK-SF-5L',  hsn:'1512', gst:5,  cost:640, agencyRate:690, wholesaleRate:725, retailRate:760, price:760, mrp:799, minStock:70,  stock:150, status:'Active' },
  { id:'P16', code:'PRD-116', brandId:'B4', name:'Annai Coconut Oil 1L',        category:'Edible Oils', oilType:'Coconut Oil',   pack:'1 L',     unit:'Bottle', sku:'ANN-CN-1L',  hsn:'1513', gst:5,  cost:195, agencyRate:210, wholesaleRate:222, retailRate:235, price:235, mrp:255, minStock:120, stock:210, status:'Active' },
  { id:'P17', code:'PRD-117', brandId:'B4', name:'Annai Palm Oil Barrel',       category:'Edible Oils', oilType:'Palm Oil',      pack:'Barrel',  unit:'Barrel', sku:'ANN-PL-BRL', hsn:'1511', gst:5,  cost:14500,agencyRate:15400,wholesaleRate:16000,retailRate:16800,price:16800,mrp:17500,minStock:8,stock:14,status:'Active' },
  { id:'P18', code:'PRD-118', brandId:'B4', name:'Annai Castor Oil 1L',         category:'Edible Oils', oilType:'Castor Oil',    pack:'1 L',     unit:'Bottle', sku:'ANN-CS-1L',  hsn:'1515', gst:12, cost:175, agencyRate:190, wholesaleRate:202, retailRate:215, price:215, mrp:235, minStock:80,  stock:36,  status:'Active' },
  { id:'P19', code:'PRD-119', brandId:'B1', name:'KKK Gold Groundnut 15kg Tin', category:'Edible Oils', oilType:'Groundnut Oil', pack:'15 kg Tin',unit:'Tin',   sku:'KKK-GN-15K', hsn:'1508', gst:5,  cost:2350,agencyRate:2500,wholesaleRate:2650,retailRate:2780,price:2780,mrp:2899,minStock:30, stock:54,  status:'Active' },
  { id:'P20', code:'PRD-120', brandId:'B1', name:'KKK Gold Coconut 15kg Tin',   category:'Edible Oils', oilType:'Coconut Oil',   pack:'15 kg Tin',unit:'Tin',    sku:'KKK-CN-15K', hsn:'1513', gst:5,  cost:2700,agencyRate:2900,wholesaleRate:3050,retailRate:3180,price:3180,mrp:3299,minStock:25, stock:18,  status:'Active' },

  // --- IMAGE SHEET PRODUCTS: KKK BRAND ---
  { id:'P21', code:'PRD-121', brandId:'B1', name:'Multisource Edible Oil 850 G Pouch (1X10)', category:'Edible Oils', oilType:'Multi Source Oil', pack:'850 G Pouch', unit:'Pouch', sku:'KKK-MS-850G', hsn:'1517', gst:5, cost:110, agencyRate:120, wholesaleRate:125, retailRate:132, price:132, mrp:145, minStock:100, stock:350, status:'Active' },
  { id:'P22', code:'PRD-122', brandId:'B1', name:'Multi Source Edible Oil 425 G Pouch (1X20)', category:'Edible Oils', oilType:'Multi Source Oil', pack:'425 G Pouch', unit:'Pouch', sku:'KKK-MS-425G', hsn:'1517', gst:5, cost:55, agencyRate:62, wholesaleRate:66, retailRate:70, price:70, mrp:78, minStock:100, stock:420, status:'Active' },
  { id:'P23', code:'PRD-123', brandId:'B1', name:'Multi Source Edible Oil 5 Ltr Can (1X4)', category:'Edible Oils', oilType:'Multi Source Oil', pack:'5 Ltr Can', unit:'Can', sku:'KKK-MS-5L', hsn:'1517', gst:5, cost:650, agencyRate:720, wholesaleRate:750, retailRate:785, price:785, mrp:840, minStock:50, stock:180, status:'Active' },
  { id:'P24', code:'PRD-124', brandId:'B1', name:'Multi Source Edible Oil 200 Ml Pouch', category:'Edible Oils', oilType:'Multi Source Oil', pack:'200 Ml Pouch', unit:'Pouch', sku:'KKK-MS-200M', hsn:'1517', gst:5, cost:28, agencyRate:32, wholesaleRate:34, retailRate:37, price:37, mrp:42, minStock:150, stock:500, status:'Active' },
  { id:'P25', code:'PRD-125', brandId:'B1', name:'Multi Source Edible Oil 100 Ml Pcs (1X100)', category:'Edible Oils', oilType:'Multi Source Oil', pack:'100 Ml Pcs', unit:'Pcs', sku:'KKK-MS-100M', hsn:'1517', gst:5, cost:15, agencyRate:17, wholesaleRate:18.5, retailRate:20, price:20, mrp:23, minStock:200, stock:800, status:'Active' },
  { id:'P26', code:'PRD-126', brandId:'B1', name:'Multi Source Edible Oil 15 Ltr Tin', category:'Edible Oils', oilType:'Multi Source Oil', pack:'15 Ltr Tin', unit:'Tin', sku:'KKK-MS-15L', hsn:'1517', gst:5, cost:1950, agencyRate:2100, wholesaleRate:2180, retailRate:2250, price:2250, mrp:2390, minStock:30, stock:65, status:'Active' },

  // --- IMAGE SHEET PRODUCTS: RUCHI BRAND ---
  { id:'P27', code:'PRD-127', brandId:'B5', name:'Ruchi Gold Palmolein 850 G PP (1X10)', category:'Palmolein Oil', oilType:'Palm Oil', pack:'850 G PP', unit:'Pouch', sku:'RUC-PL-850G', hsn:'1511', gst:5, cost:92, agencyRate:99, wholesaleRate:104, retailRate:110, price:110, mrp:118, minStock:100, stock:320, status:'Active' },
  { id:'P28', code:'PRD-128', brandId:'B5', name:'Ruchi Gold Palmolein 425 G PP (1X20)', category:'Palmolein Oil', oilType:'Palm Oil', pack:'425 G PP', unit:'Pouch', sku:'RUC-PL-425G', hsn:'1511', gst:5, cost:48, agencyRate:52, wholesaleRate:55, retailRate:58, price:58, mrp:63, minStock:100, stock:400, status:'Active' },
  { id:'P29', code:'PRD-129', brandId:'B5', name:'Ruchi Gold Palmolein Tin Value Pack (15 Ltr)', category:'Palmolein Oil', oilType:'Palm Oil', pack:'15 Ltr Tin', unit:'Tin', sku:'RUC-PL-15L', hsn:'1511', gst:5, cost:1520, agencyRate:1620, wholesaleRate:1680, retailRate:1750, price:1750, mrp:1820, minStock:40, stock:90, status:'Active' },
  { id:'P30', code:'PRD-130', brandId:'B5', name:'Ruchi Gold Palmolein Tin 15 kg', category:'Palmolein Oil', oilType:'Palm Oil', pack:'15 kg Tin', unit:'Tin', sku:'RUC-PL-15K', hsn:'1511', gst:5, cost:1650, agencyRate:1750, wholesaleRate:1820, retailRate:1890, price:1890, mrp:1980, minStock:40, stock:85, status:'Active' },
  { id:'P31', code:'PRD-131', brandId:'B5', name:'Ruchi Gold Palmolein 750 G PP (1X10)', category:'Palmolein Oil', oilType:'Palm Oil', pack:'750 G PP', unit:'Pouch', sku:'RUC-PL-750G', hsn:'1511', gst:5, cost:83, agencyRate:89, wholesaleRate:93, retailRate:98, price:98, mrp:105, minStock:100, stock:210, status:'Active' },
  { id:'P32', code:'PRD-132', brandId:'B5', name:'Ruchi No. 1 Vanaspathi 893 G PP', category:'Vanaspathi', oilType:'Vanaspathi', pack:'893 G PP', unit:'Pouch', sku:'RUC-VN-893G', hsn:'1516', gst:5, cost:105, agencyRate:113, wholesaleRate:118, retailRate:125, price:125, mrp:135, minStock:80, stock:160, status:'Active' },
  { id:'P33', code:'PRD-133', brandId:'B5', name:'Ruchi No. 1 Vanaspathi 447 G PP', category:'Vanaspathi', oilType:'Vanaspathi', pack:'447 G PP', unit:'Pouch', sku:'RUC-VN-447G', hsn:'1516', gst:5, cost:55, agencyRate:60, wholesaleRate:63, retailRate:67, price:67, mrp:72, minStock:80, stock:220, status:'Active' },

  // --- IMAGE SHEET PRODUCTS: SUNRICH BRAND ---
  { id:'P34', code:'PRD-134', brandId:'B6', name:'Sunrich Ref Sun Oil 800 G PP (1X10)', category:'Sunflower Oil', oilType:'Sunflower Oil', pack:'800 G PP', unit:'Pouch', sku:'SUN-SF-800G', hsn:'1512', gst:5, cost:105, agencyRate:114, wholesaleRate:119, retailRate:126, price:126, mrp:135, minStock:100, stock:300, status:'Active' },
  { id:'P35', code:'PRD-135', brandId:'B6', name:'Sunrich Ref Sun Oil 400 GM PP (1X20)', category:'Sunflower Oil', oilType:'Sunflower Oil', pack:'400 G PP', unit:'Pouch', sku:'SUN-SF-400G', hsn:'1512', gst:5, cost:54, agencyRate:59, wholesaleRate:62, retailRate:66, price:66, mrp:72, minStock:100, stock:380, status:'Active' },
  { id:'P36', code:'PRD-136', brandId:'B6', name:'Sunrich Ref Sun Oil 5 Ltr Jar (1x4)', category:'Sunflower Oil', oilType:'Sunflower Oil', pack:'5 Ltr Jar', unit:'Can', sku:'SUN-SF-5L', hsn:'1512', gst:5, cost:680, agencyRate:735, wholesaleRate:765, retailRate:799, price:799, mrp:850, minStock:40, stock:110, status:'Active' },
  { id:'P37', code:'PRD-137', brandId:'B6', name:'Sunrich Ref Sun OIL 13Kg Tin', category:'Sunflower Oil', oilType:'Sunflower Oil', pack:'13 kg Tin', unit:'Tin', sku:'SUN-SF-13K', hsn:'1512', gst:5, cost:1680, agencyRate:1790, wholesaleRate:1860, retailRate:1930, price:1930, mrp:2050, minStock:30, stock:55, status:'Active' },
  { id:'P38', code:'PRD-138', brandId:'B6', name:'Sunrich Ref Sun Oil 1 Ltr', category:'Sunflower Oil', oilType:'Sunflower Oil', pack:'1 Ltr', unit:'Bottle', sku:'SUN-SF-1L', hsn:'1512', gst:5, cost:132, agencyRate:142, wholesaleRate:148, retailRate:156, price:156, mrp:168, minStock:150, stock:450, status:'Active' },

  // --- IMAGE SHEET PRODUCTS: RBD BRAND ---
  { id:'P39', code:'PRD-139', brandId:'B7', name:'RBD Palmolein 15 Kg Tin', category:'Palmolein Oil', oilType:'Palm Oil', pack:'15 kg Tin', unit:'Tin', sku:'RBD-PL-15K', hsn:'1511', gst:5, cost:1580, agencyRate:1680, wholesaleRate:1740, retailRate:1820, price:1820, mrp:1890, minStock:50, stock:140, status:'Active' },
  { id:'P40', code:'PRD-140', brandId:'B7', name:'RBD 15 Kg Tin (K Gold)', category:'Palmolein Oil', oilType:'Palm Oil', pack:'15 kg Tin', unit:'Tin', sku:'RBD-KG-15K', hsn:'1511', gst:5, cost:1620, agencyRate:1720, wholesaleRate:1790, retailRate:1860, price:1860, mrp:1940, minStock:40, stock:95, status:'Active' },
  { id:'P41', code:'PRD-141', brandId:'B7', name:'Olien 15 Kg Tin', category:'Palmolein Oil', oilType:'Palm Oil', pack:'15 kg Tin', unit:'Tin', sku:'RBD-OL-15K', hsn:'1511', gst:5, cost:1590, agencyRate:1690, wholesaleRate:1750, retailRate:1830, price:1830, mrp:1910, minStock:30, stock:70, status:'Active' },
  { id:'P42', code:'PRD-142', brandId:'B7', name:'RBD Palmolien (Bulk) (kg)', category:'Palmolein Oil', oilType:'Palm Oil', pack:'Bulk kg', unit:'kg', sku:'RBD-PL-BLK', hsn:'1511', gst:5, cost:98, agencyRate:104, wholesaleRate:108, retailRate:113, price:113, mrp:120, minStock:500, stock:2400, status:'Active' },

  // --- IMAGE SHEET PRODUCTS: SIVAM LAMP OIL BRAND ---
  { id:'P43', code:'PRD-143', brandId:'B8', name:'Sivam 1 Ltr Pet (R B)', category:'Lamp Oil', oilType:'Lamp Oil', pack:'1 Ltr', unit:'Bottle', sku:'SVM-LP-1L', hsn:'1515', gst:12, cost:115, agencyRate:126, wholesaleRate:132, retailRate:140, price:140, mrp:152, minStock:100, stock:280, status:'Active' },
  { id:'P44', code:'PRD-144', brandId:'B8', name:'Sivam 1/2 Ltr Pet (R B)', category:'Lamp Oil', oilType:'Lamp Oil', pack:'500 ml', unit:'Bottle', sku:'SVM-LP-500M', hsn:'1515', gst:12, cost:60, agencyRate:66, wholesaleRate:70, retailRate:75, price:75, mrp:82, minStock:100, stock:340, status:'Active' },
  { id:'P45', code:'PRD-145', brandId:'B8', name:'Sivam 200 Ml Pet (R B)', category:'Lamp Oil', oilType:'Lamp Oil', pack:'200 ml', unit:'Bottle', sku:'SVM-LP-200M', hsn:'1515', gst:12, cost:26, agencyRate:29, wholesaleRate:31, retailRate:34, price:34, mrp:38, minStock:150, stock:420, status:'Active' },
  { id:'P46', code:'PRD-146', brandId:'B8', name:'Sivam 100 Ml Pouch (R B)', category:'Lamp Oil', oilType:'Lamp Oil', pack:'100 ml', unit:'Pouch', sku:'SVM-LP-100P', hsn:'1515', gst:12, cost:13, agencyRate:15, wholesaleRate:16.5, retailRate:18, price:18, mrp:20, minStock:200, stock:600, status:'Active' },
  { id:'P47', code:'PRD-147', brandId:'B8', name:'Sivam 50 Ml Pouch (R B)', category:'Lamp Oil', oilType:'Lamp Oil', pack:'50 ml', unit:'Pouch', sku:'SVM-LP-50P', hsn:'1515', gst:12, cost:7, agencyRate:8.5, wholesaleRate:9.5, retailRate:11, price:11, mrp:12, minStock:200, stock:750, status:'Active' },
  { id:'P48', code:'PRD-148', brandId:'B8', name:'Sivam 5 Ltr Jar (R B)', category:'Lamp Oil', oilType:'Lamp Oil', pack:'5 Ltr', unit:'Can', sku:'SVM-LP-5L', hsn:'1515', gst:12, cost:570, agencyRate:620, wholesaleRate:655, retailRate:690, price:690, mrp:740, minStock:40, stock:85, status:'Active' },
  { id:'P49', code:'PRD-149', brandId:'B8', name:'Sivam 15 Kg Tin (RB)', category:'Lamp Oil', oilType:'Lamp Oil', pack:'15 kg Tin', unit:'Tin', sku:'SVM-LP-15K', hsn:'1515', gst:12, cost:1680, agencyRate:1800, wholesaleRate:1880, retailRate:1970, price:1970, mrp:2080, minStock:25, stock:40, status:'Active' },
  { id:'P50', code:'PRD-150', brandId:'B8', name:'Rice Brand Refined Oil', category:'Edible Oils', oilType:'Rice Bran Oil', pack:'1 Ltr', unit:'Bottle', sku:'SVM-RB-1L', hsn:'1515', gst:5, cost:125, agencyRate:135, wholesaleRate:142, retailRate:150, price:150, mrp:162, minStock:100, stock:260, status:'Active' },

  // --- IMAGE SHEET 2 PRODUCTS: VANASPATHI BRAND ---
  { id:'P51', code:'PRD-151', brandId:'B9', name:'BESS Puff Vanaspathi 15 Kg', category:'Vanaspathi', oilType:'Vanaspathi', pack:'15 kg Tin', unit:'Tin', sku:'VAN-BS-PF15K', hsn:'1516', gst:5, cost:1720, agencyRate:1830, wholesaleRate:1900, retailRate:1980, price:1980, mrp:2080, minStock:30, stock:75, status:'Active' },
  { id:'P52', code:'PRD-152', brandId:'B9', name:'BESS Cream Vanaspathi 14 Kg', category:'Vanaspathi', oilType:'Vanaspathi', pack:'14 kg Tin', unit:'Tin', sku:'VAN-BS-CR14K', hsn:'1516', gst:5, cost:1610, agencyRate:1710, wholesaleRate:1780, retailRate:1860, price:1860, mrp:1950, minStock:30, stock:60, status:'Active' },
  { id:'P53', code:'PRD-153', brandId:'B9', name:'BESS Biscuit Vanaspathi 15 Kg', category:'Vanaspathi', oilType:'Vanaspathi', pack:'15 kg Tin', unit:'Tin', sku:'VAN-BS-BS15K', hsn:'1516', gst:5, cost:1740, agencyRate:1850, wholesaleRate:1920, retailRate:2000, price:2000, mrp:2100, minStock:25, stock:50, status:'Active' },
  { id:'P54', code:'PRD-154', brandId:'B9', name:'Ovento Vanaspathi 15 Kg', category:'Vanaspathi', oilType:'Vanaspathi', pack:'15 kg Tin', unit:'Tin', sku:'VAN-OV-15K', hsn:'1516', gst:5, cost:1690, agencyRate:1790, wholesaleRate:1860, retailRate:1940, price:1940, mrp:2040, minStock:30, stock:65, status:'Active' },
  { id:'P55', code:'PRD-155', brandId:'B9', name:'Vanaspathi 15Kg- Gst (Baker King)', category:'Vanaspathi', oilType:'Vanaspathi', pack:'15 kg Tin', unit:'Tin', sku:'VAN-BK-15K', hsn:'1516', gst:5, cost:1730, agencyRate:1840, wholesaleRate:1910, retailRate:1990, price:1990, mrp:2090, minStock:30, stock:70, status:'Active' },

  // --- IMAGE SHEET 2 PRODUCTS: CASTOR OIL BRAND ---
  { id:'P56', code:'PRD-156', brandId:'B10', name:'Castor Oil 1 Ltr Pet', category:'Castor Oil', oilType:'Castor Oil', pack:'1 Ltr', unit:'Bottle', sku:'CST-OL-1L', hsn:'1515', gst:12, cost:175, agencyRate:190, wholesaleRate:202, retailRate:215, price:215, mrp:235, minStock:80, stock:180, status:'Active' },
  { id:'P57', code:'PRD-157', brandId:'B10', name:'Castor Oil 1/2 Ltr Pet', category:'Castor Oil', oilType:'Castor Oil', pack:'500 ml', unit:'Bottle', sku:'CST-OL-500M', hsn:'1515', gst:12, cost:90, agencyRate:99, wholesaleRate:105, retailRate:112, price:112, mrp:122, minStock:80, stock:210, status:'Active' },
  { id:'P58', code:'PRD-158', brandId:'B10', name:'Castor Oil 200 Ml Pet', category:'Castor Oil', oilType:'Castor Oil', pack:'200 ml', unit:'Bottle', sku:'CST-OL-200M', hsn:'1515', gst:12, cost:38, agencyRate:42, wholesaleRate:45, retailRate:49, price:49, mrp:55, minStock:100, stock:290, status:'Active' },
  { id:'P59', code:'PRD-159', brandId:'B10', name:'Castor Oil 5 Ltr Can', category:'Castor Oil', oilType:'Castor Oil', pack:'5 Ltr', unit:'Can', sku:'CST-OL-5L', hsn:'1515', gst:12, cost:860, agencyRate:930, wholesaleRate:980, retailRate:1040, price:1040, mrp:1120, minStock:30, stock:55, status:'Active' },
  { id:'P60', code:'PRD-160', brandId:'B10', name:'Castor Oil 15 Kg Tin', category:'Castor Oil', oilType:'Castor Oil', pack:'15 kg Tin', unit:'Tin', sku:'CST-OL-15K', hsn:'1515', gst:12, cost:2500, agencyRate:2680, wholesaleRate:2800, retailRate:2940, price:2940, mrp:3100, minStock:20, stock:35, status:'Active' },

  // --- IMAGE SHEET 2 PRODUCTS: CSK BRAND ---
  { id:'P61', code:'PRD-161', brandId:'B11', name:'CSK Coldpressed Gn Oil 1 Ltr Pet', category:'Edible Oils', oilType:'Groundnut Oil', pack:'1 Ltr', unit:'Bottle', sku:'CSK-GN-1L', hsn:'1508', gst:5, cost:185, agencyRate:200, wholesaleRate:212, retailRate:222, price:222, mrp:240, minStock:100, stock:240, status:'Active' },
  { id:'P62', code:'PRD-162', brandId:'B11', name:'CSK Coldpressed Gn Oil 1/2 Ltr Pet', category:'Edible Oils', oilType:'Groundnut Oil', pack:'500 ml', unit:'Bottle', sku:'CSK-GN-500M', hsn:'1508', gst:5, cost:95, agencyRate:104, wholesaleRate:110, retailRate:116, price:116, mrp:126, minStock:100, stock:310, status:'Active' },
  { id:'P63', code:'PRD-163', brandId:'B11', name:'CSK Coldpressed GN Oil 5 Lt Can', category:'Edible Oils', oilType:'Groundnut Oil', pack:'5 Ltr', unit:'Can', sku:'CSK-GN-5L', hsn:'1508', gst:5, cost:910, agencyRate:980, wholesaleRate:1030, retailRate:1080, price:1080, mrp:1160, minStock:40, stock:80, status:'Active' },
  { id:'P64', code:'PRD-164', brandId:'B11', name:'CSK Coldpressed GN Oil Tin 15kg', category:'Edible Oils', oilType:'Groundnut Oil', pack:'15 kg Tin', unit:'Tin', sku:'CSK-GN-15K', hsn:'1508', gst:5, cost:2650, agencyRate:2820, wholesaleRate:2950, retailRate:3080, price:3080, mrp:3250, minStock:25, stock:42, status:'Active' },

  // --- IMAGE SHEET 2 PRODUCTS: VVD GOLD BRAND ---
  { id:'P65', code:'PRD-165', brandId:'B12', name:'VVD Gold Coco 100 Ml Pouch', category:'Coconut Oil', oilType:'Coconut Oil', pack:'100 ml Pouch', unit:'Pouch', sku:'VVD-CN-100P', hsn:'1513', gst:5, cost:22, agencyRate:25, wholesaleRate:27, retailRate:30, price:30, mrp:34, minStock:150, stock:520, status:'Active' },
  { id:'P66', code:'PRD-166', brandId:'B12', name:'VVD Gold Coco 400 ML Pet', category:'Coconut Oil', oilType:'Coconut Oil', pack:'400 ml', unit:'Bottle', sku:'VVD-CN-400M', hsn:'1513', gst:5, cost:88, agencyRate:96, wholesaleRate:102, retailRate:110, price:110, mrp:120, minStock:100, stock:280, status:'Active' },
  { id:'P67', code:'PRD-167', brandId:'B12', name:'VVD Gold Coco 400ML POUCH', category:'Coconut Oil', oilType:'Coconut Oil', pack:'400 ml Pouch', unit:'Pouch', sku:'VVD-CN-400P', hsn:'1513', gst:5, cost:82, agencyRate:90, wholesaleRate:95, retailRate:102, price:102, mrp:112, minStock:100, stock:310, status:'Active' },
  { id:'P68', code:'PRD-168', brandId:'B12', name:'VVD Gold Coco 100 Ml Pet', category:'Coconut Oil', oilType:'Coconut Oil', pack:'100 ml', unit:'Bottle', sku:'VVD-CN-100M', hsn:'1513', gst:5, cost:25, agencyRate:28, wholesaleRate:30, retailRate:33, price:33, mrp:36, minStock:150, stock:480, status:'Active' },
  { id:'P69', code:'PRD-169', brandId:'B12', name:'VVD Gold Coco 150 ml Pet', category:'Coconut Oil', oilType:'Coconut Oil', pack:'150 ml', unit:'Bottle', sku:'VVD-CN-150M', hsn:'1513', gst:5, cost:36, agencyRate:40, wholesaleRate:43, retailRate:47, price:47, mrp:52, minStock:120, stock:360, status:'Active' },

  // --- IMAGE SHEET 2 PRODUCTS: PROVISIONS & SALT ---
  { id:'P70', code:'PRD-170', brandId:'B13', name:'Groundnut Bag', category:'Provisions', oilType:'Raw Provisions', pack:'Bag', unit:'Bag', sku:'PRV-GN-BAG', hsn:'1202', gst:5, cost:4200, agencyRate:4450, wholesaleRate:4600, retailRate:4800, price:4800, mrp:4990, minStock:20, stock:65, status:'Active' },
  { id:'P71', code:'PRD-171', brandId:'B13', name:'Kristal 1 Kg 25 Nos', category:'Salt & Provisions', oilType:'Salt', pack:'1 kg (Pack of 25)', unit:'Carton', sku:'PRV-SLT-25N', hsn:'2501', gst:0, cost:280, agencyRate:310, wholesaleRate:330, retailRate:350, price:350, mrp:375, minStock:30, stock:120, status:'Active' },
  { id:'P72', code:'PRD-172', brandId:'B13', name:'Kristal Kalluppu 1 Kg', category:'Salt & Provisions', oilType:'Salt', pack:'1 kg', unit:'Pkt', sku:'PRV-SLT-1KG', hsn:'2501', gst:0, cost:11, agencyRate:13, wholesaleRate:14, retailRate:15, price:15, mrp:18, minStock:100, stock:450, status:'Active' },
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

export const SALES: SalesOrder[] = [
  { id:'SO-3001', billingType:'GST', pricingType:'RETAIL', customerId:'C01', date:'2026-06-10', salesperson:'Anitha M', dispatch:'Delivered',        payStatus:'Paid',    items:[{productId:'P01',qty:120,rate:198},{productId:'P05',qty:40,rate:228}] },
  { id:'SO-3002', billingType:'GST', pricingType:'RETAIL', customerId:'C02', date:'2026-06-10', salesperson:'Anitha M', dispatch:'In Transit',       payStatus:'Pending', items:[{productId:'P07',qty:200,rate:152},{productId:'P08',qty:15,rate:2190}] },
  { id:'SO-3003', billingType:'GST', pricingType:'RETAIL', customerId:'C06', date:'2026-06-09', salesperson:'Anitha M', dispatch:'Loaded',           payStatus:'Pending', items:[{productId:'P01',qty:150,rate:198},{productId:'P03',qty:60,rate:275}] },
  { id:'SO-3004', billingType:'GST', pricingType:'RETAIL', customerId:'C08', date:'2026-06-09', salesperson:'Anitha M', dispatch:'Ready for Dispatch',payStatus:'Pending',items:[{productId:'P02',qty:30,rate:945},{productId:'P19',qty:20,rate:2780}] },
  { id:'SO-3005', billingType:'GST', pricingType:'RETAIL', customerId:'C04', date:'2026-06-08', salesperson:'Anitha M', dispatch:'Delivered',        payStatus:'Paid',    items:[{productId:'P09',qty:100,rate:205},{productId:'P11',qty:25,rate:1690}] },
  { id:'SO-3006', billingType:'GST', pricingType:'RETAIL', customerId:'C07', date:'2026-06-08', salesperson:'Anitha M', dispatch:'Packing Pending',  payStatus:'Pending', items:[{productId:'P16',qty:80,rate:235},{productId:'P18',qty:30,rate:215}] },
  { id:'SO-3007', billingType:'GST', pricingType:'RETAIL', customerId:'C03', date:'2026-06-07', salesperson:'Anitha M', dispatch:'Delivered',        payStatus:'Paid',    items:[{productId:'P12',qty:40,rate:282},{productId:'P13',qty:60,rate:122}] },
  { id:'SO-3008', billingType:'GST', pricingType:'RETAIL', customerId:'C05', date:'2026-06-07', salesperson:'Anitha M', dispatch:'Delivered',        payStatus:'Partial', items:[{productId:'P03',qty:50,rate:275},{productId:'P05',qty:30,rate:228}] },
  { id:'SO-3009', billingType:'GST', pricingType:'RETAIL', customerId:'C10', date:'2026-06-06', salesperson:'Anitha M', dispatch:'Order Received',   payStatus:'Pending', items:[{productId:'P07',qty:300,rate:152}] },
  { id:'SO-3010', billingType:'GST', pricingType:'RETAIL', customerId:'C02', date:'2026-06-05', salesperson:'Anitha M', dispatch:'Returned',         payStatus:'Pending', items:[{productId:'P15',qty:40,rate:760}] },
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
