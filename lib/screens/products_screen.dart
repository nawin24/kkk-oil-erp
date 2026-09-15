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

    final pageHeader = Row(
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
          height: isMobile ? 38 : 40,
          onPressed: () => _showAddEditDialog(context),
        ),
      ],
    );

    final kpiCards = _buildStockKpiCards(
      totalCount: totalCount,
      inStockCount: inStockCount,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      isMobile: isMobile,
    );

    final toolbar = Container(
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
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text('RATE:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                  ),
                  ...['AGENCY', 'WHOLESALE', 'RETAIL'].map((rt) {
                    final isSel = _selectedRateType == rt;
                    return InkWell(
                      onTap: () => setState(() => _selectedRateType = rt),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

          // Oil Type Dropdown
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
                  ...['Groundnut', 'Gingelly', 'Coconut', 'Castor', 'Sunflower'].map((t) => DropdownMenuItem(value: t, child: Text(t))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedOilType = val);
                },
              ),
            ),
          ),

          // Stock Status Filter Dropdown
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
    );

    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pageHeader,
            const SizedBox(height: 14),
            kpiCards,
            const SizedBox(height: 14),
            toolbar,
            const SizedBox(height: 14),
            if (products.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text('No products found matching criteria.', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...products.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildMobileProductCard(p, brandMap, data),
                  )),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageHeader,
          const SizedBox(height: 14),
          kpiCards,
          const SizedBox(height: 14),
          toolbar,
          const SizedBox(height: 14),
          // Products Desktop Table
          Expanded(
            child: Card(
              child: products.isEmpty
                  ? const Center(child: Text('No products found matching criteria.', style: TextStyle(color: AppColors.textSecondary)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 36,
                          dataRowMinHeight: 38,
                          dataRowMaxHeight: 44,
                          horizontalMargin: 12,
                          columnSpacing: 14,
                          headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
                          columns: const [
                            DataColumn(label: Text('#', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Code', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Product Name', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Brand', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Pack / Unit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Cost (₹)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Selling Rates (AWR)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.goldDeep))),
                            DataColumn(label: Text('MRP (₹)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Stock', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('GST', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold))),
                          ],
                          rows: List.generate(products.length, (idx) {
                            final p = products[idx];
                            final isLow = p.stock <= p.minStock;

                            return DataRow(
                              cells: [
                                DataCell(Text('${idx + 1}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                                DataCell(
                                  Text(
                                    p.code,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.goldDeep),
                                  ),
                                ),
                                DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataCell(Text(brandMap[p.brandId] ?? '-', style: const TextStyle(fontSize: 11.5))),
                                DataCell(Text('${p.pack} (${p.unit})', style: const TextStyle(fontSize: 11.5))),
                                DataCell(Text('₹${p.cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11.5))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildRatePill('A', p.agencyRate, _selectedRateType == 'AGENCY', const Color(0xFFD97706)),
                                      const SizedBox(width: 4),
                                      _buildRatePill('W', p.wholesaleRate, _selectedRateType == 'WHOLESALE', const Color(0xFF2563EB)),
                                      const SizedBox(width: 4),
                                      _buildRatePill('R', p.retailRate, _selectedRateType == 'RETAIL', const Color(0xFF1F8A5B)),
                                    ],
                                  ),
                                ),
                                DataCell(Text('₹${p.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11.5))),
                                DataCell(
                                  StatusBadge(
                                    label: '${p.stock.toInt()} ${p.unit}',
                                    tone: isLow ? BadgeTone.danger : BadgeTone.success,
                                  ),
                                ),
                                DataCell(Text('${p.gst.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11.5))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.forestLight),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showAddEditDialog(context, p),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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

  Widget _buildMobileProductCard(Product p, Map<String, String> brandMap, DataProvider data) {
    final isLow = p.stock <= p.minStock;

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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cost: ₹${p.cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('MRP: ₹${p.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildRatePill('A', p.agencyRate, _selectedRateType == 'AGENCY', const Color(0xFFD97706)),
                    _buildRatePill('W', p.wholesaleRate, _selectedRateType == 'WHOLESALE', const Color(0xFF2563EB)),
                    _buildRatePill('R', p.retailRate, _selectedRateType == 'RETAIL', const Color(0xFF1F8A5B)),
                  ],
                ),
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
  }

  Widget _buildRatePill(String prefix, double rate, bool isSelected, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF5F6F4),
        border: Border.all(color: isSelected ? activeColor : const Color(0xFFE7E9E5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$prefix: ₹${rate.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? activeColor : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildStockKpiCards({
    required int totalCount,
    required int inStockCount,
    required int lowStockCount,
    required int outOfStockCount,
    required bool isMobile,
  }) {
    final cards = [
      _buildSingleKpiCard(
        title: 'Total Stock / SKUs',
        count: totalCount,
        label: 'Central Master Catalog',
        icon: Icons.inventory_2_outlined,
        filterKey: 'ALL',
        color: const Color(0xFF4B5563),
        bgColor: const Color(0xFFF9FAFB),
        activeBorder: const Color(0xFFD97706),
        isMobile: isMobile,
      ),
      _buildSingleKpiCard(
        title: 'Available / In Stock',
        count: inStockCount,
        label: 'Healthy Warehouses',
        icon: Icons.check_circle_outline,
        filterKey: 'IN_STOCK',
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFFF0FDF4),
        activeBorder: const Color(0xFF16A34A),
        isMobile: isMobile,
      ),
      _buildSingleKpiCard(
        title: 'Low Stock Alerts',
        count: lowStockCount,
        label: 'Immediate Reorder Due',
        icon: Icons.warning_amber_rounded,
        filterKey: 'LOW_STOCK',
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        activeBorder: const Color(0xFFD97706),
        isMobile: isMobile,
      ),
      _buildSingleKpiCard(
        title: 'Out of Stock',
        count: outOfStockCount,
        label: 'Zero Available Units',
        icon: Icons.remove_circle_outline,
        filterKey: 'OUT_OF_STOCK',
        color: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
        activeBorder: const Color(0xFFDC2626),
        isMobile: isMobile,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.7,
        children: cards,
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
    );
  }

  Widget _buildSingleKpiCard({
    required String title,
    required int count,
    required String label,
    required IconData icon,
    required String filterKey,
    required Color color,
    required Color bgColor,
    required Color activeBorder,
    required bool isMobile,
  }) {
    final isSelected = _stockFilter == filterKey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _stockFilter = isSelected && filterKey != 'ALL' ? 'ALL' : filterKey;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 14,
            vertical: isMobile ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeBorder : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              else
                const BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 32 : 38,
                height: isMobile ? 32 : 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isMobile ? 17 : 20),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? color : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 11.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 10,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
