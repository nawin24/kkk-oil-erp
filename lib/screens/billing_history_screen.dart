import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sales_order.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/invoice_print_dialog.dart';
import '../widgets/ui_components.dart';

class BillingHistoryScreen extends StatefulWidget {
  final String forcedBillingType; // 'GST' or 'NON_GST'

  const BillingHistoryScreen({super.key, this.forcedBillingType = 'GST'});

  @override
  State<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedPayFilter = 'All';

  void _showCancelDialog(BuildContext context, SalesOrder order) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Text('Cancel Bill ${order.voucherNo}?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancelling this voucher will restore all item quantities back to the warehouse inventory and reverse any customer credit outstanding.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'e.g. Order cancelled by customer, data entry mistake',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Bill'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final reason = reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'Cancelled by staff';
              final data = context.read<DataProvider>();
              final auth = context.read<AuthProvider>();
              await data.cancelSalesOrder(orderId: order.id, reason: reason, user: auth.currentUser!);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final visibleSales = data.getFilteredSales(auth.currentUser).where((s) {
      final bType = s.billingType.isNotEmpty ? s.billingType : (s.id.startsWith('NG') ? 'NON_GST' : 'GST');
      if (bType != widget.forcedBillingType) return false;

      if (_selectedPayFilter != 'All' && s.payStatus != _selectedPayFilter) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.voucherNo.toLowerCase().contains(q) ||
          (s.customerName ?? '').toLowerCase().contains(q) ||
          s.date.contains(q);
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.forcedBillingType == 'GST' ? 'GST Invoices History' : 'Non-GST History (Super Admin)',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${visibleSales.length} total vouchers recorded in this stream',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: widget.forcedBillingType == 'GST' ? 'GST Ledgers' : 'Non-GST Stream',
                tone: widget.forcedBillingType == 'GST' ? BadgeTone.success : BadgeTone.purple,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Responsive Filter Bar
          ResponsiveFilterBar(
            searchWidget: SearchInput(
              controller: _searchCtrl,
              hint: 'Search voucher no, customer, date...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            filterWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButton<String>(
                value: _selectedPayFilter,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: ['All', 'Paid', 'Credit'].map((mode) {
                  return DropdownMenuItem(value: mode, child: Text('Status: $mode'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPayFilter = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vouchers List
          Expanded(
            child: Card(
              child: visibleSales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No ${widget.forcedBillingType == "GST" ? "GST" : "Non-GST"} vouchers found.',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                      itemCount: visibleSales.length,
                      separatorBuilder: (_, __) => SizedBox(height: isMobile ? 10 : 6),
                      itemBuilder: (context, idx) {
                        final order = visibleSales[idx];
                        final isCancelled = order.isCancelled;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isCancelled
                                          ? AppColors.dangerBg
                                          : (order.isGst ? AppColors.successBg : AppColors.goldLight),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isCancelled ? Icons.cancel_outlined : Icons.receipt,
                                      color: isCancelled
                                          ? AppColors.danger
                                          : (order.isGst ? AppColors.forestMedium : AppColors.goldDark),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              order.voucherNo,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            StatusBadge(
                                              label: order.payStatus,
                                              tone: order.payStatus == 'Paid' ? BadgeTone.success : BadgeTone.warning,
                                            ),
                                            if (isCancelled)
                                              const StatusBadge(label: 'CANCELLED', tone: BadgeTone.danger),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          order.customerName ?? 'Counter Cash Customer',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppFormatters.inr(order.grandTotal),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: isCancelled ? AppColors.textMuted : AppColors.forestMedium,
                                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      Text(
                                        order.billingType,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${AppFormatters.formatDate(order.date)} ${order.time} · ${order.items.length} item(s) · ${order.payMode} · By: ${order.userName}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isCancelled) ...[
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.cancel_outlined, size: 14, color: AppColors.danger),
                                      label: const Text('Cancel', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: const Size(0, 32),
                                        side: const BorderSide(color: AppColors.danger),
                                      ),
                                      onPressed: () => _showCancelDialog(context, order),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.print_outlined, size: 14),
                                    label: const Text('Print PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: AppColors.forestDark,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    onPressed: () {
                                      InvoicePrintDialog.show(
                                        context,
                                        order: order,
                                        company: order.billingType == 'GST'
                                            ? data.company
                                            : data.company.copyWith(gstin: ''),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
