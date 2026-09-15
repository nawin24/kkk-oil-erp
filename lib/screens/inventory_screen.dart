import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  void _showAdjustStockDialog(BuildContext context, Product product) {
    final data = context.read<DataProvider>();
    final stockCtrl = TextEditingController(text: product.stock.toStringAsFixed(0));
    final minCtrl = TextEditingController(text: product.minStock.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust Stock: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Physical Stock Count')),
            const SizedBox(height: 12),
            TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum Alert Threshold')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newStock = double.tryParse(stockCtrl.text) ?? product.stock;
              final newMin = double.tryParse(minCtrl.text) ?? product.minStock;
              final updated = product.copyWith(stock: newStock, minStock: newMin);
              await data.saveProduct(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('Delete Inventory Item?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${p.name}" (${p.code}) permanently from Central Master and godown stock records? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final data = context.read<DataProvider>();
              await data.deleteProduct(p.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${p.name}" from inventory master.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final finishedValue = data.products.fold<double>(0.0, (s, p) => s + (p.stock * p.cost));
    final rawValue = data.rawMaterials.fold<double>(0.0, (s, r) => s + (r.stock * r.cost));
    final lowStockCount = data.products.where((p) => p.stock <= p.minStock).length;

    final filteredProducts = data.products.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q) || p.oilType.toLowerCase().contains(q);
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Valuation Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 850;
                final crossAxisCount = isWide ? 3 : (constraints.maxWidth > 550 ? 2 : 1);
                return GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: isMobile ? 128 : 124,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    MetricCard(
                      title: 'FINISHED GOODS VALUATION',
                      value: AppFormatters.inr(finishedValue),
                      subtitle: '${data.products.length} Active SKUs',
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.forestMedium,
                      iconBg: AppColors.successBg,
                    ),
                    MetricCard(
                      title: 'RAW SEEDS & PACKAGING',
                      value: AppFormatters.inr(rawValue),
                      subtitle: '${data.rawMaterials.length} Raw Materials in Godown',
                      icon: Icons.agriculture_outlined,
                      iconColor: AppColors.goldDark,
                      iconBg: AppColors.goldLight,
                    ),
                    MetricCard(
                      title: 'LOW STOCK THRESHOLD ALERTS',
                      value: '$lowStockCount Items',
                      subtitle: 'Require urgent milling/purchase',
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.danger,
                      iconBg: AppColors.dangerBg,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const TabBar(
                labelColor: AppColors.forestMedium,
                indicatorColor: AppColors.forestMedium,
                tabs: [
                  Tab(text: 'Finished Oil Products Stock'),
                  Tab(text: 'Raw Materials & Supplies'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Products
                  Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SearchInput(
                            controller: _searchCtrl,
                            hint: 'Filter finished stock by oil name, pack...',
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredProducts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final p = filteredProducts[idx];
                              final isLow = p.stock <= p.minStock;
                              final val = p.stock * p.cost;

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isLow ? AppColors.dangerBg : AppColors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.oil_barrel_outlined,
                                    color: isLow ? AppColors.danger : AppColors.forestMedium,
                                    size: 20,
                                  ),
                                ),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                subtitle: Text(
                                  'Pack: ${p.pack} • Cost: ₹${p.cost.toStringAsFixed(0)} • Total Value: ${AppFormatters.inr(val)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        StatusBadge(
                                          label: '${p.stock.toInt()} ${p.unit}s',
                                          tone: isLow ? BadgeTone.danger : BadgeTone.success,
                                        ),
                                        Text('Min: ${p.minStock.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_note, size: 20, color: AppColors.forestLight),
                                      tooltip: 'Adjust Physical Count',
                                      onPressed: () => _showAdjustStockDialog(context, p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.danger),
                                      tooltip: 'Delete Product',
                                      onPressed: () => _confirmDeleteProduct(context, p),
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

                  // Tab 2: Raw Materials
                  Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: data.rawMaterials.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final rm = data.rawMaterials[idx];
                        final isLow = rm.stock <= rm.minStock;
                        final val = rm.stock * rm.cost;

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLow ? AppColors.dangerBg : AppColors.goldLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.grass,
                              color: isLow ? AppColors.danger : AppColors.goldDark,
                              size: 20,
                            ),
                          ),
                          title: Text(rm.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: Text(
                            'Godown: ${rm.godown} • Cost: ₹${rm.cost.toStringAsFixed(0)}/${rm.unit} • Total: ${AppFormatters.inr(val)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: StatusBadge(
                            label: '${rm.stock.toInt()} ${rm.unit}',
                            tone: isLow ? BadgeTone.danger : BadgeTone.success,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
