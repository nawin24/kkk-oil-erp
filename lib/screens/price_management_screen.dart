import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class PriceManagementScreen extends StatefulWidget {
  final ValueChanged<String>? onNavigate;

  const PriceManagementScreen({super.key, this.onNavigate});

  @override
  State<PriceManagementScreen> createState() => _PriceManagementScreenState();
}

class _PriceManagementScreenState extends State<PriceManagementScreen> {
  String _selectedBrandId = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  void _showPriceUpdateDialog(BuildContext context, Product product) {
    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();

    final agencyCtrl = TextEditingController(text: product.agencyRate.toStringAsFixed(0));
    final wholesaleCtrl = TextEditingController(text: product.wholesaleRate.toStringAsFixed(0));
    final retailCtrl = TextEditingController(text: product.retailRate.toStringAsFixed(0));
    String effectiveDate = AppFormatters.todayISO();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Adjust Rates: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter updated selling rates per tier. Revisions will be logged in the price history audit trail.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: agencyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Agency Rate (₹)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: wholesaleCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Wholesale Rate (₹)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: retailCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Retail Rate (₹)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: effectiveDate,
                    decoration: const InputDecoration(labelText: 'Effective Date (YYYY-MM-DD)'),
                    onChanged: (val) => effectiveDate = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final user = auth.currentUser!;
                  final newAgency = double.tryParse(agencyCtrl.text) ?? product.agencyRate;
                  final newWholesale = double.tryParse(wholesaleCtrl.text) ?? product.wholesaleRate;
                  final newRetail = double.tryParse(retailCtrl.text) ?? product.retailRate;

                  if (newAgency != product.agencyRate) {
                    await data.updateProductRate(
                      productId: product.id,
                      pricingType: PricingType.agency,
                      newRate: newAgency,
                      effectiveDate: effectiveDate,
                      user: user,
                    );
                  }
                  if (newWholesale != product.wholesaleRate) {
                    await data.updateProductRate(
                      productId: product.id,
                      pricingType: PricingType.wholesale,
                      newRate: newWholesale,
                      effectiveDate: effectiveDate,
                      user: user,
                    );
                  }
                  if (newRetail != product.retailRate) {
                    await data.updateProductRate(
                      productId: product.id,
                      pricingType: PricingType.retail,
                      newRate: newRetail,
                      effectiveDate: effectiveDate,
                      user: user,
                    );
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rates updated for ${product.name}'), backgroundColor: AppColors.success),
                    );
                  }
                },
                child: const Text('Apply Rate Revision'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final brandMap = {for (final b in data.brands) b.id: b.name};

    final products = data.products.where((p) {
      if (_selectedBrandId != 'All' && p.brandId != _selectedBrandId) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q);
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveFilterBar(
            searchWidget: SearchInput(
              controller: _searchCtrl,
              hint: 'Search products to modify rates...',
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
                value: _selectedBrandId,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All Brands')),
                  ...data.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBrandId = val);
                },
              ),
            ),
            actionWidget: widget.onNavigate != null
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.history_edu_outlined, size: 18),
                    label: const Text('View Audit History'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
                    onPressed: () => widget.onNavigate!('price_history'),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Card(
              child: products.isEmpty
                  ? const Center(child: Text('No products found matching criteria.'))
                  : isMobile
                      ? ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final p = products[idx];

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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                            ),
                                            Text(
                                              '${brandMap[p.brandId] ?? ""} · Pack: ${p.pack}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.edit, size: 14),
                                        label: const Text('Adjust', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.gold,
                                          foregroundColor: AppColors.forestDark,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: const Size(0, 32),
                                        ),
                                        onPressed: () => _showPriceUpdateDialog(context, p),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWarm,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Cost: ₹${p.cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        Text('Agency: ₹${p.agencyRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        Text('Whole: ₹${p.wholesaleRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        Text('Retail: ₹${p.retailRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forestMedium)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
                              columns: const [
                                DataColumn(label: Text('Product Name')),
                                DataColumn(label: Text('Brand')),
                                DataColumn(label: Text('Pack')),
                                DataColumn(label: Text('Cost Rate (₹)')),
                                DataColumn(label: Text('Agency Rate (₹)')),
                                DataColumn(label: Text('Wholesale Rate (₹)')),
                                DataColumn(label: Text('Retail Rate (₹)')),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: products.map((p) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(brandMap[p.brandId] ?? '-')),
                                    DataCell(Text(p.pack)),
                                    DataCell(Text('₹${p.cost.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted))),
                                    DataCell(Text('₹${p.agencyRate.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text('₹${p.wholesaleRate.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text('₹${p.retailRate.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestMedium))),
                                    DataCell(
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.edit, size: 14),
                                        label: const Text('Adjust Rates', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.gold,
                                          foregroundColor: AppColors.forestDark,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                        onPressed: () => _showPriceUpdateDialog(context, p),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
