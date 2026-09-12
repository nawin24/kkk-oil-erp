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
                  : ListView.separated(
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final h = history[idx];
                        final isIncrease = h.newRate > h.oldRate;

                        if (isMobile) {
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
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncrease ? AppColors.successBg : AppColors.dangerBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isIncrease ? Icons.trending_up : Icons.trending_down,
                              color: isIncrease ? AppColors.success : AppColors.danger,
                              size: 20,
                            ),
                          ),
                          title: Text(h.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            '${h.pricingType.label} • Effective: ${AppFormatters.formatDate(h.effectiveDate)} • By: ${h.updatedBy}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${h.oldRate.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    '₹${h.newRate.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isIncrease ? AppColors.success : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppFormatters.formatDateTime(h.updatedAt),
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
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
