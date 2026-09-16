import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _productsKey = 'kkk_flutter_products_v1';
  static const String _brandsKey = 'kkk_flutter_brands_v1';
  static const String _customersKey = 'kkk_flutter_customers_v1';
  static const String _suppliersKey = 'kkk_flutter_suppliers_v1';
  static const String _salesKey = 'kkk_flutter_sales_v1';
  static const String _rawMaterialsKey = 'kkk_flutter_raw_materials_v1';
  static const String _purchasesKey = 'kkk_flutter_purchases_v1';
  static const String _productionKey = 'kkk_flutter_production_v1';
  static const String _dispatchesKey = 'kkk_flutter_dispatches_v1';
  static const String _expensesKey = 'kkk_flutter_expenses_v1';
  static const String _usersKey = 'kkk_flutter_users_v1';
  static const String _rolesKey = 'kkk_flutter_roles_v1';
  static const String _deletedUsersKey = 'kkk_flutter_deleted_users_v1';
  static const String _deletedRolesKey = 'kkk_flutter_deleted_roles_v1';
  static const String _companyKey = 'kkk_flutter_company_v1';
  static const String _priceHistoryKey = 'kkk_flutter_price_history_v1';
  static const String _auditLogsKey = 'kkk_flutter_audit_logs_v1';
  static const String _userSessionKey = 'kkk_flutter_user_session_v1';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>?> loadList(String key) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveObject(String key, Map<String, dynamic> obj) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, jsonEncode(obj));
  }

  static Future<Map<String, dynamic>?> loadObject(String key) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  // Specific persistence helpers
  static Future<void> saveProducts(List<Map<String, dynamic>> list) => saveList(_productsKey, list);
  static Future<List<Map<String, dynamic>>?> loadProducts() => loadList(_productsKey);

  static Future<void> saveBrands(List<Map<String, dynamic>> list) => saveList(_brandsKey, list);
  static Future<List<Map<String, dynamic>>?> loadBrands() => loadList(_brandsKey);

  static Future<void> saveCustomers(List<Map<String, dynamic>> list) => saveList(_customersKey, list);
  static Future<List<Map<String, dynamic>>?> loadCustomers() => loadList(_customersKey);

  static Future<void> saveSuppliers(List<Map<String, dynamic>> list) => saveList(_suppliersKey, list);
  static Future<List<Map<String, dynamic>>?> loadSuppliers() => loadList(_suppliersKey);

  static Future<void> saveSales(List<Map<String, dynamic>> list) => saveList(_salesKey, list);
  static Future<List<Map<String, dynamic>>?> loadSales() => loadList(_salesKey);

  static Future<void> saveRawMaterials(List<Map<String, dynamic>> list) => saveList(_rawMaterialsKey, list);
  static Future<List<Map<String, dynamic>>?> loadRawMaterials() => loadList(_rawMaterialsKey);

  static Future<void> savePurchases(List<Map<String, dynamic>> list) => saveList(_purchasesKey, list);
  static Future<List<Map<String, dynamic>>?> loadPurchases() => loadList(_purchasesKey);

  static Future<void> saveProduction(List<Map<String, dynamic>> list) => saveList(_productionKey, list);
  static Future<List<Map<String, dynamic>>?> loadProduction() => loadList(_productionKey);

  static Future<void> saveDispatches(List<Map<String, dynamic>> list) => saveList(_dispatchesKey, list);
  static Future<List<Map<String, dynamic>>?> loadDispatches() => loadList(_dispatchesKey);

  static Future<void> saveExpenses(List<Map<String, dynamic>> list) => saveList(_expensesKey, list);
  static Future<List<Map<String, dynamic>>?> loadExpenses() => loadList(_expensesKey);

  static Future<void> saveUsers(List<Map<String, dynamic>> list) => saveList(_usersKey, list);
  static Future<List<Map<String, dynamic>>?> loadUsers() => loadList(_usersKey);

  static Future<void> saveRoles(List<Map<String, dynamic>> list) => saveList(_rolesKey, list);
  static Future<List<Map<String, dynamic>>?> loadRoles() => loadList(_rolesKey);

  static Future<void> saveDeletedUsers(List<String> list) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(_deletedUsersKey, list);
  }

  static Future<List<String>> loadDeletedUsers() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_deletedUsersKey) ?? [];
  }

  static Future<void> saveDeletedRoles(List<String> list) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(_deletedRolesKey, list);
  }

  static Future<List<String>> loadDeletedRoles() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_deletedRolesKey) ?? [];
  }

  static Future<void> saveCompany(Map<String, dynamic> obj) => saveObject(_companyKey, obj);
  static Future<Map<String, dynamic>?> loadCompany() => loadObject(_companyKey);

  static Future<void> savePriceHistory(List<Map<String, dynamic>> list) => saveList(_priceHistoryKey, list);
  static Future<List<Map<String, dynamic>>?> loadPriceHistory() => loadList(_priceHistoryKey);

  static Future<void> saveAuditLogs(List<Map<String, dynamic>> list) => saveList(_auditLogsKey, list);
  static Future<List<Map<String, dynamic>>?> loadAuditLogs() => loadList(_auditLogsKey);

  static Future<void> saveUserSession(Map<String, dynamic>? session) async {
    final prefs = await _getPrefs();
    if (session == null) {
      await prefs.remove(_userSessionKey);
    } else {
      await prefs.setString(_userSessionKey, jsonEncode(session));
    }
  }

  static Future<Map<String, dynamic>?> loadUserSession() => loadObject(_userSessionKey);

  static Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}
