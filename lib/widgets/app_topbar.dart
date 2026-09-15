import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser;
    final nowFormatted = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final companyName = data.company.name;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: isMobile ? 54 : 56,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
            child: Row(
              children: [
                // Mobile Drawer Menu Button
                if (!isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.text),
                      onPressed: onToggleSidebar ?? () {
                        Scaffold.maybeOf(context)?.openDrawer();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
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

          // Notification Bell icon
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, size: 20, color: AppColors.text2),
            onPressed: () {},
            tooltip: 'Notifications',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                              user.roleLabel,
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
    ),
        ),
      ),
    );
  }
}
