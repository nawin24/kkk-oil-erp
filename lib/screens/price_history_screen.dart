import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class PriceHistoryScreen extends StatefulWidget {
  const PriceHistoryScreen({super.key});

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isMobile = MediaQuery.of(context).size.width < 700;
    final history = data.priceHistory.where((h) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return h.productName.toLowerCase().contains(q) ||
          h.updatedBy.toLowerCase().contains(q) ||
          h.effectiveDate.contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchInput(
                  controller: _searchCtrl,
                  hint: 'Search price audit log...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                StatusBadge(
                  label: '${history.length} Revisions Recorded',
                  tone: BadgeTone.info,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SearchInput(
                    controller: _searchCtrl,
                    hint: 'Search price audit log by product, user, date...',
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(
                  label: '${history.length} Revisions Recorded',
                  tone: BadgeTone.info,
                ),
              ],
            ),
          const SizedBox(height: 14),

          Expanded(
            child: Card(
              child: history.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_edu_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('No price revisions recorded yet.', style: TextStyle(color: AppColors.textSecondary)),
                          Text('Changes made in Price Management will appear here with audit timestamps.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  : isMobile
                      ? ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: history.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final h = history[idx];
                            final isIncrease = h.newRate > h.oldRate;

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isIncrease ? AppColors.successBg : AppColors.dangerBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isIncrease ? Icons.trending_up : Icons.trending_down,
                                          color: isIncrease ? AppColors.success : AppColors.danger,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(h.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                            const SizedBox(height: 2),
                                            Text('${h.pricingType.label} • By: ${h.updatedBy}',
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '₹${h.oldRate.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward, size: 12, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                '₹${h.newRate.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: isIncrease ? AppColors.success : AppColors.danger,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            AppFormatters.formatDateTime(h.updatedAt),
                                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : _buildDesktopPriceHistoryTable(history),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPriceHistoryTable(List<PriceHistoryRecord> history) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 46,
          columnSpacing: 18,
          horizontalMargin: 12,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFBF9)),
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFF0F2EF), width: 1),
          ),
          columns: const [
            DataColumn(label: Text('PRODUCT NAME', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('PRICING TIER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('OLD RATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('NEW RATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('CHANGE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('EFFECTIVE DATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('UPDATED BY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            DataColumn(label: Text('AUDIT TIMESTAMP', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
          ],
          rows: history.map((h) {
            final isIncrease = h.newRate > h.oldRate;
            final diff = h.newRate - h.oldRate;
            final diffStr = diff > 0 ? '+₹${diff.toStringAsFixed(0)}' : (diff < 0 ? '-₹${(-diff).toStringAsFixed(0)}' : '₹0');

            return DataRow(
              cells: [
                // PRODUCT NAME
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isIncrease ? AppColors.successBg : AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isIncrease ? Icons.trending_up : Icons.trending_down,
                          color: isIncrease ? AppColors.success : AppColors.danger,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        h.productName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                    ],
                  ),
                ),
                // PRICING TIER
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      h.pricingType.label.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                    ),
                  ),
                ),
                // OLD RATE
                DataCell(
                  Text(
                    '₹${h.oldRate.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                // NEW RATE
                DataCell(
                  Text(
                    '₹${h.newRate.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isIncrease ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
                // CHANGE
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isIncrease ? AppColors.successBg : AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 11,
                          color: isIncrease ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          diffStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isIncrease ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // EFFECTIVE DATE
                DataCell(
                  Text(
                    AppFormatters.formatDate(h.effectiveDate),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.text),
                  ),
                ),
                // UPDATED BY
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      h.updatedBy,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2),
                    ),
                  ),
                ),
                // AUDIT TIMESTAMP
                DataCell(
                  Text(
                    AppFormatters.formatDateTime(h.updatedAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
