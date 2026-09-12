import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/ui_components.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedBrandId = 'All';
  String _selectedOilType = 'All';
  String _selectedRateType = 'RETAIL'; // 'AGENCY', 'WHOLESALE', 'RETAIL'
  String _stockFilter = 'ALL'; // 'ALL', 'IN_STOCK', 'LOW_STOCK', 'OUT_OF_STOCK'

  void _showAddEditDialog(BuildContext context, [Product? existing]) {
    final data = context.read<DataProvider>();
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? 'PRD-${DateTime.now().millisecondsSinceEpoch % 1000}');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final hsnCtrl = TextEditingController(text: existing?.hsn ?? '1508');
    final costCtrl = TextEditingController(text: existing?.cost.toStringAsFixed(0) ?? '150');
    final agencyCtrl = TextEditingController(text: existing?.agencyRate.toStringAsFixed(0) ?? '170');
    final wholesaleCtrl = TextEditingController(text: existing?.wholesaleRate.toStringAsFixed(0) ?? '180');
    final retailCtrl = TextEditingController(text: existing?.retailRate.toStringAsFixed(0) ?? '190');
    final stockCtrl = TextEditingController(text: existing?.stock.toStringAsFixed(0) ?? '100');
    final minStockCtrl = TextEditingController(text: existing?.minStock.toStringAsFixed(0) ?? '20');

    String brandId = existing?.brandId ?? (data.brands.isNotEmpty ? data.brands[0].id : 'B1');
    String oilType = existing?.oilType ?? AppConstants.oilTypes[0];
    String pack = existing?.pack ?? '1 L';
    String unit = existing?.unit ?? 'Bottle';
    double gst = existing?.gst ?? 5.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Product' : 'Add New Product Master', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: brandId,
                            decoration: const InputDecoration(labelText: 'Brand'),
                            items: data.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => brandId = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: oilType,
                            decoration: const InputDecoration(labelText: 'Oil Type'),
                            items: AppConstants.oilTypes.map((ot) => DropdownMenuItem(value: ot, child: Text(ot))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => oilType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: pack,
                            decoration: const InputDecoration(labelText: 'Pack Size'),
                            items: AppConstants.packSizes.map((ps) => DropdownMenuItem(value: ps, child: Text(ps))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => pack = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: unit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: AppConstants.unitTypes.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => unit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU / Barcode'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: hsnCtrl, decoration: const InputDecoration(labelText: 'HSN'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Rate (₹)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: agencyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Agency (₹)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: wholesaleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wholesale (₹)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: retailCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Retail (₹)'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Stock'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: minStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Alert Stock'))),
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
                  final retail = double.tryParse(retailCtrl.text) ?? 0.0;
                  final prod = Product(
                    id: isEdit ? existing.id : 'P-${DateTime.now().millisecondsSinceEpoch}',
                    code: codeCtrl.text.trim(),
                    brandId: brandId,
                    name: nameCtrl.text.trim(),
                    category: 'Edible Oils',
                    oilType: oilType,
                    pack: pack,
                    unit: unit,
                    sku: skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : codeCtrl.text.trim(),
                    hsn: hsnCtrl.text.trim(),
                    gst: gst,
                    cost: double.tryParse(costCtrl.text) ?? 0.0,
                    price: retail,
                    agencyRate: double.tryParse(agencyCtrl.text) ?? 0.0,
                    wholesaleRate: double.tryParse(wholesaleCtrl.text) ?? 0.0,
                    retailRate: retail,
                    mrp: retail * 1.1,
                    minStock: double.tryParse(minStockCtrl.text) ?? 20.0,
                    stock: double.tryParse(stockCtrl.text) ?? 0.0,
                    status: 'Active',
                    updatedDate: AppFormatters.todayISO(),
                  );

                  await data.saveProduct(prod);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(isEdit ? 'Save Changes' : 'Create Product'),
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

    final totalCount = data.products.length;
    final inStockCount = data.products.where((p) => p.stock > p.minStock).length;
    final lowStockCount = data.products.where((p) => p.stock <= p.minStock && p.stock > 0).length;
    final outOfStockCount = data.products.where((p) => p.stock <= 0).length;

    final products = data.products.where((p) {
      if (_selectedBrandId != 'All' && p.brandId != _selectedBrandId) return false;
      if (_selectedOilType != 'All' && p.oilType != _selectedOilType) return false;
      if (_stockFilter == 'IN_STOCK' && p.stock <= p.minStock) return false;
      if (_stockFilter == 'LOW_STOCK' && (p.stock > p.minStock || p.stock <= 0)) return false;
      if (_stockFilter == 'OUT_OF_STOCK' && p.stock > 0) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.oilType.toLowerCase().contains(q);
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Master',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.products.length} Central Master Products — manage SKUs, AWR rates, HSN codes, and inventory levels.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              GoldButton(
                icon: Icons.add,
                label: 'Add Product',
                height: 40,
                onPressed: () => _showAddEditDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Toolbar with Search, Rate switch pills, Brand filter, and Oil filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                // Search Input
                SizedBox(
                  width: isMobile ? double.infinity : 240,
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search product, SKU, code…',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold)),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // Rate Selector Pills
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('RATE:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                      ),
                      ...['AGENCY', 'WHOLESALE', 'RETAIL'].map((rt) {
                        final isSel = _selectedRateType == rt;
                        return InkWell(
                          onTap: () => setState(() => _selectedRateType = rt),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.gold : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rt,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSel ? AppColors.forestDark : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Brand Selector Dropdown
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBrandId,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Brands')),
                        ...data.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBrandId = val);
                      },
                    ),
                  ),
                ),

                // Oil Type Selector Dropdown
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedOilType,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Oil Types')),
                        ...AppConstants.oilTypes.map((ot) => DropdownMenuItem(value: ot, child: Text(ot))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedOilType = val);
                      },
                    ),
                  ),
                ),

                // Stock Status Selector Dropdown
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _stockFilter,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Stock')),
                        DropdownMenuItem(value: 'IN_STOCK', child: Text('In Stock')),
                        DropdownMenuItem(value: 'LOW_STOCK', child: Text('Low Stock Alert')),
                        DropdownMenuItem(value: 'OUT_OF_STOCK', child: Text('Out of Stock')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _stockFilter = val);
                      },
                    ),
                  ),
                ),

                Text(
                  '${products.length} shown',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Products List / Table
          Expanded(
            child: Card(
              child: products.isEmpty
                  ? const Center(child: Text('No products found matching criteria.', style: TextStyle(color: AppColors.textSecondary)))
                  : isMobile
                      ? ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final p = products[idx];
                            final isLow = p.stock <= p.minStock;
                            final curRate = _getEffectiveRate(p, _selectedRateType);

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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${p.code} · ${brandMap[p.brandId] ?? ""} · ${p.pack}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(
                                        label: '${p.stock.toInt()} ${p.unit}s',
                                        tone: isLow ? BadgeTone.danger : BadgeTone.success,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWarm,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Cost: ₹${p.cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        Text(
                                          '$_selectedRateType: ₹${curRate.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.goldDeep),
                                        ),
                                        Text('MRP: ₹${p.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.forestLight),
                                        onPressed: () => _showAddEditDialog(context, p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                        onPressed: () async {
                                          await data.deleteProduct(p.id);
                                        },
                                      ),
                                    ],
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
                              columns: [
                                const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Pack / Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Cost (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(
                                  label: Text(
                                    '$_selectedRateType Rate (₹)',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldDeep),
                                  ),
                                ),
                                const DataColumn(label: Text('MRP (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('GST', style: TextStyle(fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: List.generate(products.length, (idx) {
                                final p = products[idx];
                                final isLow = p.stock <= p.minStock;
                                final curRate = _getEffectiveRate(p, _selectedRateType);

                                return DataRow(
                                  cells: [
                                    DataCell(Text('${idx + 1}')),
                                    DataCell(
                                      Text(
                                        p.code,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.goldDeep),
                                      ),
                                    ),
                                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(brandMap[p.brandId] ?? '-')),
                                    DataCell(Text('${p.pack} (${p.unit})')),
                                    DataCell(Text('₹${p.cost.toStringAsFixed(0)}')),
                                    DataCell(
                                      Text(
                                        '₹${curRate.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldDeep, fontSize: 13.5),
                                      ),
                                    ),
                                    DataCell(Text('₹${p.mrp.toStringAsFixed(0)}')),
                                    DataCell(
                                      StatusBadge(
                                        label: '${p.stock.toInt()} ${p.unit}',
                                        tone: isLow ? BadgeTone.danger : BadgeTone.success,
                                      ),
                                    ),
                                    DataCell(Text('${p.gst.toStringAsFixed(0)}%')),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.forestLight),
                                            onPressed: () => _showAddEditDialog(context, p),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                            onPressed: () async {
                                              await data.deleteProduct(p.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  double _getEffectiveRate(Product p, String rateType) {
    switch (rateType) {
      case 'AGENCY':
        return p.agencyRate > 0 ? p.agencyRate : p.price;
      case 'WHOLESALE':
        return p.wholesaleRate > 0 ? p.wholesaleRate : p.price;
      case 'RETAIL':
      default:
        return p.retailRate > 0 ? p.retailRate : p.price;
    }
  }
}
