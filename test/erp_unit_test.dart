import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkk_oil_erp_flutter/data/seed_data.dart';
import 'package:kkk_oil_erp_flutter/models/product.dart';
import 'package:kkk_oil_erp_flutter/models/sales_order.dart';
import 'package:kkk_oil_erp_flutter/models/user.dart';
import 'package:kkk_oil_erp_flutter/providers/auth_provider.dart';
import 'package:kkk_oil_erp_flutter/providers/data_provider.dart';
import 'package:kkk_oil_erp_flutter/services/pdf_invoice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Authentication & Dual-Mode Tests', () {
    test('Standard GST login with admin123 succeeds in GST mode', () async {
      final auth = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = await auth.login('admin', 'admin123');
      expect(res['ok'], isTrue);
      expect(res['mode'], 'GST');
      expect(auth.currentUser?.activeMode, BillingMode.gst);
      expect(auth.isSuperAdmin, isTrue);
      expect(auth.isNonGstSession, isFalse);
    });

    test('Non-GST login with admin123n unlocks Non-GST executive session', () async {
      final auth = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = await auth.login('admin', 'admin123n');
      expect(res['ok'], isTrue);
      expect(res['mode'], 'NON_GST');
      expect(auth.currentUser?.activeMode, BillingMode.nonGst);
      expect(auth.isNonGstSession, isTrue);
    });

    test('Cashier cannot login into Non-GST mode', () async {
      final auth = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = await auth.login('cashier', 'admin123n');
      expect(res['ok'], isFalse);
      expect(res['error'], contains('strictly restricted'));
    });
  });

  group('Billing, Stock Deduction & Numbering Tests', () {
    test('Saving a sales order deducts stock immediately', () async {
      final data = DataProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final initialProduct = data.products.firstWhere((p) => p.id == 'P01');
      final initialStock = initialProduct.stock;

      const orderItem = InvoiceItem(
        productId: 'P01',
        productCode: 'PRD-101',
        productName: 'KKK Gold Groundnut Oil 1L',
        unit: 'Bottle',
        qty: 10.0,
        rate: 198.0,
        mrp: 215.0,
        pricingType: PricingType.retail,
        appliedRate: 198.0,
        taxableAmount: 1885.71,
        gstRate: 5.0,
        gstAmount: 94.29,
        finalAmount: 1980.0,
      );

      final user = UserSession(
        id: 'U-test',
        username: 'admin',
        name: 'Super Admin',
        role: 'super_admin',
        roleLabel: 'Super Admin',
        access: '*',
      );

      final voucherNo = data.generateNextVoucherNo('GST');
      expect(voucherNo, startsWith('GST-2627-'));

      final order = SalesOrder(
        id: 'SO-TEST-1',
        voucherNo: voucherNo,
        voucherType: 'GST Invoice',
        billingType: 'GST',
        pricingType: PricingType.retail,
        customerId: 'C01',
        date: '2026-03-12',
        time: '12:00:00',
        salesperson: 'Admin',
        items: const [orderItem],
        subtotal: 1885.71,
        gstTotal: 94.29,
        grandTotal: 1980.0,
        createdAt: DateTime.now().toIso8601String(),
      );

      await data.saveSalesOrder(order: order, user: user);

      final updatedProduct = data.products.firstWhere((p) => p.id == 'P01');
      expect(updatedProduct.stock, equals(initialStock - 10.0));

      // Test cancel order restores stock
      await data.cancelSalesOrder(orderId: order.id, reason: 'Test cancel', user: user);
      final restoredProduct = data.products.firstWhere((p) => p.id == 'P01');
      expect(restoredProduct.stock, equals(initialStock));
    });
  });

  group('PDF Invoice Generation Test', () {
    test('generateInvoicePdf generates valid PDF binary bytes', () async {
      final data = DataProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final sampleOrder = SeedData.getInitialSales()[0];
      final bytes = await PdfInvoiceService.generateInvoicePdf(
        order: sampleOrder,
        company: data.company,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });

  group('Session Persistence & URL Routing Tests', () {
    test('UserSession toMap and fromMap serialization round-trips correctly', () {
      const session = UserSession(
        id: 'U-super',
        username: 'admin',
        name: 'Super Administrator',
        role: 'super_admin',
        roleLabel: 'Super Admin',
        access: '*',
        activeMode: BillingMode.gst,
      );

      final map = session.toMap();
      expect(map['username'], 'admin');
      expect(map['activeMode'], 'gst');

      final restored = UserSession.fromMap(map);
      expect(restored.id, session.id);
      expect(restored.username, session.username);
      expect(restored.role, session.role);
      expect(restored.activeMode, BillingMode.gst);
    });

    test('Login persists user session in SharedPreferences and reloads it', () async {
      final auth = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = await auth.login('admin', 'admin123');
      expect(res['ok'], isTrue);

      // Create a fresh AuthProvider simulating a browser reload
      final reloadedAuth = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(reloadedAuth.isAuthenticated, isTrue);
      expect(reloadedAuth.currentUser?.username, 'admin');
      expect(reloadedAuth.currentUser?.role, 'super_admin');
    });

    test('Logout clears persisted session so reload starts unauthenticated', () async {
      final auth = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await auth.login('admin', 'admin123');
      auth.logout();

      final reloadedAuth = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(reloadedAuth.isAuthenticated, isFalse);
      expect(reloadedAuth.currentUser, isNull);
    });
  });
}
