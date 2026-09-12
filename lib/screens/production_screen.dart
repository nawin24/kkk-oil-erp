import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/operations.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  void _showAddBatchDialog(BuildContext context) {
    final data = context.read<DataProvider>();
    final plannedCtrl = TextEditingController(text: '1000');
    final outputCtrl = TextEditingController(text: '960');
    final wastageCtrl = TextEditingController(text: '40');
    final rawCostCtrl = TextEditingController(text: '150000');
    String prodId = data.products.isNotEmpty ? data.products[0].id : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isNarrow = MediaQuery.of(context).size.width < 500;
          return AlertDialog(
            title: const Text('Start New Production Milling Run', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: prodId,
                      decoration: const InputDecoration(labelText: 'Target Product'),
                      items: data.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => prodId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isNarrow) ...[
                      TextField(controller: plannedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Planned Qty (L)')),
                      const SizedBox(height: 10),
                      TextField(controller: outputCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Output Qty (L)')),
                      const SizedBox(height: 10),
                      TextField(controller: wastageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wastage (L)')),
                    ] else
                      Row(
                        children: [
                          Expanded(child: TextField(controller: plannedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Planned Qty (L)'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: outputCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Output Qty (L)'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: wastageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wastage (L)'))),
                        ],
                      ),
                    const SizedBox(height: 12),
                    TextField(controller: rawCostCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Seed/Raw Material Cost (₹)')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              GoldButton(
                label: 'Record Milling Run',
                icon: Icons.check,
                onPressed: () {
                  final planned = double.tryParse(plannedCtrl.text) ?? 1000.0;
                  final output = double.tryParse(outputCtrl.text) ?? 960.0;
                  final wastage = double.tryParse(wastageCtrl.text) ?? 40.0;
                  final rawCost = double.tryParse(rawCostCtrl.text) ?? 150000.0;

                  final batch = ProductionBatch(
                    id: 'PRD-B${DateTime.now().millisecondsSinceEpoch % 10000}',
                    productId: prodId,
                    plannedQty: planned,
                    outputQty: output,
                    wastage: wastage,
                    status: 'Completed',
                    startDate: AppFormatters.todayISO(),
                    mfgDate: AppFormatters.todayISO(),
                    expDate: '2026-12-31',
                    rawCost: rawCost,
                    packCost: output * 4.5,
                    labourCost: 2500,
                  );

                  data.production.insert(0, batch);
                  Navigator.pop(ctx);
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
    final prodMap = {for (final p in data.products) p.id: p};
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Oil Milling & Production Runs', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${data.production.length} milling batches recorded', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    icon: Icons.add,
                    label: 'New Milling Run',
                    onPressed: () => _showAddBatchDialog(context),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Oil Milling & Production Runs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${data.production.length} milling batches recorded', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                GoldButton(
                  icon: Icons.add,
                  label: 'New Milling Run',
                  onPressed: () => _showAddBatchDialog(context),
                ),
              ],
            ),
          const SizedBox(height: 14),

          Expanded(
            child: Card(
              child: ListView.separated(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                itemCount: data.production.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final b = data.production[idx];
                  final prod = prodMap[b.productId];

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
                                  color: AppColors.goldSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.precision_manufacturing, color: AppColors.goldDeep, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(b.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            prod?.name ?? 'Oil Crushing Batch',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Mfg: ${AppFormatters.formatDate(b.mfgDate)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: '${b.recoveryYield.toStringAsFixed(1)}% Yield',
                                tone: b.recoveryYield >= 90 ? BadgeTone.success : BadgeTone.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('In: ${b.plannedQty.toInt()}L • Out: ${b.outputQty.toInt()}L',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                Text('Cost: ${AppFormatters.inr(b.totalCost)}',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.forestMedium)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.precision_manufacturing, color: AppColors.goldDeep, size: 22),
                    ),
                    title: Row(
                      children: [
                        Text(b.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(prod?.name ?? 'Oil Crushing Batch', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        StatusBadge(
                          label: '${b.recoveryYield.toStringAsFixed(1)}% Recovery Yield',
                          tone: b.recoveryYield >= 90 ? BadgeTone.success : BadgeTone.warning,
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text('Planned: ${b.plannedQty.toInt()} L • Output: ${b.outputQty.toInt()} L • Waste: ${b.wastage.toInt()} L',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const Spacer(),
                          Text('Mfg: ${AppFormatters.formatDate(b.mfgDate)} • Cost: ${AppFormatters.inr(b.totalCost)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
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
