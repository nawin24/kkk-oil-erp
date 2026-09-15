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

  void _showBulkPriceEditor(BuildContext context, DataProvider data) {
    final products = data.products;
    final Map<String, Map<String, TextEditingController>> controllers = {};
    for (final p in products) {
      controllers[p.id] = {
        'agency': TextEditingController(text: p.agencyRate.toStringAsFixed(0)),
        'wholesale': TextEditingController(text: p.wholesaleRate.toStringAsFixed(0)),
        'retail': TextEditingController(text: p.retailRate.toStringAsFixed(0)),
        'mrp': TextEditingController(text: p.mrp.toStringAsFixed(0)),
      };
    }

    String modalSearch = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = products.where((p) {
            if (modalSearch.isEmpty) return true;
            final q = modalSearch.toLowerCase();
            return p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Price Editor · 1-Click Rate Adjustments',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Edit Agency, Wholesale, Retail & MRP rates for multiple products in a single stretch.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 820,
              height: 520,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Filter products in bulk editor…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setModalState(() => modalSearch = val),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('PRODUCT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('AGENCY (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
                        Expanded(flex: 2, child: Text('WHOLESALE (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
                        Expanded(flex: 2, child: Text('RETAIL (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F8A5B)))),
                        Expanded(flex: 2, child: Text('MRP (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final p = filtered[idx];
                        final ctrlMap = controllers[p.id]!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${p.code} · ${p.pack}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: ctrlMap['agency'],
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: ctrlMap['wholesale'],
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: ctrlMap['retail'],
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: ctrlMap['mrp'],
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Save All Price Changes (1-Click)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestMedium,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () async {
                  int updatedCount = 0;

                  for (final p in products) {
                    final ctrlMap = controllers[p.id];
                    if (ctrlMap == null) continue;

                    final newAgency = double.tryParse(ctrlMap['agency']!.text.trim()) ?? p.agencyRate;
                    final newWholesale = double.tryParse(ctrlMap['wholesale']!.text.trim()) ?? p.wholesaleRate;
                    final newRetail = double.tryParse(ctrlMap['retail']!.text.trim()) ?? p.retailRate;
                    final newMrp = double.tryParse(ctrlMap['mrp']!.text.trim()) ?? p.mrp;

                    if (newAgency != p.agencyRate ||
                        newWholesale != p.wholesaleRate ||
                        newRetail != p.retailRate ||
                        newMrp != p.mrp) {
                      final updated = p.copyWith(
                        agencyRate: newAgency,
                        wholesaleRate: newWholesale,
                        retailRate: newRetail,
                        price: newRetail,
                        mrp: newMrp,
                        updatedDate: AppFormatters.todayISO(),
                      );
                      await data.saveProduct(updated, updatedBy: 'Bulk Price Editor');
                      updatedCount++;
                    }
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated rates for $updatedCount product(s) in a single stretch!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
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
            actionWidget: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('Bulk Price Editor', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.forestDark,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showBulkPriceEditor(context, data),
                ),
                if (widget.onNavigate != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history_edu_outlined, size: 18),
                    label: const Text('View Audit History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => widget.onNavigate!('price_history'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
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
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              color: AppColors.surfaceAlt,
                              child: const Row(
                                children: [
                                  SizedBox(width: 32, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 3, child: Text('Product Name & Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('Brand & Pack', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 1, child: Text('Cost Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 1, child: Text('Agency Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
                                  Expanded(flex: 1, child: Text('Wholesale Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
                                  Expanded(flex: 1, child: Text('Retail Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F8A5B)))),
                                  SizedBox(width: 120, child: Center(child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                                ],
                              ),
                            ),
                            const Divider(height: 1, thickness: 1, color: AppColors.border),
                            Expanded(
                              child: ListView.separated(
                                itemCount: products.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.8, color: AppColors.border),
                                itemBuilder: (context, idx) {
                                  final p = products[idx];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: idx.isOdd ? AppColors.surfaceWarm.withOpacity(0.35) : Colors.white,
                                    child: Row(
                                      children: [
                                        SizedBox(width: 32, child: Text('${idx + 1}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text(p.code, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.goldDeep)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('${brandMap[p.brandId] ?? "-"} · ${p.pack}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text('₹${p.cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text('₹${p.agencyRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text('₹${p.wholesaleRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text('₹${p.retailRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1F8A5B))),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Center(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.edit, size: 13),
                                              label: const Text('Adjust', style: TextStyle(fontSize: 11.5)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.gold,
                                                foregroundColor: AppColors.forestDark,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                minimumSize: const Size(0, 32),
                                              ),
                                              onPressed: () => _showPriceUpdateDialog(context, p),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
