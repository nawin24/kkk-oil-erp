import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/operations.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  void _showAddPurchaseDialog(BuildContext context) {
    final data = context.read<DataProvider>();
    final matCtrl = TextEditingController(text: 'Groundnut Raw Pods');
    final qtyCtrl = TextEditingController(text: '5000');
    final rateCtrl = TextEditingController(text: '45');
    String suppId = data.suppliers.isNotEmpty ? data.suppliers[0].id : '';
    String qcStatus = 'Passed';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isNarrow = MediaQuery.of(context).size.width < 500;
          return AlertDialog(
            title: const Text('Record Seed & Raw Material Inward', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: matCtrl, decoration: const InputDecoration(labelText: 'Material Name')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: suppId,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: data.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => suppId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isNarrow) ...[
                      TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity (kg)')),
                      const SizedBox(height: 10),
                      TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate per kg (₹)')),
                    ] else
                      Row(
                        children: [
                          Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity (kg)'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate per kg (₹)'))),
                        ],
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: qcStatus,
                      decoration: const InputDecoration(labelText: 'QC Status'),
                      items: const [
                        DropdownMenuItem(value: 'Passed', child: Text('Passed (Graded)')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending Lab Test')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => qcStatus = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              GoldButton(
                label: 'Save Inward Entry',
                icon: Icons.check,
                onPressed: () {
                  final qty = double.tryParse(qtyCtrl.text) ?? 1000.0;
                  final rate = double.tryParse(rateCtrl.text) ?? 45.0;

                  final purchase = Purchase(
                    id: 'PO-INW-${DateTime.now().millisecondsSinceEpoch % 10000}',
                    supplierId: suppId,
                    date: AppFormatters.todayISO(),
                    material: matCtrl.text.trim().isEmpty ? 'Groundnut Raw Pods' : matCtrl.text.trim(),
                    qty: qty,
                    unit: 'kg',
                    rate: rate,
                    qc: qcStatus,
                  );

                  data.purchases.insert(0, purchase);
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
    final suppMap = {for (final s in data.suppliers) s.id: s.name};
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
                const Text('Seed & Raw Supplies Inward', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${data.purchases.length} inward shipments recorded', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    icon: Icons.add,
                    label: 'Record Inward PO',
                    onPressed: () => _showAddPurchaseDialog(context),
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
                    const Text('Seed & Raw Supplies Inward', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${data.purchases.length} inward shipments recorded', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                GoldButton(
                  icon: Icons.add,
                  label: 'Record Inward PO',
                  onPressed: () => _showAddPurchaseDialog(context),
                ),
              ],
            ),
          const SizedBox(height: 14),

          Expanded(
            child: Card(
              child: ListView.separated(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                itemCount: data.purchases.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final p = data.purchases[idx];
                  final suppName = suppMap[p.supplierId] ?? 'Local Seed Farmer';

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
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.forestMedium, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(p.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            p.material,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Supplier: $suppName',
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(label: 'QC: ${p.qc}', tone: p.qc == 'Passed' ? BadgeTone.success : BadgeTone.warning),
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
                                Text('${p.qty.toInt()} ${p.unit} @ ₹${p.rate.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                Text('Total: ${AppFormatters.inr(p.totalAmount)}',
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
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.forestMedium, size: 22),
                    ),
                    title: Row(
                      children: [
                        Text(p.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(p.material, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(width: 8),
                        StatusBadge(label: 'QC: ${p.qc}', tone: p.qc == 'Passed' ? BadgeTone.success : BadgeTone.warning),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text('Supplier: $suppName • Inward Date: ${AppFormatters.formatDate(p.date)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const Spacer(),
                          Text('${p.qty.toInt()} ${p.unit} @ ₹${p.rate.toStringAsFixed(0)} • Total: ${AppFormatters.inr(p.totalAmount)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
