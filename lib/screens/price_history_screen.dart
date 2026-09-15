import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String? _filterDate;
  String _selectedTier = 'ALL';
  String _changeFilter = 'ALL'; // ALL, INCREASED, DECREASED

  Future<void> _pickFilterDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate != null ? (DateTime.tryParse(_filterDate!) ?? now) : now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Date to Filter Price Changes',
    );
    if (picked != null) {
      final yyyy = picked.year.toString().padLeft(4, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      final dd = picked.day.toString().padLeft(2, '0');
      setState(() => _filterDate = '$yyyy-$mm-$dd');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isMobile = MediaQuery.of(context).size.width < 700;
    final todayStr = AppFormatters.todayISO();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final history = data.priceHistory.where((h) {
      // 1. Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = h.productName.toLowerCase().contains(q) ||
            h.updatedBy.toLowerCase().contains(q) ||
            h.effectiveDate.contains(q);
        if (!matches) return false;
      }
      // 2. Date filter
      if (_filterDate != null) {
        final effectiveMatches = h.effectiveDate == _filterDate;
        final timestampMatches = h.updatedAt.startsWith(_filterDate!);
        if (!effectiveMatches && !timestampMatches) return false;
      }
      // 3. Pricing tier filter
      if (_selectedTier != 'ALL') {
        if (h.pricingType.key.toUpperCase() != _selectedTier) return false;
      }
      // 4. Rate change direction filter
      if (_changeFilter == 'INCREASED' && h.newRate <= h.oldRate) return false;
      if (_changeFilter == 'DECREASED' && h.newRate >= h.oldRate) return false;

      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Search Bar & Revisions Badge
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
          const SizedBox(height: 10),

          // FILTERS TOOLBAR: Date Filter, Tier Filter, Change Direction Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Text('DATE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.text3)),
                  ],
                ),
                // All Dates
                InkWell(
                  onTap: () => setState(() => _filterDate = null),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _filterDate == null ? const Color(0xFFD97706) : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'All Dates',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _filterDate == null ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                // Today
                InkWell(
                  onTap: () => setState(() => _filterDate = todayStr),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _filterDate == todayStr ? const Color(0xFFD97706) : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _filterDate == todayStr ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                // Yesterday
                InkWell(
                  onTap: () => setState(() => _filterDate = yesterdayStr),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _filterDate == yesterdayStr ? const Color(0xFFD97706) : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Yesterday',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _filterDate == yesterdayStr ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                // Pick Date Button
                InkWell(
                  onTap: _pickFilterDate,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_filterDate != null && _filterDate != todayStr && _filterDate != yesterdayStr)
                          ? const Color(0xFFD97706)
                          : Colors.white,
                      border: Border.all(color: const Color(0xFFD97706)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 13,
                          color: (_filterDate != null && _filterDate != todayStr && _filterDate != yesterdayStr)
                              ? Colors.white
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (_filterDate != null && _filterDate != todayStr && _filterDate != yesterdayStr)
                              ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(_filterDate!) ?? DateTime.now())
                              : 'Select Date…',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: (_filterDate != null && _filterDate != todayStr && _filterDate != yesterdayStr)
                                ? Colors.white
                                : const Color(0xFFD97706),
                          ),
                        ),
                        if (_filterDate != null && _filterDate != todayStr && _filterDate != yesterdayStr) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() => _filterDate = null),
                            child: const Icon(Icons.cancel, size: 13, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),
                // TIER FILTER PILLS
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['ALL', 'AGENCY', 'WHOLESALE', 'RETAIL'].map((tier) {
                      final isSel = _selectedTier == tier;
                      return InkWell(
                        onTap: () => setState(() => _selectedTier = tier),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF10231B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tier,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // CHANGE STATE FILTER PILLS
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatePill('ALL', 'All Changes', _changeFilter == 'ALL', () => setState(() => _changeFilter = 'ALL')),
                      _buildStatePill('INCREASED', '▲ Increased', _changeFilter == 'INCREASED', () => setState(() => _changeFilter = 'INCREASED'), color: AppColors.success),
                      _buildStatePill('DECREASED', '▼ Decreased', _changeFilter == 'DECREASED', () => setState(() => _changeFilter = 'DECREASED'), color: AppColors.danger),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Card(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_edu_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            _filterDate != null
                                ? 'No price revisions recorded on $_filterDate.'
                                : 'No price revisions recorded yet.',
                            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Changes made when editing products will automatically appear here with exact increase/decrease amounts.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          if (_filterDate != null) ...[
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () => setState(() => _filterDate = null),
                              icon: const Icon(Icons.clear, size: 14),
                              label: const Text('Clear Date Filter'),
                            ),
                          ],
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
                            final diff = h.newRate - h.oldRate;
                            final isIncrease = diff > 0;
                            final isDecrease = diff < 0;
                            final pct = h.oldRate > 0 ? ((diff.abs() / h.oldRate) * 100) : 0.0;
                            final diffStr = isIncrease
                                ? '+₹${diff.toStringAsFixed(0)} (+${pct.toStringAsFixed(1)}%)'
                                : (isDecrease
                                    ? '-₹${(-diff).toStringAsFixed(0)} (-${pct.toStringAsFixed(1)}%)'
                                    : '₹0 (0%)');

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
                                          color: isIncrease ? AppColors.successBg : (isDecrease ? AppColors.dangerBg : const Color(0xFFF3F4F6)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isIncrease ? Icons.trending_up : (isDecrease ? Icons.trending_down : Icons.remove),
                                          color: isIncrease ? AppColors.success : (isDecrease ? AppColors.danger : AppColors.textMuted),
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
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(3)),
                                                  child: Text(h.pricingType.label.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                                                ),
                                                const SizedBox(width: 6),
                                                Text('By: ${h.updatedBy}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ],
                                            ),
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
                                                  color: isIncrease ? AppColors.success : (isDecrease ? AppColors.danger : AppColors.textPrimary),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isIncrease ? AppColors.successBg : (isDecrease ? AppColors.dangerBg : const Color(0xFFF3F4F6)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              diffStr,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isIncrease ? AppColors.success : (isDecrease ? AppColors.danger : AppColors.textMuted),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${AppFormatters.formatDate(h.effectiveDate)} • ${AppFormatters.formatDateTime(h.updatedAt)}',
                                            style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
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

  Widget _buildStatePill(String key, String label, bool isSel, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? (color ?? const Color(0xFF10231B)) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isSel ? Colors.white : (color ?? AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPriceHistoryTable(List<PriceHistoryRecord> history) {
    return Column(
      children: [
        // Responsive Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFFFAFBF9),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('PRODUCT NAME', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
              Expanded(flex: 2, child: Text('PRICING TIER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
              Expanded(flex: 1, child: Text('OLD RATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
              Expanded(flex: 1, child: Text('NEW RATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
              Expanded(flex: 2, child: Text('CHANGE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
              Expanded(flex: 2, child: Text('EFFECTIVE DATE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
              Expanded(flex: 2, child: Text('UPDATED BY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
              Expanded(flex: 2, child: Text('AUDIT TIMESTAMP', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text3))),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2EF)),
        // Responsive List Rows
        Expanded(
          child: ListView.separated(
            itemCount: history.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.8, color: Color(0xFFF0F2EF)),
            itemBuilder: (context, idx) {
              final h = history[idx];
              final diff = h.newRate - h.oldRate;
              final isIncrease = diff > 0;
              final isDecrease = diff < 0;
              final pct = h.oldRate > 0 ? ((diff.abs() / h.oldRate) * 100) : 0.0;
              final diffStr = isIncrease
                  ? '+₹${diff.toStringAsFixed(0)} (+${pct.toStringAsFixed(1)}%)'
                  : (isDecrease
                      ? '-₹${(-diff).toStringAsFixed(0)} (-${pct.toStringAsFixed(1)}%)'
                      : '₹0 (0%)');

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: idx.isOdd ? AppColors.surfaceWarm.withOpacity(0.35) : Colors.white,
                child: Row(
                  children: [
                    // PRODUCT NAME
                    Expanded(
                      flex: 3,
                      child: Row(
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
                          Expanded(
                            child: Text(
                              h.productName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // PRICING TIER
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
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
                    ),
                    // OLD RATE
                    Expanded(
                      flex: 1,
                      child: Text(
                        '₹${h.oldRate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    // NEW RATE
                    Expanded(
                      flex: 1,
                      child: Text(
                        '₹${h.newRate.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isIncrease ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                    // CHANGE
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
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
                    ),
                    // EFFECTIVE DATE
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppFormatters.formatDate(h.effectiveDate),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.text),
                      ),
                    ),
                    // UPDATED BY
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            h.updatedBy,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    // AUDIT TIMESTAMP
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppFormatters.formatDateTime(h.updatedAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
