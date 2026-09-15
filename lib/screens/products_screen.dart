import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/file_download_helper.dart';
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
    final codeCtrl = TextEditingController(text: existing?.code ?? 'PRD-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final hsnCtrl = TextEditingController(text: existing?.hsn ?? '1508');
    final costCtrl = TextEditingController(text: existing?.cost.toStringAsFixed(0) ?? '150');
    final agencyCtrl = TextEditingController(text: existing?.agencyRate.toStringAsFixed(0) ?? '170');
    final wholesaleCtrl = TextEditingController(text: existing?.wholesaleRate.toStringAsFixed(0) ?? '180');
    final retailCtrl = TextEditingController(text: existing?.retailRate.toStringAsFixed(0) ?? '190');
    final mrpCtrl = TextEditingController(text: existing != null ? existing.mrp.toStringAsFixed(0) : '210');
    final stockCtrl = TextEditingController(text: existing?.stock.toStringAsFixed(0) ?? '100');
    final minStockCtrl = TextEditingController(text: existing?.minStock.toStringAsFixed(0) ?? '20');
    final gstCtrl = TextEditingController(text: existing?.gst.toStringAsFixed(0) ?? '5');

    String brandId = existing?.brandId ?? (data.brands.isNotEmpty ? data.brands[0].id : 'B1');
    String oilType = existing?.oilType ?? AppConstants.oilTypes[0];
    String pack = existing?.pack ?? '1 L';
    String unit = existing?.unit ?? 'Bottle';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isSmall = MediaQuery.of(ctx).size.width < 640;

          InputDecoration inputDec(String label, {String? prefixText, String? hintText}) {
            return InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              hintText: hintText,
              prefixText: prefixText,
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
            );
          }

          Widget sectionBanner(String title, IconData icon) {
            return Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.goldDeep),
                  const SizedBox(width: 6),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forestDark, letterSpacing: 0.5),
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isEdit ? AppColors.forestLight : AppColors.gold).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(isEdit ? Icons.edit_note : Icons.add_business, color: isEdit ? AppColors.forestDark : AppColors.goldDeep, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Product Master' : 'Add New Product Master',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: AppColors.textPrimary),
                      ),
                      Text(
                        isEdit
                            ? 'Editing SKU: ${existing.code} · ${existing.name}'
                            : 'Fill in specifications, tier pricing (AWR), and initial inventory.',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 680, maxHeight: MediaQuery.of(ctx).size.height * 0.78),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Basic Specifications
                    sectionBanner('1. Basic & Brand Specifications', Icons.category_outlined),
                    if (isSmall) ...[
                      TextField(controller: nameCtrl, decoration: inputDec('Product Name *', hintText: 'e.g., KKK Pure Groundnut Oil 1L')),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: brandId,
                        decoration: inputDec('Brand *'),
                        items: data.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) { if (val != null) setDialogState(() => brandId = val); },
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(flex: 3, child: TextField(controller: nameCtrl, decoration: inputDec('Product Name *', hintText: 'e.g., KKK Pure Groundnut Oil 1L'))),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: brandId,
                              decoration: inputDec('Brand *'),
                              items: data.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) { if (val != null) setDialogState(() => brandId = val); },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: oilType,
                            decoration: inputDec('Oil Type'),
                            items: AppConstants.oilTypes.map((ot) => DropdownMenuItem(value: ot, child: Text(ot, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) { if (val != null) setDialogState(() => oilType = val); },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: pack,
                            decoration: inputDec('Pack Size'),
                            items: AppConstants.packSizes.map((ps) => DropdownMenuItem(value: ps, child: Text(ps, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) { if (val != null) setDialogState(() => pack = val); },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: unit,
                            decoration: inputDec('Unit Type'),
                            items: AppConstants.unitTypes.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) { if (val != null) setDialogState(() => unit = val); },
                          ),
                        ),
                      ],
                    ),

                    // Section 2: Identification & Taxation
                    sectionBanner('2. Identification & Taxation', Icons.qr_code_2_outlined),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: codeCtrl, decoration: inputDec('Product Code *'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: skuCtrl, decoration: inputDec('SKU / Barcode'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: hsnCtrl, decoration: inputDec('HSN Code'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: gstCtrl, keyboardType: TextInputType.number, decoration: inputDec('GST (%)', hintText: '5'))),
                      ],
                    ),

                    // Section 3: Tier Pricing Matrix (AWR & MRP)
                    sectionBanner('3. Tier Pricing Matrix (AWR Rates & MRP in ₹)', Icons.currency_rupee),
                    const Text(
                      'Changes to Agency, Wholesale, or Retail rates are automatically audited in Price History with effective dates.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    if (isSmall) ...[
                      Row(
                        children: [
                          Expanded(child: TextField(controller: costCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Cost (₹)', prefixText: '₹ '))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: mrpCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('MRP (₹)', prefixText: '₹ '))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: agencyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Agency (₹)', prefixText: '₹ '))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: wholesaleCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Wholesale (₹)', prefixText: '₹ '))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: retailCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Retail (₹)', prefixText: '₹ '))),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: TextField(controller: costCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Cost (₹)', prefixText: '₹ '))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: agencyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Agency (₹) [A]', prefixText: '₹ '))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: wholesaleCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Wholesale (₹) [W]', prefixText: '₹ '))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: retailCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Retail (₹) [R]', prefixText: '₹ '))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: mrpCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('MRP (₹)', prefixText: '₹ '))),
                        ],
                      ),
                    ],

                    // Section 4: Inventory & Alerts
                    sectionBanner('4. Inventory & Reorder Levels', Icons.warehouse_outlined),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: stockCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Current Stock Units *'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: minStockCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('Min Alert Stock Threshold *'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: Text(isEdit ? 'Save Changes & Sync Rates' : 'Create Product Master'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product name is required.')));
                    return;
                  }
                  final retail = double.tryParse(retailCtrl.text) ?? 0.0;
                  final mrpVal = double.tryParse(mrpCtrl.text) ?? (retail * 1.1);
                  final prod = Product(
                    id: isEdit ? existing.id : 'P-${DateTime.now().millisecondsSinceEpoch}',
                    code: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'PRD-${DateTime.now().millisecondsSinceEpoch % 1000}',
                    brandId: brandId,
                    name: nameCtrl.text.trim(),
                    category: 'Edible Oils',
                    oilType: oilType,
                    pack: pack,
                    unit: unit,
                    sku: skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : codeCtrl.text.trim(),
                    hsn: hsnCtrl.text.trim().isNotEmpty ? hsnCtrl.text.trim() : '1508',
                    gst: double.tryParse(gstCtrl.text) ?? 5.0,
                    cost: double.tryParse(costCtrl.text) ?? 0.0,
                    price: retail,
                    agencyRate: double.tryParse(agencyCtrl.text) ?? 0.0,
                    wholesaleRate: double.tryParse(wholesaleCtrl.text) ?? 0.0,
                    retailRate: retail,
                    mrp: mrpVal,
                    minStock: double.tryParse(minStockCtrl.text) ?? 20.0,
                    stock: double.tryParse(stockCtrl.text) ?? 0.0,
                    status: 'Active',
                    updatedDate: AppFormatters.todayISO(),
                  );

                  await data.saveProduct(prod, updatedBy: isEdit ? 'Admin Edit' : 'Admin Create');
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Product "${prod.name}" updated successfully!' : 'Product "${prod.name}" created!'),
                        backgroundColor: AppColors.forestDark,
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

  void _showQuickPriceEditDialog(BuildContext context, Product p) {
    final data = context.read<DataProvider>();
    final agencyCtrl = TextEditingController(text: p.agencyRate.toStringAsFixed(0));
    final wholesaleCtrl = TextEditingController(text: p.wholesaleRate.toStringAsFixed(0));
    final retailCtrl = TextEditingController(text: p.retailRate.toStringAsFixed(0));
    final mrpCtrl = TextEditingController(text: p.mrp.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildPriceRow(String title, double oldRate, TextEditingController ctrl, Color color) {
            final currentVal = double.tryParse(ctrl.text) ?? oldRate;
            final diff = currentVal - oldRate;
            final isDiff = diff.abs() > 0.001;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                        Text('Current: ₹${oldRate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: isDiff
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: diff > 0 ? const Color(0xFF16A34A).withValues(alpha: 0.1) : const Color(0xFFDC2626).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              diff > 0 ? '▲ +₹${diff.toStringAsFixed(0)}' : '▼ -₹${(-diff).toStringAsFixed(0)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: diff > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                          )
                        : const Text('No change', style: TextStyle(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.price_change, color: AppColors.goldDeep, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Update Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${p.name} (${p.code} · ${p.pack})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Change rates below. Price differences are recorded to Price History with date.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  buildPriceRow('Agency Rate', p.agencyRate, agencyCtrl, const Color(0xFFD97706)),
                  buildPriceRow('Wholesale Rate', p.wholesaleRate, wholesaleCtrl, const Color(0xFF2563EB)),
                  buildPriceRow('Retail Rate', p.retailRate, retailCtrl, const Color(0xFF16A34A)),
                  buildPriceRow('MRP Rate', p.mrp, mrpCtrl, const Color(0xFF7C3AED)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Save & Log to History'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestDark, foregroundColor: Colors.white),
                onPressed: () async {
                  final newRetail = double.tryParse(retailCtrl.text) ?? p.retailRate;
                  final updated = p.copyWith(
                    agencyRate: double.tryParse(agencyCtrl.text) ?? p.agencyRate,
                    wholesaleRate: double.tryParse(wholesaleCtrl.text) ?? p.wholesaleRate,
                    retailRate: newRetail,
                    price: newRetail,
                    mrp: double.tryParse(mrpCtrl.text) ?? p.mrp,
                    updatedDate: AppFormatters.todayISO(),
                  );
                  await data.saveProduct(updated, updatedBy: 'Quick Price Edit');
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rates updated for ${p.name} and logged in Price History!'),
                        backgroundColor: AppColors.forestDark,
                        duration: const Duration(seconds: 3),
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

  void _exportProducts(BuildContext context, List<Product> products, {required bool isExcel, required Map<String, String> brandMap}) {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products to export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    // Prepend UTF-8 BOM so Microsoft Excel cleanly parses Unicode and commas without garbled characters
    buffer.write('\uFEFF');

    // Header row
    buffer.writeln('Product Code,Product Name,Brand,Oil Type,Pack Size,Unit,Cost Rate (INR),Agency Rate (INR),Wholesale Rate (INR),Retail Rate (INR),MRP (INR),Current Stock,Min Stock Alert,HSN Code,GST Rate (%),Status,Last Updated');

    for (final p in products) {
      String escape(dynamic val) {
        final str = (val ?? '').toString().replaceAll('"', '""');
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          return '"$str"';
        }
        return str;
      }

      final brandName = brandMap[p.brandId] ?? p.brandId;
      buffer.writeln([
        escape(p.code),
        escape(p.name),
        escape(brandName),
        escape(p.oilType),
        escape(p.pack),
        escape(p.unit),
        p.cost.toStringAsFixed(2),
        p.agencyRate.toStringAsFixed(2),
        p.wholesaleRate.toStringAsFixed(2),
        p.retailRate.toStringAsFixed(2),
        p.mrp.toStringAsFixed(2),
        p.stock.toStringAsFixed(0),
        p.minStock.toStringAsFixed(0),
        escape(p.hsn),
        p.gst.toStringAsFixed(0),
        escape(p.status),
        escape(p.updatedDate),
      ].join(','));
    }

    final dateStr = AppFormatters.todayISO();
    final fileName = 'kkk_products_${isExcel ? "excel_" : ""}$dateStr.csv';

    FileDownloadHelper.downloadFile(
      content: buffer.toString(),
      fileName: fileName,
      mimeType: 'text/csv',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isExcel ? Icons.table_chart : Icons.file_download, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Exported ${products.length} products as ${isExcel ? "Excel CSV" : "CSV"} ($fileName)')),
          ],
        ),
        backgroundColor: AppColors.forestDark,
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final data = context.read<DataProvider>();
    final textCtrl = TextEditingController();
    String parseStatus = '';
    List<Product> parsedProducts = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void parseInput(String text) {
            final lines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
            if (lines.isEmpty) {
              setDialogState(() {
                parsedProducts = [];
                parseStatus = 'Paste or type product data below to preview.';
              });
              return;
            }

            final List<Product> result = [];
            int lineNo = 0;

            for (final rawLine in lines) {
              lineNo++;
              final lower = rawLine.toLowerCase();
              if (lower.startsWith('code') || lower.startsWith('product') || lower.contains('product name') || lower.startsWith('#')) {
                continue;
              }

              final List<String> parts = rawLine.contains('\t')
                  ? rawLine.split('\t').map((p) => p.trim()).toList()
                  : rawLine.split(',').map((p) => p.trim().replaceAll('"', '')).toList();

              if (parts.length < 2) continue;

              final code = parts[0].isNotEmpty ? parts[0] : 'PRD-${DateTime.now().millisecondsSinceEpoch % 10000}-$lineNo';
              final name = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'Imported Product $lineNo';

              String brandId = data.brands.isNotEmpty ? data.brands[0].id : 'B1';
              if (parts.length > 2 && parts[2].isNotEmpty) {
                final match = data.brands.firstWhere(
                  (b) => b.name.toLowerCase() == parts[2].toLowerCase() || b.id.toLowerCase() == parts[2].toLowerCase(),
                  orElse: () => data.brands[0],
                );
                brandId = match.id;
              }

              final oilType = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : 'Groundnut';
              final pack = parts.length > 4 && parts[4].isNotEmpty ? parts[4] : '1 L';
              final unit = parts.length > 5 && parts[5].isNotEmpty ? parts[5] : 'Bottle';
              final cost = parts.length > 6 ? (double.tryParse(parts[6]) ?? 150.0) : 150.0;
              final agency = parts.length > 7 ? (double.tryParse(parts[7]) ?? 170.0) : 170.0;
              final wholesale = parts.length > 8 ? (double.tryParse(parts[8]) ?? 180.0) : 180.0;
              final retail = parts.length > 9 ? (double.tryParse(parts[9]) ?? 190.0) : 190.0;
              final mrp = parts.length > 10 ? (double.tryParse(parts[10]) ?? (retail * 1.1)) : (retail * 1.1);
              final stock = parts.length > 11 ? (double.tryParse(parts[11]) ?? 100.0) : 100.0;
              final minStock = parts.length > 12 ? (double.tryParse(parts[12]) ?? 20.0) : 20.0;
              final hsn = parts.length > 13 && parts[13].isNotEmpty ? parts[13] : '1508';
              final gst = parts.length > 14 ? (double.tryParse(parts[14]) ?? 5.0) : 5.0;

              result.add(Product(
                id: 'P-IMP-${code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
                code: code,
                brandId: brandId,
                name: name,
                category: 'Edible Oils',
                oilType: oilType,
                pack: pack,
                unit: unit,
                sku: code,
                hsn: hsn,
                gst: gst,
                cost: cost,
                price: retail,
                agencyRate: agency,
                wholesaleRate: wholesale,
                retailRate: retail,
                mrp: mrp,
                minStock: minStock,
                stock: stock,
                status: 'Active',
                updatedDate: AppFormatters.todayISO(),
              ));
            }

            setDialogState(() {
              parsedProducts = result;
              parseStatus = 'Parsed ${result.length} valid product(s) ready to import.';
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.file_upload, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Import Products (Excel / CSV)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                      Text('Paste table rows directly or download the sample format.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 14),
                          label: const Text('Download Sample CSV Template', style: TextStyle(fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          onPressed: () {
                            const sampleCsv = '\uFEFFCode,Name,Brand,OilType,Pack,Unit,Cost,AgencyRate,WholesaleRate,RetailRate,MRP,Stock,MinStock,HSN,GST\n'
                                'KKK-GND-1L,KKK Pure Groundnut Oil 1L,KKK Brand,Groundnut,1 L,Bottle,155,172,182,192,215,150,30,1508,5\n'
                                'KKK-SES-500M,KKK Gingelly Sesame Oil 500ml,KKK Brand,Gingelly,500 ml,Pouch,110,122,130,140,155,200,40,1515,5\n'
                                'DEVI-COC-1L,Devi Brand Cold Pressed Coconut Oil 1L,Devi,Coconut,1 L,Bottle,180,200,210,225,250,80,25,1513,5';
                            FileDownloadHelper.downloadFile(
                              content: sampleCsv,
                              fileName: 'product_import_sample_template.csv',
                              mimeType: 'text/csv',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sample CSV template downloaded!')),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.content_paste_go, size: 14),
                          label: const Text('Load Sample Data', style: TextStyle(fontSize: 11.5)),
                          onPressed: () {
                            const sampleText = 'KKK-GND-1L,KKK Pure Groundnut Oil 1L,KKK Brand,Groundnut,1 L,Bottle,155,172,182,192,215,150,30,1508,5\n'
                                'KKK-SES-500M,KKK Gingelly Sesame Oil 500ml,KKK Brand,Gingelly,500 ml,Pouch,110,122,130,140,155,200,40,1515,5\n'
                                'DEVI-COC-1L,Devi Brand Cold Pressed Coconut Oil 1L,Devi,Coconut,1 L,Bottle,180,200,210,225,250,80,25,1513,5';
                            textCtrl.text = sampleText;
                            parseInput(sampleText);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(6)),
                      child: const Text(
                        'Columns expected in order:\n'
                        'Code, Name, Brand, OilType, Pack, Unit, Cost, AgencyRate, WholesaleRate, RetailRate, MRP, Stock, MinStock, HSN, GST',
                        style: TextStyle(fontSize: 11, color: AppColors.forestDark, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: textCtrl,
                      maxLines: 7,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Paste CSV or Excel tab-separated rows here...',
                        hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) => parseInput(val),
                    ),
                    const SizedBox(height: 10),
                    if (parseStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: parsedProducts.isNotEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: parsedProducts.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        ),
                        child: Text(
                          parseStatus,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: parsedProducts.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    if (parsedProducts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Preview (Ready to Import):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 140),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(6)),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: parsedProducts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final prod = parsedProducts[i];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text('${prod.name} (${prod.code})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              subtitle: Text('Rates: A:₹${prod.agencyRate.toInt()} | W:₹${prod.wholesaleRate.toInt()} | R:₹${prod.retailRate.toInt()} | Stock: ${prod.stock.toInt()}', style: const TextStyle(fontSize: 10.5)),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: Text('Import ${parsedProducts.length} Products & Sync to Firebase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: parsedProducts.isEmpty
                    ? null
                    : () async {
                        final importedCount = await data.bulkImportProducts(parsedProducts, updatedBy: 'Excel/CSV Import');
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully imported $importedCount products to Master Catalogue and synced to Firebase!'),
                              backgroundColor: AppColors.forestDark,
                              duration: const Duration(seconds: 4),
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
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.file_upload_outlined, size: 15, color: AppColors.forestDark),
              label: Text(isMobile ? 'Import' : 'Import Excel/CSV', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forestDark)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showImportDialog(context),
            ),
            PopupMenuButton<String>(
              tooltip: 'Export Products',
              onSelected: (val) {
                if (val == 'EXCEL') _exportProducts(context, products, isExcel: true, brandMap: brandMap);
                if (val == 'CSV') _exportProducts(context, products, isExcel: false, brandMap: brandMap);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'EXCEL',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart_outlined, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Text('Export to Excel (.csv)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'CSV',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 18),
                      SizedBox(width: 8),
                      Text('Export to CSV (.csv)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.file_download_outlined, size: 15, color: AppColors.textPrimary),
                    const SizedBox(width: 4),
                    Text(isMobile ? 'Export' : 'Export Data', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            GoldButton(
              icon: Icons.add,
              label: isMobile ? 'Add' : 'Add Product',
              height: isMobile ? 36 : 38,
              onPressed: () => _showAddEditDialog(context),
            ),
          ],
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
                                      _buildRatePill('A', p.agencyRate, _selectedRateType == 'AGENCY', const Color(0xFFD97706), onTap: () => _showQuickPriceEditDialog(context, p)),
                                      const SizedBox(width: 4),
                                      _buildRatePill('W', p.wholesaleRate, _selectedRateType == 'WHOLESALE', const Color(0xFF2563EB), onTap: () => _showQuickPriceEditDialog(context, p)),
                                      const SizedBox(width: 4),
                                      _buildRatePill('R', p.retailRate, _selectedRateType == 'RETAIL', const Color(0xFF1F8A5B), onTap: () => _showQuickPriceEditDialog(context, p)),
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
                                        icon: const Icon(Icons.price_change_outlined, size: 16, color: AppColors.goldDeep),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Quick Price Edit (AWR)',
                                        onPressed: () => _showQuickPriceEditDialog(context, p),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.forestLight),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit Full Product',
                                        onPressed: () => _showAddEditDialog(context, p),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete Product',
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
                    _buildRatePill('A', p.agencyRate, _selectedRateType == 'AGENCY', const Color(0xFFD97706), onTap: () => _showQuickPriceEditDialog(context, p)),
                    _buildRatePill('W', p.wholesaleRate, _selectedRateType == 'WHOLESALE', const Color(0xFF2563EB), onTap: () => _showQuickPriceEditDialog(context, p)),
                    _buildRatePill('R', p.retailRate, _selectedRateType == 'RETAIL', const Color(0xFF1F8A5B), onTap: () => _showQuickPriceEditDialog(context, p)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.price_change_outlined, size: 15, color: AppColors.goldDeep),
                label: const Text('Update Rates', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.goldDeep)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showQuickPriceEditDialog(context, p),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.forestLight),
                tooltip: 'Edit Product',
                onPressed: () => _showAddEditDialog(context, p),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                tooltip: 'Delete Product',
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

  Widget _buildRatePill(String prefix, double rate, bool isSelected, Color activeColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
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
