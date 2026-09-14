import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:kkk_oil_erp_flutter/main.dart';
import 'package:kkk_oil_erp_flutter/providers/auth_provider.dart';
import 'package:kkk_oil_erp_flutter/providers/data_provider.dart';
import 'package:kkk_oil_erp_flutter/screens/dashboard_screen.dart';
import 'package:kkk_oil_erp_flutter/screens/erp_billing_screen.dart';
import 'package:kkk_oil_erp_flutter/screens/login_screen.dart';
import 'package:kkk_oil_erp_flutter/screens/products_screen.dart';
import 'package:kkk_oil_erp_flutter/theme/app_theme.dart';

Widget _buildTestWrapper({
  required Widget child,
  AuthProvider? authProvider,
  DataProvider? dataProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? AuthProvider(),
      ),
      ChangeNotifierProvider<DataProvider>.value(
        value: dataProvider ?? DataProvider(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test builds MaterialApp without exception', (WidgetTester tester) async {
    await tester.pumpWidget(const KkkOilErpApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  group('Mobile Viewport Tests (Zero Overflow across 360px - 412px)', () {
    const mobileSizes = [
      Size(360, 640), // Compact Android
      Size(390, 844), // Modern iPhone (12/13/14/15)
      Size(412, 915), // Standard Android (Pixel/Samsung)
    ];

    for (final size in mobileSizes) {
      testWidgets('LoginScreen renders without overflow on ${size.width.toInt()}x${size.height.toInt()}', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestWrapper(child: const LoginScreen()),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('KKK Oil'), findsWidgets);
        expect(find.textContaining('Super Admin (GST Login)'), findsOneWidget);
        expect(find.textContaining('Super Admin (Non-GST Login)'), findsOneWidget);
      });

      testWidgets('DashboardScreen renders without overflow on ${size.width.toInt()}x${size.height.toInt()}', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final auth = AuthProvider();
        final data = DataProvider();
        await auth.login('admin', 'admin123');

        await tester.pumpWidget(
          _buildTestWrapper(
            authProvider: auth,
            dataProvider: data,
            child: DashboardScreen(onNavigate: (_) {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Amount Sold'), findsOneWidget);
      });

      testWidgets('ErpBillingScreen renders without overflow on ${size.width.toInt()}x${size.height.toInt()}', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final auth = AuthProvider();
        final data = DataProvider();
        await auth.login('admin', 'admin123');

        await tester.pumpWidget(
          _buildTestWrapper(
            authProvider: auth,
            dataProvider: data,
            child: const ErpBillingScreen(forcedBillingType: 'GST'),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('SALES INVOICE VOUCHER'), findsOneWidget);
        expect(find.text('Save (F2)'), findsOneWidget);
        expect(find.text('Save & Print'), findsOneWidget);
      });

      testWidgets('ProductsScreen renders without overflow on ${size.width.toInt()}x${size.height.toInt()}', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final auth = AuthProvider();
        final data = DataProvider();

        await tester.pumpWidget(
          _buildTestWrapper(
            authProvider: auth,
            dataProvider: data,
            child: const ProductsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Product Master'), findsOneWidget);
      });
    }
  });
}
