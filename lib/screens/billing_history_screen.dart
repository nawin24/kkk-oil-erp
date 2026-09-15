import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
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
                      widget.forcedBillingType == 'GST' ? 'Billing History' : 'Non-GST History (Super Admin)',
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
                label: widget.forcedBillingType == 'GST' ? 'Billing Stream' : 'Non-GST Stream',
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
                            'No ${widget.forcedBillingType == "GST" ? "billing" : "Non-GST"} vouchers found.',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                      : isMobile
                          ? ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: visibleSales.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            order.voucherNo,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: const Color(0xFFD97706),
                                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          _buildPaymentBadge(order.payStatus),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.customerName ?? 'Walk-in Customer',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${AppFormatters.formatDate(order.date)} · ${order.billingType}',
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                          ),
                                          Text(
                                            AppFormatters.inr(order.grandTotal),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 14),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (!isCancelled) ...[
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                              tooltip: 'Cancel Voucher',
                                              onPressed: () => _showCancelDialog(context, order),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          IconButton(
                                            icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.text2),
                                            tooltip: 'Print PDF',
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
                            )
                          : _buildDesktopInvoicesTable(context, visibleSales, data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopInvoicesTable(
    BuildContext context,
    List<SalesOrder> sales,
    DataProvider data,
  ) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 48,
          columnSpacing: 14,
          horizontalMargin: 12,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFBF9)),
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFF0F2EF), width: 1),
          ),
          columns: const [
            DataColumn(label: Text('VOUCHER NO', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('DATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('PRICING', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('BILLING TYPE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('BILLED BY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('TAXABLE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('GST', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('GRAND TOTAL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('PAYMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
          ],
          rows: sales.map((order) {
            final isCancelled = order.isCancelled;

            return DataRow(
              cells: [
                // VOUCHER NO
                DataCell(
                  Text(
                    order.voucherNo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFD97706),
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                // CUSTOMER
                DataCell(
                  Text(
                    order.customerName?.isNotEmpty == true ? order.customerName! : 'Walk-in Customer',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // DATE
                DataCell(
                  Text(
                    AppFormatters.formatDate(order.date),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.text),
                  ),
                ),
                // PRICING
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.pricingType.key.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                    ),
                  ),
                ),
                // BILLING TYPE
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.billingType,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF137333)),
                    ),
                  ),
                ),
                // BILLED BY
                DataCell(
                  Text(
                    order.salesperson.isNotEmpty ? order.salesperson : order.userName,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.text2),
                  ),
                ),
                // TAXABLE
                DataCell(
                  Text(
                    AppFormatters.inr(order.subtotal),
                    style: const TextStyle(fontSize: 12, color: AppColors.text),
                  ),
                ),
                // GST
                DataCell(
                  Text(
                    AppFormatters.inr(order.gstTotal),
                    style: const TextStyle(fontSize: 12, color: AppColors.text),
                  ),
                ),
                // GRAND TOTAL
                DataCell(
                  Text(
                    AppFormatters.inr(order.grandTotal),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: isCancelled ? AppColors.text3 : AppColors.text,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                // PAYMENT
                DataCell(_buildPaymentBadge(order.payStatus)),
                // STATUS
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isCancelled ? const Color(0xFFFCE8E6) : const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCancelled ? 'CANCELLED' : 'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isCancelled ? const Color(0xFFC5221F) : const Color(0xFF137333),
                      ),
                    ),
                  ),
                ),
                // ACTIONS
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_outlined, size: 16, color: AppColors.text2),
                        tooltip: 'Print / Download PDF',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
                      if (!isCancelled) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                          tooltip: 'Cancel Voucher',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => _showCancelDialog(context, order),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String payStatus) {
    Color bg = const Color(0xFFE6F4EA);
    Color fg = const Color(0xFF137333);

    if (payStatus == 'Pending') {
      bg = const Color(0xFFFCE8E6);
      fg = const Color(0xFFC5221F);
    } else if (payStatus == 'Partial') {
      bg = const Color(0xFFFEF7E0);
      fg = const Color(0xFFB06000);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        payStatus,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
