import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/seed_data.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/operations.dart';
import '../models/product.dart';
import '../models/sales_order.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class ErpMetrics {
  final double todaySales;
  final double monthSales;
  final double totalRevenue;
  final double customerOutstanding;
  final double inventoryValue;
  final double finishedValue;
  final double rawValue;
  final int todayBillsCount;
  final int monthBillsCount;
  final double gstMonthSales;
  final int gstMonthBillsCount;
  final double nonGstMonthSales;
  final int nonGstMonthBillsCount;
  final double totalProfit;
  final List<Product> lowStockProducts;
  final List<RawMaterial> lowRawMaterials;
  final Map<String, double> brandSales;
  final List<Map<String, dynamic>> salesTrend;

  const ErpMetrics({
    required this.todaySales,
    required this.monthSales,
    required this.totalRevenue,
    required this.customerOutstanding,
    required this.inventoryValue,
    required this.finishedValue,
    required this.rawValue,
    required this.todayBillsCount,
    required this.monthBillsCount,
    this.gstMonthSales = 0.0,
    this.gstMonthBillsCount = 0,
    this.nonGstMonthSales = 0.0,
    this.nonGstMonthBillsCount = 0,
    this.totalProfit = 0.0,
    required this.lowStockProducts,
    required this.lowRawMaterials,
    required this.brandSales,
    required this.salesTrend,
  });
}

class DataProvider extends ChangeNotifier {
  List<Brand> _brands = [];
  List<Product> _products = [];
  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  List<SalesOrder> _sales = [];
  List<RawMaterial> _rawMaterials = [];
  List<Purchase> _purchases = [];
  List<ProductionBatch> _production = [];
  List<Dispatch> _dispatches = [];
  List<Expense> _expenses = [];
  List<PriceHistoryRecord> _priceHistory = [];
  List<AuditRecord> _auditLogs = [];
  Company _company = Company.defaultCompany;
  bool _initialized = false;
  bool _firestoreConnected = false;

  bool get isInitialized => _initialized;
  bool get isFirestoreConnected => _firestoreConnected;
  List<Brand> get brands => _brands;
  List<Product> get products => _products;
  List<Customer> get customers => _customers;
  List<Supplier> get suppliers => _suppliers;
  List<SalesOrder> get sales => _sales;
  List<RawMaterial> get rawMaterials => _rawMaterials;
  List<Purchase> get purchases => _purchases;
  List<ProductionBatch> get production => _production;
  List<Dispatch> get dispatches => _dispatches;
  List<Expense> get expenses => _expenses;
  List<PriceHistoryRecord> get priceHistory => _priceHistory;
  List<AuditRecord> get auditLogs => _auditLogs;
  Company get company => _company;

  DataProvider() {
    _init();
  }

  Future<void> _init() async {
    // 1. Brands
    final rawBrands = await StorageService.loadBrands();
    _brands = rawBrands != null && rawBrands.isNotEmpty
        ? rawBrands.map((m) => Brand.fromMap(m)).toList()
        : List.from(SeedData.brands);

    // 2. Products
    final rawProds = await StorageService.loadProducts();
    _products = rawProds != null && rawProds.isNotEmpty
        ? rawProds.map((m) => Product.fromMap(m)).toList()
        : List.from(SeedData.products);

    // 3. Customers
    final rawCusts = await StorageService.loadCustomers();
    _customers = rawCusts != null && rawCusts.isNotEmpty
        ? rawCusts.map((m) => Customer.fromMap(m)).toList()
        : List.from(SeedData.customers);

    // 4. Suppliers
    final rawSupps = await StorageService.loadSuppliers();
    _suppliers = rawSupps != null && rawSupps.isNotEmpty
        ? rawSupps.map((m) => Supplier.fromMap(m)).toList()
        : List.from(SeedData.suppliers);

    // 5. Sales
    final rawSales = await StorageService.loadSales();
    _sales = rawSales != null && rawSales.isNotEmpty
        ? rawSales.map((m) => SalesOrder.fromMap(m)).toList()
        : SeedData.getInitialSales();

    // 6. Raw Materials
    final rawRms = await StorageService.loadRawMaterials();
    _rawMaterials = rawRms != null && rawRms.isNotEmpty
        ? rawRms.map((m) => RawMaterial.fromMap(m)).toList()
        : List.from(SeedData.rawMaterials);

    // 7. Operations
    final rawPurch = await StorageService.loadPurchases();
    _purchases = rawPurch != null && rawPurch.isNotEmpty
        ? rawPurch.map((m) => Purchase.fromMap(m)).toList()
        : List.from(SeedData.purchases);

    final rawProdBatches = await StorageService.loadProduction();
    _production = rawProdBatches != null && rawProdBatches.isNotEmpty
        ? rawProdBatches.map((m) => ProductionBatch.fromMap(m)).toList()
        : List.from(SeedData.productionBatches);

    final rawDisps = await StorageService.loadDispatches();
    _dispatches = rawDisps != null && rawDisps.isNotEmpty
        ? rawDisps.map((m) => Dispatch.fromMap(m)).toList()
        : List.from(SeedData.dispatches);

    final rawExps = await StorageService.loadExpenses();
    _expenses = rawExps != null && rawExps.isNotEmpty
        ? rawExps.map((m) => Expense.fromMap(m)).toList()
        : List.from(SeedData.expenses);

    // 8. Company
    final rawComp = await StorageService.loadCompany();
    _company = rawComp != null ? Company.fromMap(rawComp) : Company.defaultCompany;

    // 9. Histories & Audits
    final rawHist = await StorageService.loadPriceHistory();
    _priceHistory = rawHist != null ? rawHist.map((m) => PriceHistoryRecord.fromMap(m)).toList() : [];

    final rawAud = await StorageService.loadAuditLogs();
    _auditLogs = rawAud != null ? rawAud.map((m) => AuditRecord.fromMap(m)).toList() : [];

    _initialized = true;
    notifyListeners();

    // Background sync from live Firestore database
    _syncFromFirestore();
  }

