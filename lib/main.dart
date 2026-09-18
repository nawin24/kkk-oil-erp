import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'utils/url_strategy.dart';
import 'widgets/responsive_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  configureUrlStrategy();
  runApp(const KkkOilErpApp());
}

/// Translates internal route names to clean URL paths
String routeToPath(String route) {
  switch (route) {
    case 'dashboard':
      return '/dashboard';
    case 'erp_billing':
    case 'gst_billing':
    case 'billing':
      return '/billing';
    case 'counter':
      return '/counter';
    case 'billing_history':
      return '/billing-history';
    case 'nongst_billing':
    case 'non_gst_billing':
      return '/nongst-billing';
    case 'nongst_counter':
      return '/nongst-counter';
    case 'nongst_history':
    case 'non_gst_history':
      return '/nongst-history';
    case 'products':
      return '/products';
    case 'price_management':
      return '/price-management';
    case 'price_history':
      return '/price-history';
    case 'inventory':
      return '/inventory';
    case 'production':
      return '/production';
    case 'purchase':
      return '/purchase';
    case 'logistics':
      return '/logistics';
    case 'customers':
      return '/customers';
    case 'suppliers':
      return '/suppliers';
    case 'reports':
      return '/reports';
    case 'employees':
      return '/employees';
    case 'settings':
      return '/settings';
    case 'login':
      return '/login';
    default:
      return '/$route';
  }
}

/// Translates URL path string (with or without hash) into internal route name
String pathToRoute(String path) {
  var clean = path.trim();
  if (clean.startsWith('#/')) clean = clean.substring(2);
  if (clean.startsWith('#')) clean = clean.substring(1);
  if (clean.startsWith('/')) clean = clean.substring(1);
  if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);

  switch (clean.toLowerCase()) {
    case '':
    case 'dashboard':
      return 'dashboard';
    case 'billing':
    case 'erp-billing':
    case 'erp_billing':
    case 'gst-billing':
    case 'gst_billing':
      return 'erp_billing';
    case 'counter':
    case 'pos':
      return 'counter';
    case 'billing-history':
    case 'billing_history':
    case 'bills':
      return 'billing_history';
    case 'nongst-billing':
    case 'nongst_billing':
    case 'non-gst-billing':
    case 'non_gst_billing':
      return 'nongst_billing';
    case 'nongst-counter':
    case 'nongst_counter':
      return 'nongst_counter';
    case 'nongst-history':
    case 'nongst_history':
    case 'non-gst-history':
    case 'non_gst_history':
      return 'nongst_history';
    case 'products':
    case 'product':
      return 'products';
    case 'price-management':
    case 'price_management':
    case 'pricing':
      return 'price_management';
    case 'price-history':
    case 'price_history':
      return 'price_history';
    case 'inventory':
    case 'stock':
      return 'inventory';
    case 'production':
    case 'milling':
      return 'production';
    case 'purchase':
    case 'inward':
      return 'purchase';
    case 'logistics':
    case 'dispatch':
      return 'logistics';
    case 'customers':
      return 'customers';
    case 'suppliers':
      return 'suppliers';
    case 'reports':
    case 'analytics':
      return 'reports';
    case 'employees':
    case 'staff':
      return 'employees';
    case 'settings':
      return 'settings';
    case 'login':
      return 'login';
    default:
      return clean.replaceAll('-', '_');
  }
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
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final path = settings.name ?? '/';
          final route = pathToRoute(path);
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => AuthGate(requestedRoute: route),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final String? requestedRoute;

  const AuthGate({super.key, this.requestedRoute});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  String _currentRoute = 'dashboard';
  String? _intendedRoute;
  bool _routeInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final requested = widget.requestedRoute;
    if (requested != null && requested.isNotEmpty && requested != 'dashboard') {
      _currentRoute = requested;
      _routeInitialized = true;
    } else {
      final defaultPath = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      if (defaultPath.isNotEmpty && defaultPath != '/' && defaultPath != '/dashboard') {
        _currentRoute = pathToRoute(defaultPath);
        _routeInitialized = true;
      }
    }
  }

  @override
  void didUpdateWidget(AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestedRoute != null &&
        widget.requestedRoute!.isNotEmpty &&
        widget.requestedRoute != oldWidget.requestedRoute &&
        widget.requestedRoute != _currentRoute) {
      setState(() {
        _currentRoute = widget.requestedRoute!;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final path = routeInformation.uri.path;
    if (path.isNotEmpty) {
      final route = pathToRoute(path);
      if (route != _currentRoute) {
        setState(() {
          _currentRoute = route;
        });
      }
    }
    return true;
  }

  void _onNavigate(String route) {
    if (_currentRoute != route) {
      setState(() {
        _currentRoute = route;
      });
    }
    _updateWebUrl(route);
  }

  void _updateWebUrl(String route) {
    try {
      final path = routeToPath(route);
      SystemNavigator.routeInformationUpdated(uri: Uri.parse(path));
    } catch (_) {}
  }

  Widget _buildScreen(String route, BuildContext context) {
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
        return const CounterScreen(billingType: 'NON_GST');
      case 'billing_history':
        return const BillingHistoryScreen(forcedBillingType: 'GST');
      case 'nongst_billing':
      case 'non_gst_billing':
        return const ErpBillingScreen(forcedBillingType: 'NON_GST');
      case 'nongst_history':
      case 'non_gst_history':
        return const BillingHistoryScreen(forcedBillingType: 'NON_GST');
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
      case 'login':
        return const LoginScreen();
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
      if (_currentRoute != 'login') {
        _intendedRoute = _currentRoute;
      }
      _routeInitialized = false;
      _updateWebUrl('login');
      return const LoginScreen();
    }

    // If authenticated user specifically went to /login, show LoginScreen
    if (_currentRoute == 'login') {
      return const LoginScreen();
    }

    if (!_routeInitialized) {
      if (_intendedRoute != null &&
          _intendedRoute!.isNotEmpty &&
          _intendedRoute != 'login') {
        _currentRoute = _intendedRoute!;
        _intendedRoute = null;
      } else if (widget.requestedRoute != null &&
          widget.requestedRoute!.isNotEmpty &&
          widget.requestedRoute != 'dashboard' &&
          widget.requestedRoute != 'login') {
        _currentRoute = widget.requestedRoute!;
      } else if (auth.isCashier) {
        _currentRoute = 'erp_billing';
      } else if (auth.currentUser?.role == 'production_staff') {
        _currentRoute = 'production';
      } else if (auth.currentUser?.role == 'logistics_staff') {
        _currentRoute = 'logistics';
      } else {
        _currentRoute = 'dashboard';
      }
      _routeInitialized = true;
      _updateWebUrl(_currentRoute);
    }

    return ResponsiveShell(
      currentRoute: _currentRoute,
      onNavigate: _onNavigate,
      child: _buildScreen(_currentRoute, context),
    );
  }
}
