import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  void _showAddSupplierDialog(BuildContext context, [Supplier? existing]) {
    final data = context.read<DataProvider>();
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final materialCtrl = TextEditingController(text: existing?.material ?? '');
    final contactCtrl = TextEditingController(text: existing?.contact ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final gstinCtrl = TextEditingController(text: existing?.gstin ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final dueCtrl = TextEditingController(text: existing?.due.toStringAsFixed(0) ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Supplier' : 'Add New Supplier Vendor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Supplier Firm Name')),
                const SizedBox(height: 12),
                TextField(controller: materialCtrl, decoration: const InputDecoration(labelText: 'Materials Supplied (Seeds, Tins, PET)')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN')),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 12),
                TextField(controller: dueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Outstanding Payable (₹)')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final supp = Supplier(
                id: isEdit ? existing.id : 'S${DateTime.now().millisecondsSinceEpoch % 1000}',
                name: nameCtrl.text.trim(),
                material: materialCtrl.text.trim(),
                contact: contactCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                gstin: gstinCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                due: double.tryParse(dueCtrl.text) ?? 0.0,
              );

              await data.saveSupplier(supp);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save Changes' : 'Create Supplier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final suppliers = data.suppliers.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.material.toLowerCase().contains(q) || s.contact.toLowerCase().contains(q);
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
              hint: 'Search vendors by firm name, raw material...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            actionWidget: GoldButton(
              icon: Icons.add_business_outlined,
              label: 'Add Supplier',
              height: 46,
              onPressed: () => _showAddSupplierDialog(context),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: suppliers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final s = suppliers[idx];
                  final hasDue = s.due > 0;

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
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.business_outlined, color: AppColors.forestMedium, size: 20),
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
                                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      StatusBadge(label: '⭐ ${s.rating}', tone: BadgeTone.gold),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Supplies: ${s.material} · Contact: ${s.contact} (${s.phone})',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.forestLight),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showAddSupplierDialog(context, s),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'GSTIN: ${s.gstin} · Address: ${s.address}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Payable Due Status', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                'Due: ${AppFormatters.inr(s.due)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: hasDue ? AppColors.danger : AppColors.forestMedium,
                                ),
                              ),
                            ],
                          ),
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
