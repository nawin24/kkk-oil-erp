import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _customerSegment = 'ALL'; // 'ALL', 'RETAIL', 'DEALERS'

  void _showAddCustomerDialog(BuildContext context, [Customer? existing]) {
    final data = context.read<DataProvider>();
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final contactCtrl = TextEditingController(text: existing?.contact ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final gstinCtrl = TextEditingController(text: existing?.gstin ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final areaCtrl = TextEditingController(text: existing?.area ?? '');
    final routeCtrl = TextEditingController(text: existing?.route ?? '');
    final limitCtrl = TextEditingController(text: existing?.creditLimit.toStringAsFixed(0) ?? '100000');
    
    // Category helper: Retail vs Dealer
    bool isDealerCategory = existing != null &&
        (existing.type == 'Wholesaler' || existing.type == 'Distributor' || existing.priceList == 'AGENCY' || existing.priceList == 'WHOLESALE');
    String category = isDealerCategory ? 'DEALER' : 'RETAIL';
    String type = existing?.type ?? 'Retail Store';
    String priceList = existing?.priceList ?? 'RETAIL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Customer' : 'Add New Customer Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  category = 'RETAIL';
                                  type = 'Retail Store';
                                  priceList = 'RETAIL';
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: category == 'RETAIL' ? AppColors.forestMedium : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    'Regular / Retail',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: category == 'RETAIL' ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  category = 'DEALER';
                                  type = 'Wholesaler';
                                  priceList = 'WHOLESALE';
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: category == 'DEALER' ? const Color(0xFFD97706) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    'Dealer / Agency',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: category == 'DEALER' ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer / Store Name')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: type,
                            decoration: const InputDecoration(labelText: 'Store Type'),
                            items: ['Supermarket', 'Wholesaler', 'Retail Store', 'Institutional', 'Distributor']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => type = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priceList,
                            decoration: const InputDecoration(labelText: 'Default Pricing List'),
                            items: ['AGENCY', 'WHOLESALE', 'RETAIL'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => priceList = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN')),
                    const SizedBox(height: 12),
                    TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Delivery Address')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'City / Area'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: 'Delivery Route'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Limit (₹)'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final cust = Customer(
                    id: isEdit ? existing.id : 'C${DateTime.now().millisecondsSinceEpoch % 1000}',
                    code: isEdit ? existing.code : 'CUST-${DateTime.now().millisecondsSinceEpoch % 1000}',
                    name: nameCtrl.text.trim(),
                    type: type,
                    contact: contactCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    gstin: gstinCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    area: areaCtrl.text.trim(),
                    route: routeCtrl.text.trim(),
                    priceList: priceList,
                    creditLimit: double.tryParse(limitCtrl.text) ?? 100000.0,
                    outstanding: existing?.outstanding ?? 0.0,
                  );

                  await data.saveCustomer(cust);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(isEdit ? 'Save Changes' : 'Create Customer'),
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
    final allList = data.customers;
    final retailCount = allList.where((c) => c.priceList == 'RETAIL' || c.type == 'Retail Store' || c.type == 'Supermarket').length;
    final dealerCount = allList.where((c) => c.priceList == 'AGENCY' || c.priceList == 'WHOLESALE' || c.type == 'Wholesaler' || c.type == 'Distributor').length;

    final customers = allList.where((c) {
      if (_customerSegment == 'RETAIL') {
        if (c.priceList != 'RETAIL' && c.type != 'Retail Store' && c.type != 'Supermarket') return false;
      } else if (_customerSegment == 'DEALERS') {
        if (c.priceList != 'AGENCY' && c.priceList != 'WHOLESALE' && c.type != 'Wholesaler' && c.type != 'Distributor') return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.contact.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.area.toLowerCase().contains(q) ||
          c.route.toLowerCase().contains(q);
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
              hint: 'Search customers by store name, contact, area, route...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            actionWidget: GoldButton(
              icon: Icons.person_add,
              label: 'Add Customer',
              height: 46,
              onPressed: () => _showAddCustomerDialog(context),
            ),
          ),
          const SizedBox(height: 12),

          // SEGMENTED TABS: All, Regular Retail, Dealers & Wholesale
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegmentTab('ALL', 'All Customers (${allList.length})'),
                _buildSegmentTab('RETAIL', 'Regular / Retail ($retailCount)'),
                _buildSegmentTab('DEALERS', 'Dealers & Agencies ($dealerCount)'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: customers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final c = customers[idx];
                  final hasOverdue = c.outstanding > 0;

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
                                color: hasOverdue ? AppColors.warningBg : AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.storefront_outlined, color: hasOverdue ? AppColors.warning : AppColors.forestMedium, size: 20),
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
                                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      StatusBadge(label: c.type, tone: BadgeTone.neutral),
                                      StatusBadge(label: c.priceList, tone: BadgeTone.gold),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Contact: ${c.contact} (${c.phone})',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.forestLight),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showAddCustomerDialog(context, c),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Route: ${c.route} · Area: ${c.area} · GST: ${c.gstin.isNotEmpty ? c.gstin : "URP"}',
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
                              Text('Credit Limit: ${AppFormatters.inr(c.creditLimit, decimals: false)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                'Outstanding: ${AppFormatters.inr(c.outstanding)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: hasOverdue ? AppColors.danger : AppColors.success,
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

  Widget _buildSegmentTab(String key, String label) {
    final isSelected = _customerSegment == key;
    return InkWell(
      onTap: () => setState(() => _customerSegment = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forestMedium : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
