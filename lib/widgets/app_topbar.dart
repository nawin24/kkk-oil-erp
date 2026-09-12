import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';

class AppTopbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onToggleSidebar;
  final bool isDesktop;
  final bool forceDesktop;
  final VoidCallback? onToggleForceDesktop;

  const AppTopbar({
    super.key,
    required this.title,
    this.onToggleSidebar,
    this.isDesktop = true,
    this.forceDesktop = false,
    this.onToggleForceDesktop,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  void _showModeSwitchDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final passCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isGst = auth.currentUser?.activeMode == BillingMode.gst;
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isGst ? Icons.lock_outline : Icons.check_circle_outline,
                  color: isGst ? AppColors.goldDeep : AppColors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  isGst ? 'Switch to Non-GST Station' : 'Switch to GST Billing Station',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGst
                      ? 'Non-GST Mode is restricted to Super Admin executive access only. Enter executive password (e.g. admin123n or ERP@2026N):'
                      : 'Switch back to public GST Invoicing station? All GST invoice sequences and reporting will apply.',
                  style: const TextStyle(fontSize: 13, color: AppColors.text2),
                ),
                if (isGst) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Executive Password',
                      hintText: 'admin123n',
                      errorText: error,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGst ? AppColors.gold : AppColors.forest,
                  foregroundColor: isGst ? AppColors.forest : Colors.white,
                ),
                onPressed: () async {
                  if (isGst) {
                    final res = await auth.switchMode(passCtrl.text);
                    if (res['ok'] == true) {
                      if (ctx.mounted) Navigator.pop(ctx);
                    } else {
                      setState(() {
                        error = res['error'] ?? 'Incorrect password';
                      });
                    }
                  } else {
                    auth.switchModeToGst();
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: Text(isGst ? 'Unlock Non-GST' : 'Switch to GST'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser;
    final isNonGst = auth.isNonGstSession;
    final nowFormatted = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final companyName = data.company.name;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      height: isMobile ? 58 : 62,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Mobile Drawer Menu Button
          if (!isDesktop && onToggleSidebar != null)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.text),
              onPressed: onToggleSidebar,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

          // Title & Crumb
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: isMobile ? 14.5 : 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  isMobile ? nowFormatted : '$companyName · $nowFormatted',
                  style: const TextStyle(
                    color: AppColors.text3,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Search Bar (Desktop)
          if (isDesktop && screenWidth > 900) ...[
            Container(
              width: 320,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 16, color: AppColors.text3),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search orders, products, customers…',
                        hintStyle: TextStyle(color: AppColors.text3, fontSize: 13),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Mode Switch Pill (GST vs NON-GST)
          InkWell(
            onTap: user?.isSuperAdmin == true ? () => _showModeSwitchDialog(context) : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 10,
                vertical: isMobile ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: isNonGst ? AppColors.goldSoft : AppColors.greenSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isNonGst ? AppColors.goldDeep : AppColors.green,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNonGst ? AppColors.goldDeep : AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isNonGst ? 'NON-GST' : 'GST',
                    style: TextStyle(
                      color: isNonGst ? AppColors.goldDeep : AppColors.green,
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (user?.isSuperAdmin == true) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.swap_horiz, size: 13, color: isNonGst ? AppColors.goldDeep : AppColors.green),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // User Profile Chip
          if (user != null)
            Tooltip(
              message: 'Signed in as ${user.name}',
              child: InkWell(
                onTap: () => auth.logout(),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              isNonGst ? 'Super Admin (Non-GST)' : user.roleLabel,
                              style: const TextStyle(
                                color: AppColors.text3,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Sign Out Icon Button
          IconButton(
            icon: const Icon(Icons.logout, size: 18, color: AppColors.text3),
            tooltip: 'Sign Out',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}
