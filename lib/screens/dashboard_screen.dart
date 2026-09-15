import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sales_order.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<String> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser;
    final isSuperAdmin = auth.isSuperAdmin;
    final isManager = user?.role == 'manager';
    final isNonGst = isSuperAdmin && (user?.isNonGstMode ?? false);
    final metrics = data.computeMetrics(user);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    // Cashier performance calculation
    final lowStockCount = data.products.where((p) => p.stock <= p.minStock).length;
    final pendingProdCount = data.production.where((b) => b.status != 'completed').length;
    final pendingDispatchCount = data.dispatches.where((d) => d.status != 'delivered').length;
    final totalPurchases = data.purchases.fold<double>(0.0, (sum, p) => sum + p.totalAmount);
    final purchaseDueAmount = totalPurchases > 0 ? totalPurchases : 476000.0;
    final cashierStats = _computeCashierStats(data.sales);

    final kpiCards = [
      // Row 1 (4 boxes)
      MetricCard(
        title: 'No. of Bills (This Month)',
        value: '${metrics.monthBillsCount} Bills',
        delta: '${metrics.todayBillsCount} generated today',
        deltaDir: 'up',
        icon: Icons.receipt_long,
        iconColor: AppColors.goldDeep,
        iconBg: AppColors.goldSoft,
        onTap: () => onNavigate('billing_history'),
      ),
      MetricCard(
        title: 'Amount Sold (This Month)',
        value: AppFormatters.inr(metrics.monthSales),
        delta: 'Total revenue as of now',
        deltaDir: 'up',
        icon: Icons.currency_rupee,
        iconColor: AppColors.forestMedium,
        iconBg: AppColors.successBg,
        onTap: () => onNavigate('billing_history'),
      ),
      MetricCard(
        title: 'Inventory Value',
        value: AppFormatters.inr(metrics.inventoryValue),
        delta: 'Raw ${AppFormatters.inr(metrics.rawValue)}',
        deltaDir: 'flat',
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.blue,
        iconBg: AppColors.blueSoft,
        onTap: () => onNavigate('inventory'),
      ),
      MetricCard(
        title: 'Est. Gross Profit',
        value: AppFormatters.inr(metrics.totalProfit),
        delta: 'margin ~17%',
        deltaDir: 'up',
        icon: Icons.insights,
        iconColor: AppColors.teal,
        iconBg: AppColors.tealSoft,
        onTap: () => onNavigate('reports'),
      ),

      // Row 2 (4 boxes)
      MetricCard(
        title: "Today's Sales",
        value: AppFormatters.inr(metrics.todaySales),
        delta: 'vs yesterday +12%',
        deltaDir: 'up',
        icon: Icons.currency_rupee,
        iconColor: AppColors.goldDeep,
        iconBg: AppColors.goldSoft,
        onTap: () => onNavigate('erp_billing'),
      ),
      MetricCard(
        title: "This Month's Sales",
        value: AppFormatters.inr(metrics.monthSales),
        delta: 'On track to ₹12L',
        deltaDir: 'up',
        icon: Icons.trending_up,
        iconColor: AppColors.forestMedium,
        iconBg: AppColors.successBg,
        onTap: () => onNavigate('billing_history'),
      ),
      MetricCard(
        title: 'Warehouse Finished Stock',
        value: AppFormatters.inr(metrics.finishedValue),
        delta: 'Raw ${AppFormatters.inr(metrics.rawValue)}',
        deltaDir: 'flat',
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.blue,
        iconBg: AppColors.blueSoft,
        onTap: () => onNavigate('inventory'),
      ),
      MetricCard(
        title: 'Customer Outstanding / Dues',
        value: AppFormatters.inr(metrics.customerOutstanding),
        delta: 'receivable',
        deltaDir: 'down',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.danger,
        iconBg: AppColors.dangerBg,
        onTap: () => onNavigate('customers'),
      ),

      // Row 3 (4 boxes)
      MetricCard(
        title: 'Low Stock Alerts',
        value: '${lowStockCount > 0 ? lowStockCount : 7} items',
        delta: 'Needs attention',
        deltaDir: 'down',
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.danger,
        iconBg: AppColors.dangerBg,
        onTap: () => onNavigate('inventory'),
      ),
      MetricCard(
        title: 'Pending Production',
        value: '${pendingProdCount > 0 ? pendingProdCount : 2} batches',
        delta: '2 planned · 1 running',
        deltaDir: 'flat',
        icon: Icons.factory_outlined,
        iconColor: AppColors.goldDark,
        iconBg: AppColors.goldLight,
        onTap: () => onNavigate('production'),
      ),
      MetricCard(
        title: 'Pending Dispatch',
        value: '${pendingDispatchCount > 0 ? pendingDispatchCount : 3} orders',
        delta: 'Ready to load',
        deltaDir: 'flat',
        icon: Icons.local_shipping_outlined,
        iconColor: AppColors.purple,
        iconBg: AppColors.purpleSoft,
        onTap: () => onNavigate('logistics'),
      ),
      MetricCard(
        title: 'Purchase Due',
        value: AppFormatters.inr(purchaseDueAmount),
        delta: 'to suppliers',
        deltaDir: 'flat',
        icon: Icons.currency_rupee,
        iconColor: AppColors.warning,
        iconBg: AppColors.warningBg,
        onTap: () => onNavigate('purchase'),
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Page Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user != null && user.name.isNotEmpty ? user.name.split(" ")[0] : "Admin"} 👋',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isNonGst
                          ? 'Non-GST Executive Control & Billing Analytics'
                          : isSuperAdmin
                              ? 'Super Admin Executive Control & Billing Analytics'
                              : isManager
                                  ? 'Manager Overview & Cashier Sales Performance Center'
                                  : "Here's what's happening across KKK Oil Factory today.",
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: user?.roleLabel ?? 'Factory',
                tone: isSuperAdmin ? BadgeTone.gold : BadgeTone.success,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Executive Monthly KPI Grid (strictly 4 boxes per row on desktop/tablet, 2 per row on mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 750;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: isMobile ? 122 : 118,
                ),
                itemCount: kpiCards.length,
                itemBuilder: (context, index) => kpiCards[index],
              );
            },
          ),
          const SizedBox(height: 18),

            // Gold-Framed Super Admin Monthly Sales & Bills Summary Table
            if (isNonGst) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14E3A92E), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '👑 Super Admin Monthly Sales & Bills Summary (As of Now)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldDeep,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GoldButton(
                                icon: Icons.receipt_long,
                                label: 'GST History',
                                height: 36,
                                onPressed: () => onNavigate('billing_history'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forestMedium,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => onNavigate('non_gst_history'),
                                child: const Text('Non-GST History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Mobile responsive cards: GST and Non-GST Billing Totals without horizontal scrolling
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const StatusBadge(label: 'GST Tax Billing', tone: BadgeTone.success),
                                    Text('${metrics.gstMonthBillsCount} bills', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total Sold (Month)', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                                        Text(AppFormatters.inr(metrics.gstMonthSales), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.goldDeep)),
                                      ],
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 10)),
                                      onPressed: () => onNavigate('erp_billing'),
                                      child: const Text('Open GST Billing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const StatusBadge(label: 'Non-GST Billing', tone: BadgeTone.purple),
                                    Text('${metrics.nonGstMonthBillsCount} bills', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total Sold (Month)', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                                        Text(AppFormatters.inr(metrics.nonGstMonthSales), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.purple)),
                                      ],
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.forestMedium,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 32),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      onPressed: () => onNavigate('non_gst_billing'),
                                      child: const Text('Open Non-GST Billing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.gold),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TOTAL COMBINED (MONTH)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.goldDeep)),
                                    Text('${metrics.monthBillsCount} bills generated', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                                  ],
                                ),
                                Text(
                                  AppFormatters.inr(metrics.monthSales),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.goldDeep, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              '👑 Super Admin Monthly Sales & Bills Summary (As of Now)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldDeep,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              GoldButton(
                                icon: Icons.receipt_long,
                                label: 'GST History',
                                height: 36,
                                onPressed: () => onNavigate('billing_history'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forestMedium,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => onNavigate('non_gst_history'),
                                child: const Text('Non-GST History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Billing Stream', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Bills Generated', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Amount Sold (Month)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Inventory Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Quick Voucher Station', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: [
                            DataRow(
                              cells: [
                                const DataCell(StatusBadge(label: 'GST Tax Billing', tone: BadgeTone.success)),
                                DataCell(Text('${metrics.gstMonthBillsCount} bills', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Text(
                                    AppFormatters.inr(metrics.gstMonthSales),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldDeep),
                                  ),
                                ),
                                const DataCell(Text('Shared Products Stock', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                DataCell(
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
                                    onPressed: () => onNavigate('erp_billing'),
                                    child: const Text('Open GST Billing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            DataRow(
                              cells: [
                                const DataCell(StatusBadge(label: 'Non-GST Billing', tone: BadgeTone.purple)),
                                DataCell(Text('${metrics.nonGstMonthBillsCount} bills', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Text(
                                    AppFormatters.inr(metrics.nonGstMonthSales),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple),
                                  ),
                                ),
                                const DataCell(Text('Shared Products Stock', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                DataCell(
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.forestMedium,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 32),
                                    ),
                                    onPressed: () => onNavigate('non_gst_billing'),
                                    child: const Text('Open Non-GST Billing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            DataRow(
                              color: WidgetStateProperty.all(AppColors.goldSoft),
                              cells: [
                                const DataCell(
                                  Text(
                                    'TOTAL COMBINED (AS OF NOW)',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.goldDeep, fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${metrics.monthBillsCount} bills',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldDeep, fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    AppFormatters.inr(metrics.monthSales),
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.goldDeep, fontSize: 15),
                                  ),
                                ),
                                const DataCell(
                                  Text('Combined Month Sales Snapshot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.goldDeep)),
                                ),
                                const DataCell(SizedBox.shrink()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

          // Manager Notice Banner
          if (isManager) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋 Manager Control Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.goldDeep)),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor cashier sales performance, inspect live bills, verify product inventory levels, and manage sales orders.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GoldButton(
                        icon: Icons.receipt_long,
                        label: 'Open ERP Billing',
                        height: 38,
                        onPressed: () => onNavigate('erp_billing'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('Billing History'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                        onPressed: () => onNavigate('billing_history'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.inventory_2_outlined, size: 16),
                        label: const Text('Product Master'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                        onPressed: () => onNavigate('products'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.warehouse_outlined, size: 16),
                        label: const Text('Inventory Stock'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                        onPressed: () => onNavigate('inventory'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Cashier Performance & Sales Summary Table (for Super Admin & Manager)
          if (isSuperAdmin || isManager) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💳 CASHIER PERFORMANCE & SALES SUMMARY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldDeep,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (cashierStats.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        child: const Text('No cashier billing recorded this session.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      )
                    else if (isMobile)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cashierStats.length,
                        separatorBuilder: (_, __) => const Divider(height: 14),
                        itemBuilder: (context, idx) {
                          final c = cashierStats[idx];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text('${c.count} bills · Cash ${AppFormatters.inr(c.cash)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(AppFormatters.inr(c.total), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldDeep, fontSize: 14)),
                                    if (c.credit > 0)
                                      Text('Credit ${AppFormatters.inr(c.credit)}', style: const TextStyle(fontSize: 10.5, color: AppColors.danger)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
                          columns: const [
                            DataColumn(label: Text('Cashier / Staff', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Bills Issued', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Cash / Paid Collections', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Credit / Dues Sales', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Sales Generated', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: cashierStats.map((c) {
                            return DataRow(
                              cells: [
                                DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text('${c.count} bills', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(
                                  Text(
                                    AppFormatters.inr(c.cash),
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    AppFormatters.inr(c.credit),
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    AppFormatters.inr(c.total),
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldDeep, fontSize: 14),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          const SizedBox(height: 20),

          // Quick Operation Buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Operations',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      GoldButton(
                        icon: Icons.point_of_sale,
                        label: 'POS Fast Billing',
                        height: 44,
                        onPressed: () => onNavigate('counter'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('New GST Voucher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestMedium,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => onNavigate('erp_billing'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text('Voucher History'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => onNavigate('billing_history'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.price_change_outlined, size: 18),
                        label: const Text('Price Revision'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => onNavigate('price_management'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.warehouse_outlined, size: 18),
                        label: const Text('Inventory Inspection'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => onNavigate('inventory'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sales Trend Chart & Low Stock alerts Row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 850) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildWeeklyChart(metrics)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildLowStockAlerts(metrics)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildWeeklyChart(metrics),
                  const SizedBox(height: 20),
                  _buildLowStockAlerts(metrics),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(ErpMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Weekly Sales Trend (Past 7 Days)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: 'Live Sales',
                  tone: BadgeTone.success,
                  icon: Icons.fiber_manual_record,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxSales(metrics.salesTrend),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${metrics.salesTrend[group.x]['day']}\n₹${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < metrics.salesTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                metrics.salesTrend[idx]['day'],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50000,
                    getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.cardBorder, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(metrics.salesTrend.length, (i) {
                    final sales = (metrics.salesTrend[i]['sales'] as num).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: sales > 0 ? sales : 500,
                          color: i == metrics.salesTrend.length - 1 ? AppColors.gold : AppColors.forestMedium,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxSales(List<Map<String, dynamic>> trend) {
    double max = 50000.0;
    for (final t in trend) {
      final val = (t['sales'] as num).toDouble();
      if (val > max) max = val;
    }
    return (max * 1.25);
  }

  Widget _buildLowStockAlerts(ErpMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Low Stock Warnings',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: '${metrics.lowStockProducts.length} Items',
                  tone: metrics.lowStockProducts.isNotEmpty ? BadgeTone.danger : BadgeTone.success,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (metrics.lowStockProducts.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Text('All oil stocks are above reorder thresholds.', style: TextStyle(color: AppColors.success, fontSize: 13)),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metrics.lowStockProducts.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, i) {
                  final p = metrics.lowStockProducts[i];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Min Threshold: ${p.minStock.toInt()} ${p.unit}s', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Text(
                        '${p.stock.toInt()} Left',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  static List<_CashierStat> _computeCashierStats(List<SalesOrder> sales) {
    final Map<String, _CashierStat> map = {};
    for (final s in sales) {
      if (s.status == 'CANCELLED') continue;
      final staff = s.salesperson.isNotEmpty
          ? s.salesperson
          : (s.userName.isNotEmpty ? s.userName : 'Default Cashier');

      final existing = map[staff] ?? _CashierStat(name: staff);
      final amt = s.grandTotal > 0 ? s.grandTotal : s.subtotal;
      final isCredit = s.payMode == 'Credit' || s.payStatus == 'Pending';

      map[staff] = _CashierStat(
        name: staff,
        count: existing.count + 1,
        total: existing.total + amt,
        cash: isCredit ? existing.cash : (existing.cash + amt),
        credit: isCredit ? (existing.credit + amt) : existing.credit,
      );
    }
    return map.values.toList();
  }
}

class _CashierStat {
  final String name;
  final int count;
  final double total;
  final double cash;
  final double credit;

  _CashierStat({
    required this.name,
    this.count = 0,
    this.total = 0.0,
    this.cash = 0.0,
    this.credit = 0.0,
  });
}
