import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onSelectRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onSelectRoute,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser;
    final isNonGst = user?.isNonGstMode ?? false;
    final companyName = data.company.name.isNotEmpty ? data.company.name : 'KKK Oil Factory';

    return Container(
      width: 244,
      decoration: BoxDecoration(
        color: isNonGst ? const Color(0xFF121815) : AppColors.forestDark,
        border: const Border(right: BorderSide(color: Color(0xFF0C1A14))),
      ),
      child: Column(
        children: [
          // Sidebar Brand Header matching .sb-brand
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.gold, AppColors.goldDeep],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'KKK',
                      style: TextStyle(
                        color: AppColors.forestDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isNonGst ? 'Non-GST Station · ERP' : '${data.company.state.isNotEmpty ? data.company.state : "Tamil Nadu"} · ERP',
                        style: TextStyle(
                          color: isNonGst ? AppColors.gold : const Color(0xFF8FA298),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links matching .sb-nav
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
              children: [
                _buildSectionHeader('MAIN'),
                if (auth.can('dashboard') && !auth.isCashier)
                  _buildNavItem(context, 'dashboard', 'Dashboard', Icons.dashboard_outlined),

                _buildSectionHeader('GST BILLING & OPERATIONS'),
                if (auth.can('billing')) ...[
                  _buildNavItem(context, 'erp_billing', 'GST Billing Voucher', Icons.receipt_long_outlined),
                  _buildNavItem(context, 'billing_history', 'GST Invoices History', Icons.history_outlined),
                ],
                if (auth.can('products'))
                  _buildNavItem(context, 'products', 'Product Master', Icons.inventory_2_outlined),
                if (auth.can('price_management'))
                  _buildNavItem(context, 'price_management', 'Price Management', Icons.edit_note_outlined),
                if (auth.can('price_history'))
                  _buildNavItem(context, 'price_history', 'Price History', Icons.history_edu_outlined),
                if (auth.can('inventory'))
                  _buildNavItem(context, 'inventory', 'Inventory', Icons.warehouse_outlined),
                if (auth.can('purchase'))
                  _buildNavItem(context, 'purchase', 'Purchase', Icons.shopping_cart_outlined),
                if (auth.can('production'))
                  _buildNavItem(context, 'production', 'Production', Icons.precision_manufacturing_outlined),

                // Non-GST billing strictly shown to Super Admin only in active Non-GST session
                if (isNonGst && auth.isSuperAdmin) ...[
                  _buildSectionHeader('NON-GST BILLING (SUPER ADMIN)'),
                  _buildNavItem(context, 'nongst_billing', 'Non-GST Billing Voucher', Icons.receipt_outlined, isSpecial: true),
                  _buildNavItem(context, 'nongst_history', 'Non-GST History', Icons.manage_history_outlined, isSpecial: true),
                ],

                _buildSectionHeader('PEOPLE & SETTINGS'),
                if (auth.can('customers'))
                  _buildNavItem(context, 'customers', 'Customers Directory', Icons.people_outline),
                if (auth.can('suppliers'))
                  _buildNavItem(context, 'suppliers', 'Suppliers Directory', Icons.business_outlined),
                if (auth.can('reports'))
                  _buildNavItem(context, 'reports', 'Reports & Analytics', Icons.bar_chart_outlined),
                if (auth.can('employees'))
                  _buildNavItem(context, 'employees', 'Employees & Roles', Icons.badge_outlined),
                if (auth.can('settings'))
                  _buildNavItem(context, 'settings', 'Company Settings', Icons.settings_outlined),
              ],
            ),
          ),

          // User Footer matching .sb-foot and user chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.gold,
                  child: Text(
                    user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.forestDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.roleLabel ?? 'Staff',
                        style: const TextStyle(
                          color: Color(0xFF8FA298),
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF8FA298), size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => auth.logout(),
                  tooltip: 'Sign Out',
                ),
              ],
            ),
          ),
          // Sub-foot version label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
            child: const Text(
              'v2.0 Professional ERP · © 2026 KKK Oils',
              style: TextStyle(
                color: Color(0xFF6F8276),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 14, bottom: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6F8276),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String route,
    String label,
    IconData icon, {
    bool isSpecial = false,
  }) {
    final isSelected = currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? (isSpecial
                ? LinearGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.28),
                      AppColors.gold.withOpacity(0.10),
                    ],
                  )
                : AppColors.activeNavGradient)
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.06),
          onTap: () => onSelectRoute(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.gold
                      : (isSpecial ? AppColors.gold.withOpacity(0.7) : const Color(0xFFB6C4BA)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFB6C4BA),
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSpecial)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
