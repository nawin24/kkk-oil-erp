import 'package:flutter/material.dart';

class ErpModuleInfo {
  final String key;
  final String label;
  final String desc;
  final IconData icon;

  const ErpModuleInfo({
    required this.key,
    required this.label,
    required this.desc,
    required this.icon,
  });
}

class AppConstants {
  static const String appName = 'KKK Oil Factory ERP';
  static const String appSubTitle = 'Horizon-style Factory Management';
  static const String defaultGstPassword = 'admin123';
  static const String altGstPassword = 'ERP@2026G';
  static const String defaultNonGstPassword = 'admin123n';
  static const String altNonGstPassword = 'ERP@2026N';

  static const List<String> oilTypes = [
    'Groundnut Oil',
    'Gingelly Oil',
    'Coconut Oil',
    'Sunflower Oil',
    'Palm Oil',
    'Castor Oil',
    'Lamp Oil',
    'Vanaspathi',
    'Rice Bran Oil',
    'Multi Source Oil',
  ];

  static const List<String> packSizes = [
    '500 ml',
    '1 L',
    '2 L',
    '5 L',
    '15 L Tin',
    '15 kg Tin',
    'Barrel',
    '850 G Pouch',
    '425 G Pouch',
    'Pouch',
    'Tin',
    'Can',
    'Bag',
  ];

  static const List<String> unitTypes = [
    'Bottle',
    'Tin',
    'Can',
    'Barrel',
    'Carton',
    'Pouch',
    'Pcs',
    'Bag',
    'Pkt',
    'kg',
  ];

  static const List<String> godowns = [
    'Main Godown',
    'Godown 2 (Dharmapuri)',
    'Godown 3 (Salem)',
  ];

  static const List<ErpModuleInfo> modules = [
    ErpModuleInfo(
      key: 'dashboard',
      label: 'Dashboard',
      desc: 'Executive overview, sales KPI, factory metrics & quick links',
      icon: Icons.dashboard_outlined,
    ),
    ErpModuleInfo(
      key: 'billing',
      label: 'GST Billing & POS',
      desc: 'Counter billing, voucher creation, invoice printing & sales receipts',
      icon: Icons.receipt_long_outlined,
    ),
    ErpModuleInfo(
      key: 'products',
      label: 'Products Master',
      desc: 'Product catalog, rates, stock levels & SKU categories',
      icon: Icons.inventory_2_outlined,
    ),
    ErpModuleInfo(
      key: 'price_management',
      label: 'Price Management',
      desc: 'Adjust wholesale, retail & dealer rates per brand/pack',
      icon: Icons.price_change_outlined,
    ),
    ErpModuleInfo(
      key: 'price_history',
      label: 'Price Change History',
      desc: 'Audit log of past price revisions and timestamps',
      icon: Icons.history_edu_outlined,
    ),
    ErpModuleInfo(
      key: 'inventory',
      label: 'Inventory & Stock',
      desc: 'Finished oils, bottles, pouches, raw materials & batch stocks',
      icon: Icons.warehouse_outlined,
    ),
    ErpModuleInfo(
      key: 'purchase',
      label: 'Purchase & Inward',
      desc: 'Seeds, unrefined oils, packaging supplies & purchase orders',
      icon: Icons.shopping_cart_outlined,
    ),
    ErpModuleInfo(
      key: 'production',
      label: 'Production Milling',
      desc: 'Milling runs, crushing batches, recovery yields & packaging',
      icon: Icons.precision_manufacturing_outlined,
    ),
    ErpModuleInfo(
      key: 'sales',
      label: 'Sales Orders',
      desc: 'Distributor orders, retailer dispatches & order tracking',
      icon: Icons.point_of_sale_outlined,
    ),
    ErpModuleInfo(
      key: 'logistics',
      label: 'Logistics & Dispatch',
      desc: 'Vehicle loading, gate passes, driver manifests & route logs',
      icon: Icons.local_shipping_outlined,
    ),
    ErpModuleInfo(
      key: 'customers',
      label: 'Customers Directory',
      desc: 'Customer ledgers, balances, contacts & credit tracking',
      icon: Icons.people_outline,
    ),
    ErpModuleInfo(
      key: 'suppliers',
      label: 'Suppliers Directory',
      desc: 'Vendor contacts, payables & raw material history',
      icon: Icons.business_outlined,
    ),
    ErpModuleInfo(
      key: 'reports',
      label: 'Reports & Analytics',
      desc: 'GST reports, sales turnover, production logs & ledger summaries',
      icon: Icons.bar_chart_outlined,
    ),
    ErpModuleInfo(
      key: 'employees',
      label: 'Employees & Roles',
      desc: 'Staff accounts, role assignments & operational credentials',
      icon: Icons.badge_outlined,
    ),
    ErpModuleInfo(
      key: 'settings',
      label: 'Company Settings',
      desc: 'Factory address, GSTIN, invoice prefixes & print templates',
      icon: Icons.settings_outlined,
    ),
  ];
}