  Future<void> _syncFromFirestore() async {
    if (!FirebaseService.isConfigured) return;
    try {
      // 1. Products
      final prods = await FirebaseService.getCollection('products');
      if (prods.isNotEmpty) {
        final remote = prods.map((m) => Product.fromMap(m)).toList();
        final ids = remote.map((p) => p.id).toSet();
        for (final lp in _products) {
          if (!ids.contains(lp.id)) remote.add(lp);
        }
        _products = remote;
        await StorageService.saveProducts(_products.map((p) => p.toMap()).toList());
      }

      // 2. Brands
      final brands = await FirebaseService.getCollection('brands');
      if (brands.isNotEmpty) {
        final remote = brands.map((m) => Brand.fromMap(m)).toList();
        final ids = remote.map((b) => b.id).toSet();
        for (final lb in _brands) {
          if (!ids.contains(lb.id)) remote.add(lb);
        }
        _brands = remote;
        await StorageService.saveBrands(_brands.map((b) => b.toMap()).toList());
      }

      // 3. Customers
      final custs = await FirebaseService.getCollection('customers');
      if (custs.isNotEmpty) {
        final remote = custs.map((m) => Customer.fromMap(m)).toList();
        final ids = remote.map((c) => c.id).toSet();
        for (final lc in _customers) {
          if (!ids.contains(lc.id)) remote.add(lc);
        }
        _customers = remote;
        await StorageService.saveCustomers(_customers.map((c) => c.toMap()).toList());
      }

      // 4. Suppliers
      final supps = await FirebaseService.getCollection('suppliers');
      if (supps.isNotEmpty) {
        final remote = supps.map((m) => Supplier.fromMap(m)).toList();
        final ids = remote.map((s) => s.id).toSet();
        for (final ls in _suppliers) {
          if (!ids.contains(ls.id)) remote.add(ls);
        }
        _suppliers = remote;
        await StorageService.saveSuppliers(_suppliers.map((s) => s.toMap()).toList());
      }

      // 5. Sales
      final sales = await FirebaseService.getCollection('sales');
      if (sales.isNotEmpty) {
        final remote = sales.map((m) => SalesOrder.fromMap(m)).toList();
        final ids = remote.map((s) => s.id).toSet();
        for (final ls in _sales) {
          if (!ids.contains(ls.id)) remote.add(ls);
        }
        _sales = remote;
        await StorageService.saveSales(_sales.map((s) => s.toMap()).toList());
      }

      // 6. Raw Materials
      final rms = await FirebaseService.getCollection('rawMaterials');
      if (rms.isNotEmpty) {
        final remote = rms.map((m) => RawMaterial.fromMap(m)).toList();
        final ids = remote.map((r) => r.id).toSet();
        for (final lr in _rawMaterials) {
          if (!ids.contains(lr.id)) remote.add(lr);
        }
        _rawMaterials = remote;
        await StorageService.saveRawMaterials(_rawMaterials.map((r) => r.toMap()).toList());
      }

      // 7. Purchases
      final purchs = await FirebaseService.getCollection('purchases');
      if (purchs.isNotEmpty) {
        final remote = purchs.map((m) => Purchase.fromMap(m)).toList();
        final ids = remote.map((p) => p.id).toSet();
        for (final lp in _purchases) {
          if (!ids.contains(lp.id)) remote.add(lp);
        }
        _purchases = remote;
        await StorageService.savePurchases(_purchases.map((p) => p.toMap()).toList());
      }

      // 8. Production
      final prodsBatches = await FirebaseService.getCollection('production');
      if (prodsBatches.isNotEmpty) {
        final remote = prodsBatches.map((m) => ProductionBatch.fromMap(m)).toList();
        final ids = remote.map((p) => p.id).toSet();
        for (final lp in _production) {
          if (!ids.contains(lp.id)) remote.add(lp);
        }
        _production = remote;
        await StorageService.saveProduction(_production.map((p) => p.toMap()).toList());
      }

      // 9. Dispatches
      final disps = await FirebaseService.getCollection('dispatches');
      if (disps.isNotEmpty) {
        final remote = disps.map((m) => Dispatch.fromMap(m)).toList();
        final ids = remote.map((d) => d.id).toSet();
        for (final ld in _dispatches) {
          if (!ids.contains(ld.id)) remote.add(ld);
        }
        _dispatches = remote;
        await StorageService.saveDispatches(_dispatches.map((d) => d.toMap()).toList());
      }

      // 10. Expenses
      final exps = await FirebaseService.getCollection('expenses');
      if (exps.isNotEmpty) {
        final remote = exps.map((m) => Expense.fromMap(m)).toList();
        final ids = remote.map((e) => e.id).toSet();
        for (final le in _expenses) {
          if (!ids.contains(le.id)) remote.add(le);
        }
        _expenses = remote;
        await StorageService.saveExpenses(_expenses.map((e) => e.toMap()).toList());
      }

      // 11. Price History
      final priceHists = await FirebaseService.getCollection('priceHistory');
      if (priceHists.isNotEmpty) {
        final remote = priceHists.map((m) => PriceHistoryRecord.fromMap(m)).toList();
        final ids = remote.map((h) => h.id).toSet();
        for (final lh in _priceHistory) {
          if (!ids.contains(lh.id)) remote.add(lh);
        }
        _priceHistory = remote;
        await StorageService.savePriceHistory(_priceHistory.map((h) => h.toMap()).toList());
      }

      // 12. Audit Logs
      final audits = await FirebaseService.getCollection('auditLogs');
      if (audits.isNotEmpty) {
        final remote = audits.map((m) => AuditRecord.fromMap(m)).toList();
        final ids = remote.map((a) => a.id).toSet();
        for (final la in _auditLogs) {
          if (!ids.contains(la.id)) remote.add(la);
        }
        _auditLogs = remote;
        await StorageService.saveAuditLogs(_auditLogs.map((a) => a.toMap()).toList());
      }

      _firestoreConnected = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Firestore background sync error: $e');
      }
    }
  }

  // Sales Orders Filtered based on active User Session & Mode
  List<SalesOrder> getFilteredSales(UserSession? session) {
    if (session == null) return [];

    final isSuper = session.isSuperAdmin;
    final sessRole = session.role;
    final sessUserId = session.id;

    return _sales.where((s) {
      if (s.grandTotal <= 0 || s.items.isEmpty) return false;

      // 1. STRICT NON-GST ISOLATION:
      // Non-GST bills are STRICTLY restricted to Super Admin only
      if (s.isNonGst && !isSuper) {
        return false;
      }

      // 2. Role Hierarchy Isolation:
      if (isSuper) return true;
      if (sessRole == 'admin') {
        if (s.createdByRole == 'super_admin' || s.createdByRole == 'super_admin_nongst') return false;
        return true;
      } else if (sessRole == 'manager') {
        if (s.createdByRole == 'super_admin' || s.createdByRole == 'admin') return false;
        return true;
      } else if (sessRole == 'cashier') {
        if (s.createdByRole != 'cashier' && s.userId != sessUserId) return false;
        return true;
      }

      return true;
    }).toList();
  }

  // Generate Next Voucher Number
  String generateNextVoucherNo(String billingType) {
    final prefix = billingType == 'GST' ? 'GST-2627-' : 'NG-2627-';
    final matchingSales = _sales.where((s) {
      final bType = s.billingType.isNotEmpty ? s.billingType : (s.id.startsWith('NG') ? 'NON_GST' : 'GST');
      return bType == billingType && s.voucherNo.startsWith(prefix);
    }).toList();

    int maxNum = 0;
    for (final s in matchingSales) {
      final numStr = s.voucherNo.replaceFirst(prefix, '');
      final parsed = int.tryParse(numStr);
      if (parsed != null && parsed > maxNum) {
        maxNum = parsed;
      }
    }

    final nextNum = maxNum + 1;
    return '$prefix${nextNum.toString().padLeft(4, '0')}';
  }

  // Save Sales Order with Instant Stock Deduction
  Future<SalesOrder> saveSalesOrder({
    required SalesOrder order,
    required UserSession user,
  }) async {
    // 1. Deduct Stock immediately from inventory
    _products = _products.map((p) {
      final billItem = order.items.firstWhere(
        (it) => it.productId == p.id,
        orElse: () => const InvoiceItem(
          productId: '',
          productCode: '',
          productName: '',
          unit: '',
          qty: 0,
          rate: 0,
          mrp: 0,
          pricingType: PricingType.retail,
          appliedRate: 0,
          taxableAmount: 0,
          gstRate: 0,
          gstAmount: 0,
          finalAmount: 0,
        ),
      );

      if (billItem.productId.isNotEmpty && billItem.qty > 0) {
        final newStock = (p.stock - billItem.qty).clamp(0.0, 9999999.0);
        return p.copyWith(stock: newStock, updatedDate: AppFormatters.todayISO());
      }
      return p;
    }).toList();

    // 2. Adjust Customer Outstanding if credit
    if (order.payStatus == 'Credit' && order.customerId.isNotEmpty) {
      _customers = _customers.map((c) {
        if (c.id == order.customerId) {
          return c.copyWith(outstanding: c.outstanding + order.grandTotal);
        }
        return c;
      }).toList();
    }

    // 3. Add to Sales
    _sales = [order, ..._sales.where((s) => s.id != order.id && s.voucherNo != order.voucherNo)];

    // 4. Audit Log
    addAuditLog(
      user: user.name,
      userId: user.id,
      role: user.roleLabel,
      action: 'BILL_CREATED',
      module: 'BILLING',
      details: '${order.voucherNo} | ${order.billingType} | ₹${order.grandTotal.toStringAsFixed(2)}',
    );

    // 5. Persist to storage & Firestore
    await StorageService.saveProducts(_products.map((p) => p.toMap()).toList());
    await StorageService.saveCustomers(_customers.map((c) => c.toMap()).toList());
    await StorageService.saveSales(_sales.map((s) => s.toMap()).toList());

    // Sync to Firestore backend
    FirebaseService.setDocument('sales', order.id, order.toMap());
    FirebaseService.setDocument('invoices', order.id, order.toMap());
    for (final it in order.items) {
      final p = _products.where((prod) => prod.id == it.productId).firstOrNull;
      if (p != null) {
        FirebaseService.setDocument('products', p.id, p.toMap());
      }
    }
    if (order.customerId.isNotEmpty) {
      final c = _customers.where((cust) => cust.id == order.customerId).firstOrNull;
      if (c != null) {
        FirebaseService.setDocument('customers', c.id, c.toMap());
      }
    }

    notifyListeners();
    return order;
  }

  // Cancel Sales Order & Restore Stock
  Future<void> cancelSalesOrder({
    required String orderId,
    required String reason,
    required UserSession user,
  }) async {
    final order = _sales.firstWhere((s) => s.id == orderId, orElse: () => throw Exception('Order not found'));
    if (order.status == 'CANCELLED') return;

    // 1. Restore Stock
    _products = _products.map((p) {
      final billItem = order.items.firstWhere(
        (it) => it.productId == p.id,
        orElse: () => const InvoiceItem(
          productId: '',
          productCode: '',
          productName: '',
          unit: '',
          qty: 0,
          rate: 0,
          mrp: 0,
          pricingType: PricingType.retail,
          appliedRate: 0,
          taxableAmount: 0,
          gstRate: 0,
          gstAmount: 0,
          finalAmount: 0,
        ),
      );

      if (billItem.productId.isNotEmpty && billItem.qty > 0) {
        return p.copyWith(stock: p.stock + billItem.qty, updatedDate: AppFormatters.todayISO());
      }
      return p;
    }).toList();

    // 2. Reduce Customer Outstanding if it was credit
    if (order.payStatus == 'Credit' && order.customerId.isNotEmpty) {
      _customers = _customers.map((c) {
        if (c.id == order.customerId) {
          final newOut = (c.outstanding - order.grandTotal).clamp(0.0, 9999999.0);
          return c.copyWith(outstanding: newOut);
        }
        return c;
      }).toList();
    }

    // 3. Mark Cancelled
    SalesOrder? cancelledOrder;
    _sales = _sales.map((s) {
      if (s.id == orderId) {
        cancelledOrder = s.copyWith(
          status: 'CANCELLED',
          cancelledBy: user.name,
          cancelledDate: DateTime.now().toIso8601String(),
          cancelledReason: reason,
        );
        return cancelledOrder!;
      }
      return s;
    }).toList();

    // 4. Audit Log
    addAuditLog(
      user: user.name,
      userId: user.id,
      role: user.roleLabel,
      action: 'BILL_CANCELLED',
      module: 'BILLING',
      details: '${order.voucherNo} cancelled. Reason: $reason',
    );

    await StorageService.saveProducts(_products.map((p) => p.toMap()).toList());
    await StorageService.saveCustomers(_customers.map((c) => c.toMap()).toList());
    await StorageService.saveSales(_sales.map((s) => s.toMap()).toList());

    if (cancelledOrder != null) {
      FirebaseService.setDocument('sales', cancelledOrder!.id, cancelledOrder!.toMap());
    }

    notifyListeners();
  }

  // Price Management: Update Rate & Record History
  Future<void> updateProductRate({
    required String productId,
    required PricingType pricingType,
    required double newRate,
    required String effectiveDate,
    required UserSession user,
  }) async {
    final p = _products.firstWhere((x) => x.id == productId, orElse: () => throw Exception('Product not found'));
    final oldRate = p.getRateFor(pricingType);
    if (oldRate == newRate) return;

    // 1. Record History
    final hist = PriceHistoryRecord(
      id: 'PH-${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: p.name,
      pricingType: pricingType,
      oldRate: oldRate,
      newRate: newRate,
      effectiveDate: effectiveDate,
      updatedBy: user.name,
      updatedAt: DateTime.now().toIso8601String(),
    );
    _priceHistory = [hist, ..._priceHistory];

    // 2. Update Product
    Product updated = p.copyWith(updatedDate: AppFormatters.todayISO());
    switch (pricingType) {
      case PricingType.agency:
        updated = updated.copyWith(agencyRate: newRate);
        break;
      case PricingType.wholesale:
        updated = updated.copyWith(wholesaleRate: newRate);
        break;
      case PricingType.retail:
        updated = updated.copyWith(retailRate: newRate, price: newRate);
        break;
    }

    _products = _products.map((x) => x.id == productId ? updated : x).toList();

    // 3. Audit Log
    addAuditLog(
      user: user.name,
      userId: user.id,
      role: user.roleLabel,
      action: 'PRICE_CHANGE',
      module: 'PRICE_MANAGEMENT',
      details: '${p.name} (${pricingType.label}): ₹$oldRate → ₹$newRate (Eff: $effectiveDate)',
    );

    await StorageService.saveProducts(_products.map((p) => p.toMap()).toList());
    await StorageService.savePriceHistory(_priceHistory.map((h) => h.toMap()).toList());

    // Sync to Firestore
    FirebaseService.setDocument('products', productId, updated.toMap());
    FirebaseService.setDocument('priceHistory', hist.id, hist.toMap());

    notifyListeners();
  }

  // Product CRUD
  Future<void> saveProduct(Product product) async {
    final exists = _products.any((p) => p.id == product.id);
    if (exists) {
      _products = _products.map((p) => p.id == product.id ? product : p).toList();
    } else {
      _products = [..._products, product];
    }
    await StorageService.saveProducts(_products.map((p) => p.toMap()).toList());
    FirebaseService.setDocument('products', product.id, product.toMap());
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    _products = _products.where((p) => p.id != productId).toList();
    await StorageService.saveProducts(_products.map((p) => p.toMap()).toList());
    FirebaseService.deleteDocument('products', productId);
    notifyListeners();
  }

  // Customer CRUD
  Future<void> saveCustomer(Customer customer) async {
    final exists = _customers.any((c) => c.id == customer.id);
    if (exists) {
      _customers = _customers.map((c) => c.id == customer.id ? customer : c).toList();
    } else {
      _customers = [..._customers, customer];
    }
    await StorageService.saveCustomers(_customers.map((c) => c.toMap()).toList());
    FirebaseService.setDocument('customers', customer.id, customer.toMap());
    notifyListeners();
  }

  // Supplier CRUD
  Future<void> saveSupplier(Supplier supplier) async {
    final exists = _suppliers.any((s) => s.id == supplier.id);
    if (exists) {
      _suppliers = _suppliers.map((s) => s.id == supplier.id ? supplier : s).toList();
    } else {
      _suppliers = [..._suppliers, supplier];
    }
    await StorageService.saveSuppliers(_suppliers.map((s) => s.toMap()).toList());
    FirebaseService.setDocument('suppliers', supplier.id, supplier.toMap());
    notifyListeners();
  }

  // Company Settings
  Future<void> saveCompany(Company company) async {
    _company = company;
    await StorageService.saveCompany(_company.toMap());
    FirebaseService.setDocument('config', 'company', _company.toMap());
    notifyListeners();
  }

  // Audit Logs
  void addAuditLog({
    required String user,
    required String userId,
    required String role,
    required String action,
    required String module,
    required String details,
  }) {
    final rec = AuditRecord(
      id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
      user: user,
      userId: userId,
      role: role,
      action: action,
      module: module,
      details: details,
      timestamp: DateTime.now().toIso8601String(),
    );
    _auditLogs = [rec, ..._auditLogs].take(200).toList();
    StorageService.saveAuditLogs(_auditLogs.map((a) => a.toMap()).toList());
    FirebaseService.setDocument('auditLogs', rec.id, rec.toMap());
  }

  // Sync with Firestore manually
  Future<void> syncWithFirestore() async {
    await _syncFromFirestore();
  }

  // Seed All Local Data to Firestore Cloud
  Future<void> seedToFirestore() async {
    for (final b in _brands) {
      await FirebaseService.setDocument('brands', b.id, b.toMap());
    }
    for (final p in _products) {
      await FirebaseService.setDocument('products', p.id, p.toMap());
    }
    for (final c in _customers) {
      await FirebaseService.setDocument('customers', c.id, c.toMap());
    }
    for (final s in _suppliers) {
      await FirebaseService.setDocument('suppliers', s.id, s.toMap());
    }
    for (final r in _rawMaterials) {
      await FirebaseService.setDocument('rawMaterials', r.id, r.toMap());
    }
    for (final p in _purchases) {
      await FirebaseService.setDocument('purchases', p.id, p.toMap());
    }
    for (final pb in _production) {
      await FirebaseService.setDocument('production', pb.id, pb.toMap());
    }
    for (final d in _dispatches) {
      await FirebaseService.setDocument('dispatches', d.id, d.toMap());
    }
    for (final e in _expenses) {
      await FirebaseService.setDocument('expenses', e.id, e.toMap());
    }
    for (final s in _sales) {
      await FirebaseService.setDocument('sales', s.id, s.toMap());
    }
    _firestoreConnected = true;
    notifyListeners();
  }

  // Reset to Seed Demo Data
  Future<void> resetDemoData() async {
    await StorageService.clearAll();
    _brands = List.from(SeedData.brands);
    _products = List.from(SeedData.products);
    _customers = List.from(SeedData.customers);
    _suppliers = List.from(SeedData.suppliers);
    _rawMaterials = List.from(SeedData.rawMaterials);
    _purchases = List.from(SeedData.purchases);
    _production = List.from(SeedData.productionBatches);
    _dispatches = List.from(SeedData.dispatches);
    _expenses = List.from(SeedData.expenses);
    _sales = SeedData.getInitialSales();
    _priceHistory = [];
    _auditLogs = [];
    _company = Company.defaultCompany;

    await StorageService.saveBrands(_brands.map((b) => b.toMap()).toList());
    await StorageService.saveProducts(_products.map((p) => p.toMap()).toList());
    await StorageService.saveCustomers(_customers.map((c) => c.toMap()).toList());
    await StorageService.saveSuppliers(_suppliers.map((s) => s.toMap()).toList());
    await StorageService.saveRawMaterials(_rawMaterials.map((r) => r.toMap()).toList());
    await StorageService.savePurchases(_purchases.map((p) => p.toMap()).toList());
    await StorageService.saveProduction(_production.map((p) => p.toMap()).toList());
    await StorageService.saveDispatches(_dispatches.map((d) => d.toMap()).toList());
    await StorageService.saveExpenses(_expenses.map((e) => e.toMap()).toList());
    await StorageService.saveSales(_sales.map((s) => s.toMap()).toList());
    await StorageService.saveCompany(_company.toMap());

    notifyListeners();
  }

  // Dashboard Metrics
  ErpMetrics computeMetrics(UserSession? session) {
    final visibleSales = getFilteredSales(session).where((s) => !s.isCancelled).toList();
    final today = AppFormatters.todayISO();

    double todaySales = 0.0;
    double monthSales = 0.0;
    double totalRevenue = 0.0;
    int todayBillsCount = 0;
    int monthBillsCount = 0;

    final thisMonth = today.substring(0, 7); // yyyy-MM
    final Map<String, double> brandSales = {};

    final brandMap = {for (final b in _brands) b.id: b.name};
    final prodMap = {for (final p in _products) p.id: p};

    for (final s in visibleSales) {
      totalRevenue += s.grandTotal;

      if (s.date == today) {
        todaySales += s.grandTotal;
        todayBillsCount++;
      }

      if (s.date.startsWith(thisMonth)) {
        monthSales += s.grandTotal;
        monthBillsCount++;
      }

      for (final it in s.items) {
        final prod = prodMap[it.productId];
        if (prod != null) {
          final bName = brandMap[prod.brandId] ?? 'Other';
          brandSales[bName] = (brandSales[bName] ?? 0.0) + it.finalAmount;
        }
      }
    }

    double custOutstanding = 0.0;
    for (final c in _customers) {
      custOutstanding += c.outstanding;
    }

    final finishedValue = _products.fold<double>(0.0, (sum, p) => sum + (p.stock * p.cost));
    final rawValue = _rawMaterials.fold<double>(0.0, (sum, r) => sum + (r.stock * r.cost));
    final inventoryValue = finishedValue + rawValue;

    final lowStock = _products.where((p) => p.stock <= p.minStock).toList();
    final lowRaw = _rawMaterials.where((r) => r.stock <= r.minStock).toList();

    // Past 7 days sales trend
    final List<Map<String, dynamic>> salesTrend = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final iso = DateFormat('yyyy-MM-dd').format(date);
      final label = DateFormat('E').format(date); // Mon, Tue...

      double dayTotal = 0.0;
      for (final s in visibleSales) {
        if (s.date == iso) {
          dayTotal += s.grandTotal;
        }
      }
      salesTrend.add({'day': label, 'date': iso, 'sales': dayTotal});
    }

    // Separate GST vs Non-GST stream calculations for Super Admin table
    double gstMonthSales = 0.0;
    int gstMonthBillsCount = 0;
    double nonGstMonthSales = 0.0;
    int nonGstMonthBillsCount = 0;

    for (final s in _sales.where((s) => !s.isCancelled)) {
      final isNg = s.billingType == 'NON_GST' || s.id.startsWith('NG') || s.voucherNo.startsWith('NG');
      if (s.date.startsWith(thisMonth)) {
        if (isNg) {
          nonGstMonthSales += s.grandTotal;
          nonGstMonthBillsCount++;
        } else {
          gstMonthSales += s.grandTotal;
          gstMonthBillsCount++;
        }
      }
    }

    final totalProfit = monthSales * 0.17; // Estimated ~17% gross profit margin

    return ErpMetrics(
      todaySales: todaySales,
      monthSales: monthSales,
      totalRevenue: totalRevenue,
      customerOutstanding: custOutstanding,
      inventoryValue: inventoryValue,
      finishedValue: finishedValue,
      rawValue: rawValue,
      todayBillsCount: todayBillsCount,
      monthBillsCount: monthBillsCount,
      gstMonthSales: gstMonthSales,
      gstMonthBillsCount: gstMonthBillsCount,
      nonGstMonthSales: nonGstMonthSales,
      nonGstMonthBillsCount: nonGstMonthBillsCount,
      totalProfit: totalProfit,
      lowStockProducts: lowStock,
      lowRawMaterials: lowRaw,
      brandSales: brandSales,
      salesTrend: salesTrend,
    );
  }
}
