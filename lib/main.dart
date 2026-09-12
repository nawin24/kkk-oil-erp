import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/billing_history_screen.dart';
import 'screens/counter_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/erp_billing_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/login_screen.dart';
import 'screens/logistics_screen.dart';
import 'screens/price_history_screen.dart';
import 'screens/price_management_screen.dart';
import 'screens/production_screen.dart';
import 'screens/products_screen.dart';
import 'screens/purchase_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/suppliers_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/responsive_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KkkOilErpApp());
}

class KkkOilErpApp extends StatelessWidget {
  const KkkOilErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        title: 'KKK Oil Factory ERP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String _currentRoute = 'dashboard';
  bool _routeInitialized = false;

  void _onNavigate(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  Widget _buildScreen(String route, BuildContext context) {
    final auth = context.read<AuthProvider>();

    switch (route) {
      case 'dashboard':
        return DashboardScreen(onNavigate: _onNavigate);
      case 'erp_billing':
      case 'gst_billing':
      case 'billing':
        return const ErpBillingScreen(forcedBillingType: 'GST');
      case 'counter':
        return const CounterScreen(billingType: 'GST');
      case 'nongst_counter':
        return auth.isSuperAdmin ? const CounterScreen(billingType: 'NON_GST') : const CounterScreen(billingType: 'GST');
      case 'billing_history':
        return const BillingHistoryScreen(forcedBillingType: 'GST');
      case 'nongst_billing':
        return auth.isSuperAdmin ? const ErpBillingScreen(forcedBillingType: 'NON_GST') : const ErpBillingScreen(forcedBillingType: 'GST');
      case 'nongst_history':
        return auth.isSuperAdmin ? const BillingHistoryScreen(forcedBillingType: 'NON_GST') : const BillingHistoryScreen(forcedBillingType: 'GST');
      case 'products':
        return const ProductsScreen();
      case 'price_management':
        return PriceManagementScreen(onNavigate: _onNavigate);
      case 'price_history':
        return const PriceHistoryScreen();
      case 'inventory':
        return const InventoryScreen();
      case 'production':
        return const ProductionScreen();
      case 'purchase':
        return const PurchaseScreen();
      case 'logistics':
        return const LogisticsScreen();
      case 'customers':
        return const CustomersScreen();
      case 'suppliers':
        return const SuppliersScreen();
      case 'reports':
        return const ReportsScreen();
      case 'employees':
        return const EmployeesScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return DashboardScreen(onNavigate: _onNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.forestDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      _routeInitialized = false;
      return const LoginScreen();
    }

    if (!_routeInitialized) {
      if (auth.isCashier) {
        _currentRoute = 'erp_billing';
      } else if (auth.currentUser?.role == 'production_staff') {
        _currentRoute = 'production';
      } else if (auth.currentUser?.role == 'logistics_staff') {
        _currentRoute = 'logistics';
      } else {
        _currentRoute = 'dashboard';
      }
      _routeInitialized = true;
    }

    return ResponsiveShell(
      currentRoute: _currentRoute,
      onNavigate: _onNavigate,
      child: _buildScreen(_currentRoute, context),
    );
  }
}
