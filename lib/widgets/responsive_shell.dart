import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'app_drawer.dart';
import 'app_topbar.dart';

class ResponsiveShell extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final Widget child;

  const ResponsiveShell({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.child,
  });

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  bool _forceDesktop = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _getMobileNavIndex(String route) {
    switch (route) {
      case 'dashboard':
        return 0;
      case 'counter':
      case 'nongst_counter':
      case 'erp_billing':
      case 'gst_billing':
      case 'nongst_billing':
      case 'non_gst_billing':
        return 1;
      case 'inventory':
      case 'products':
        return 2;
      case 'billing_history':
      case 'nongst_history':
      case 'non_gst_history':
        return 3;
      default:
        return 4; // 'more'
    }
  }

  void _onMobileNavTapped(int index) {
    final auth = context.read<AuthProvider>();
    final isNonGst = auth.currentUser?.isNonGstMode ?? false;

    switch (index) {
      case 0:
        widget.onNavigate('dashboard');
        break;
      case 1:
        widget.onNavigate(isNonGst ? 'nongst_billing' : 'erp_billing');
        break;
      case 2:
        widget.onNavigate('inventory');
        break;
      case 3:
        widget.onNavigate(isNonGst ? 'nongst_history' : 'billing_history');
        break;
      case 4:
        _showMobileMoreSheet(context);
        break;
    }
  }

  void _showMobileMoreSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isNonGst = auth.currentUser?.isNonGstMode ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All ERP Modules',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.forestDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                // Active Session Info Card in More Sheet
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.forestMedium,
                        child: Text(
                          auth.currentUser?.name.isNotEmpty == true ? auth.currentUser!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.name ?? 'User',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            Text(
                              '${auth.currentUser?.role ?? "Staff"} · ${isNonGst ? "Non-GST Station" : "Billing Station"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isNonGst ? AppColors.goldDeep : AppColors.forestMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isNonGst && auth.isSuperAdmin)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  auth.toggleNonGstMode();
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldSoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.gold),
                                  ),
                                  child: const Text(
                                    'Switch GST',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.forestDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.logout, size: 14, color: Colors.white),
                            label: const Text('Log Out', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 32),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              auth.logout();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (auth.can('billing')) ...[
                        _buildMoreGridItem(ctx, 'counter', 'POS Counter Billing', Icons.point_of_sale_outlined, 'Fast-Click POS Grid'),
                        _buildMoreGridItem(ctx, 'erp_billing', 'Billing Voucher', Icons.receipt_long, 'Full A4 Invoice'),
                      ],
                      if (isNonGst && auth.isSuperAdmin) ...[
                        _buildMoreGridItem(ctx, 'nongst_counter', 'Non-GST POS Counter', Icons.point_of_sale_outlined, 'Fast-Click Non-GST POS'),
                        _buildMoreGridItem(ctx, 'nongst_billing', 'Non-GST Voucher', Icons.receipt, 'Executive Bill'),
                        _buildMoreGridItem(ctx, 'nongst_history', 'Non-GST History', Icons.manage_history_outlined, 'Executive Records'),
                      ],
                      if (auth.can('products'))
                        _buildMoreGridItem(ctx, 'products', 'Products', Icons.inventory_2_outlined, 'Rates & Stock'),
                      if (auth.can('price_management'))
                        _buildMoreGridItem(ctx, 'price_management', 'Price Management', Icons.price_change_outlined, 'Wholesale/Retail Rates'),
                      if (auth.can('price_history'))
                        _buildMoreGridItem(ctx, 'price_history', 'Price Audit History', Icons.history_edu_outlined, 'Past Revisions'),
                      if (auth.can('customers'))
                        _buildMoreGridItem(ctx, 'customers', 'Customers', Icons.people_outline, 'Ledgers & Balances'),
                      if (auth.can('suppliers'))
                        _buildMoreGridItem(ctx, 'suppliers', 'Suppliers', Icons.business_outlined, 'Dues & Raw Materials'),
                      if (auth.can('production'))
                        _buildMoreGridItem(ctx, 'production', 'Production Milling', Icons.precision_manufacturing_outlined, 'Crushing Runs'),
                      if (auth.can('purchase'))
                        _buildMoreGridItem(ctx, 'purchase', 'Purchase & Inward', Icons.shopping_cart_outlined, 'Inward Seeds & Tins'),
                      if (auth.can('logistics'))
                        _buildMoreGridItem(ctx, 'logistics', 'Logistics & Dispatch', Icons.local_shipping_outlined, 'Vehicles & Gate Passes'),
                      if (auth.can('reports'))
                        _buildMoreGridItem(ctx, 'reports', 'Reports & Analytics', Icons.bar_chart_outlined, 'Turnover & GST Summary'),
                      if (auth.can('employees'))
                        _buildMoreGridItem(ctx, 'employees', 'Employees & Roles', Icons.badge_outlined, 'Staff Accounts'),
                      if (auth.can('settings'))
                        _buildMoreGridItem(ctx, 'settings', 'Company Settings', Icons.settings_outlined, 'Profile & Master Reset'),
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: AppColors.danger),
                          title: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                          onTap: () {
                            Navigator.pop(ctx);
                            auth.logout();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMoreGridItem(
    BuildContext ctx,
    String route,
    String title,
    IconData icon,
    String desc,
  ) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.goldSoft.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.forestMedium, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: () {
          Navigator.pop(ctx);
          widget.onNavigate(route);
        },
      ),
    );
  }

  String _getPageTitle(String route) {
    switch (route) {
      case 'dashboard':
        return 'Dashboard Overview';
      case 'erp_billing':
      case 'counter':
        return 'Billing Voucher';
      case 'nongst_billing':
        return 'Non-GST Billing Voucher';
      case 'billing_history':
        return 'Billing History';
      case 'nongst_history':
        return 'Non-GST Bills History';
      case 'products':
        return 'Products Master';
      case 'price_management':
        return 'Price Management';
      case 'price_history':
        return 'Price Audit History';
      case 'inventory':
        return 'Inventory & Stock Valuation';
      case 'production':
        return 'Production Milling';
      case 'purchase':
        return 'Purchase & Inward';
      case 'logistics':
        return 'Logistics & Dispatch';
      case 'customers':
        return 'Customers Directory';
      case 'suppliers':
        return 'Suppliers Directory';
      case 'reports':
        return 'Reports & Analytics';
      case 'employees':
        return 'Employees & Staff Roles';
      case 'settings':
        return 'Company Settings';
      default:
        return 'KKK Oil ERP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopLayout = (screenWidth >= 900 || _forceDesktop);

    if (!isDesktopLayout) {
      // Mobile Layout with Bottom Navigation Bar & Drawer
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: AppDrawer(
          currentRoute: widget.currentRoute,
          onSelectRoute: (route) {
            _scaffoldKey.currentState?.closeDrawer();
            widget.onNavigate(route);
          },
        ),
        appBar: AppTopbar(
          title: _getPageTitle(widget.currentRoute),
          isDesktop: false,
          forceDesktop: _forceDesktop,
          onToggleSidebar: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          onToggleForceDesktop: () {
            setState(() {
              _forceDesktop = !_forceDesktop;
            });
          },
        ),
        body: SafeArea(
          top: false,
          child: Material(
            color: AppColors.background,
            child: widget.child,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _getMobileNavIndex(widget.currentRoute),
          onTap: _onMobileNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.forestMedium,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Billing',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warehouse_outlined),
              activeIcon: Icon(Icons.warehouse),
              label: 'Stock',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      );
    }

    // Desktop / Tablet Layout with Sidebar Drawer
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AppDrawer(
            currentRoute: widget.currentRoute,
            onSelectRoute: widget.onNavigate,
          ),
          Expanded(
            child: Column(
              children: [
                AppTopbar(
                  title: _getPageTitle(widget.currentRoute),
                  isDesktop: true,
                  forceDesktop: _forceDesktop,
                  onToggleForceDesktop: () {
                    setState(() {
                      _forceDesktop = !_forceDesktop;
                    });
                  },
                ),
                Expanded(
                  child: Material(
                    color: AppColors.background,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
