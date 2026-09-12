import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/sales_order.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/invoice_print_dialog.dart';

class CounterScreen extends StatefulWidget {
  final String billingType; // 'GST' or 'NON_GST'

  const CounterScreen({super.key, this.billingType = 'GST'});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  PricingType _selectedPricing = PricingType.retail;
  Customer? _selectedCustomer;
  String _paymentMode = 'Cash';
  String _payStatus = 'Paid';

  // Cart items: Map<productId, {product, qty, rate, discount}>
  final List<InvoiceItem> _cartItems = [];
  bool _isSaving = false;
  final Set<String> _submittedVouchers = {};
  SalesOrder? _lastSavedOrder;
  Customer? _lastSavedCustomer;

  void _addProductToCart(Product p) {
    final existingIdx = _cartItems.indexWhere((it) => it.productId == p.id);
    final rate = p.getRateFor(_selectedPricing);

    if (existingIdx >= 0) {
      final current = _cartItems[existingIdx];
      final newQty = current.qty + 1;
      _updateCartItem(existingIdx, newQty, current.discPercent);
    } else {
      final gstRate = widget.billingType == 'GST' ? p.gst : 0.0;
      final lineGross = rate * 1.0;
      final taxable = widget.billingType == 'GST' ? lineGross / (1 + (gstRate / 100)) : lineGross;
      final gstAmt = lineGross - taxable;

      setState(() {
        _cartItems.add(
          InvoiceItem(
            productId: p.id,
            productCode: p.code,
            productName: p.name,
            unit: p.unit,
            qty: 1.0,
            rate: rate,
            mrp: p.mrp,
            pricingType: _selectedPricing,
            appliedRate: rate,
            discPercent: 0.0,
            discAmount: 0.0,
            taxableAmount: taxable,
            gstRate: gstRate,
            gstAmount: gstAmt,
            finalAmount: lineGross,
          ),
        );
      });
    }
  }

  void _updateCartItem(int index, double newQty, double discPercent) {
    if (newQty <= 0) {
      setState(() {
        _cartItems.removeAt(index);
      });
      return;
    }

    final item = _cartItems[index];
    final gross = item.rate * newQty;
    final discAmt = gross * (discPercent / 100);
    final netLine = gross - discAmt;
    final taxable = widget.billingType == 'GST' ? netLine / (1 + (item.gstRate / 100)) : netLine;
    final gstAmt = netLine - taxable;

    setState(() {
      _cartItems[index] = InvoiceItem(
        productId: item.productId,
        productCode: item.productCode,
        productName: item.productName,
        unit: item.unit,
        qty: newQty,
        rate: item.rate,
        mrp: item.mrp,
        pricingType: item.pricingType,
        appliedRate: item.rate,
        discPercent: discPercent,
        discAmount: discAmt,
        taxableAmount: taxable,
        gstRate: item.gstRate,
        gstAmount: gstAmt,
        finalAmount: netLine,
      );
    });
  }

  void _clearBill() {
    setState(() {
      _cartItems.clear();
      _searchCtrl.clear();
      _searchQuery = '';
      _selectedCustomer = null;
      _paymentMode = 'Cash';
      _payStatus = 'Paid';
    });
  }

  void _previewPrintCurrentBill() {
    if (_cartItems.isEmpty) return;
    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    double totalTaxable = 0.0;
    double totalGst = 0.0;
    double totalNet = 0.0;

    for (final it in _cartItems) {
      totalTaxable += it.taxableAmount;
      totalGst += it.gstAmount;
      totalNet += it.finalAmount;
    }

    final roundNet = totalNet.roundToDouble();
    final roundOff = roundNet - totalNet;
    final grandTotal = roundNet;
    final voucherNo = data.generateNextVoucherNo(widget.billingType);

    final billedByStr = (user?.isSuperAdmin ?? false)
        ? '${user?.name ?? "Super Admin"} (Super Admin)'
        : '${user?.name ?? "Staff"} (${user?.roleLabel ?? "Staff"})';

    final order = SalesOrder(
      id: 'PREVIEW',
      voucherNo: voucherNo,
      voucherType: widget.billingType == 'GST' ? 'GST Invoice' : 'Non-GST Voucher',
      billingType: widget.billingType,
      pricingType: _selectedPricing,
      customerId: _selectedCustomer?.id ?? 'C-CASH',
      customerName: _selectedCustomer?.name ?? 'Counter Retail Customer',
      date: AppFormatters.todayISO(),
      time: AppFormatters.currentTimeStr(),
      salesperson: billedByStr,
      deliveryMan: 'Srinivasan',
      godown: 'Main Godown',
      route: _selectedCustomer?.route ?? 'Local',
      address: _selectedCustomer?.address ?? '',
      gstin: widget.billingType == 'GST' ? (_selectedCustomer?.gstin ?? '') : '',
      priceList: _selectedPricing.key,
      dispatch: 'Delivered',
      payStatus: _payStatus,
      payMode: _paymentMode,
      userId: user?.id ?? '',
      userName: user?.name ?? '',
      userRole: user?.role ?? '',
      createdBy: user?.id ?? '',
      createdByRole: user?.role ?? '',
      items: List.from(_cartItems),
      subtotal: totalTaxable,
      discountTotal: 0.0,
      gstTotal: totalGst,
      roundOff: roundOff,
      grandTotal: grandTotal,
      createdAt: DateTime.now().toIso8601String(),
    );

    InvoicePrintDialog.show(
      context,
      order: order,
      company: widget.billingType == 'GST' ? data.company : data.company.copyWith(gstin: ''),
      customer: _selectedCustomer,
    );
  }

  Future<void> _handleSaveBill({bool printAfterSave = false}) async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Please add items to create bill.')),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    // Math Totals
    double totalTaxable = 0.0;
    double totalGst = 0.0;
    double totalNet = 0.0;

    for (final it in _cartItems) {
      totalTaxable += it.taxableAmount;
      totalGst += it.gstAmount;
      totalNet += it.finalAmount;
    }

    final roundNet = totalNet.roundToDouble();
    final roundOff = roundNet - totalNet;
    final grandTotal = roundNet;

    if (grandTotal <= 0) {
      setState(() => _isSaving = false);
      return;
    }

    final voucherNo = data.generateNextVoucherNo(widget.billingType);
    if (_submittedVouchers.contains(voucherNo)) {
      setState(() => _isSaving = false);
      return;
    }
    _submittedVouchers.add(voucherNo);

    final billedByStr = user.isSuperAdmin
        ? '${user.name} (Super Admin)'
        : '${user.name} (${user.roleLabel})';

    final order = SalesOrder(
      id: 'SO-${DateTime.now().millisecondsSinceEpoch}',
      voucherNo: voucherNo,
      voucherType: widget.billingType == 'GST' ? 'GST Invoice' : 'Non-GST Voucher',
      billingType: widget.billingType,
      pricingType: _selectedPricing,
      customerId: _selectedCustomer?.id ?? 'C-CASH',
      customerName: _selectedCustomer?.name ?? 'Counter Retail Customer',
      date: AppFormatters.todayISO(),
      time: AppFormatters.currentTimeStr(),
      salesperson: billedByStr,
      deliveryMan: 'Srinivasan',
      godown: 'Main Godown',
      route: _selectedCustomer?.route ?? 'Local',
      address: _selectedCustomer?.address ?? '',
      gstin: widget.billingType == 'GST' ? (_selectedCustomer?.gstin ?? '') : '',
      priceList: _selectedPricing.key,
      dispatch: 'Delivered',
      payStatus: _payStatus,
      payMode: _paymentMode,
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      createdBy: user.id,
      createdByRole: user.role,
      items: List.from(_cartItems),
      subtotal: totalTaxable,
      discountTotal: 0.0,
      gstTotal: totalGst,
      roundOff: roundOff,
      grandTotal: grandTotal,
      createdAt: DateTime.now().toIso8601String(),
    );

    final savedCustomer = _selectedCustomer;
    final saved = await data.saveSalesOrder(order: order, user: user);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _lastSavedOrder = saved;
        _lastSavedCustomer = savedCustomer;
      });
      _clearBill();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher ${saved.voucherNo} created successfully! Total: ₹${saved.grandTotal.toStringAsFixed(2)}'),
          backgroundColor: AppColors.success,
        ),
      );

      if (printAfterSave) {
        InvoicePrintDialog.show(
          context,
          order: saved,
          company: widget.billingType == 'GST' ? data.company : data.company.copyWith(gstin: ''),
          customer: savedCustomer,
        );
      }
    }
  }

  Widget _buildRatePill(PricingType pt, String label) {
    final isSelected = _selectedPricing == pt;
    return InkWell(
      onTap: () => setState(() => _selectedPricing = pt),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.forestDark : AppColors.text2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isGst = widget.billingType == 'GST';
    final companyName = data.company.name.isNotEmpty ? data.company.name : 'KKK OIL FACTORY';

    final products = data.products.where((p) {
      if (p.status != 'Active') return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.oilType.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Top Page Head matching Vercel .page-head
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGst ? 'Billing Counter' : 'Non-GST Billing Counter',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isGst
                        ? 'Fast GST billing — add products, take payment, print the tax invoice.'
                        : 'Fast Non-GST counter voucher — private executive billing.',
                    style: const TextStyle(fontSize: 12, color: AppColors.text2),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGst ? AppColors.surfaceAlt : AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isGst ? AppColors.border : AppColors.gold),
                ),
                child: Text(
                  isGst ? companyName : 'NON-GST PRIVATE',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isGst ? AppColors.text2 : AppColors.goldDeep,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Content Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              if (isWide) {
                // Desktop Dual-Pane Layout matching .counter-grid
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildProductsPane(products)),
                    Container(width: 1, color: AppColors.border),
                    SizedBox(width: 380, child: _buildCartPane(data)),
                  ],
                );
              }

              // Mobile Single Column / Tabbed View
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppColors.forest,
                      indicatorColor: AppColors.forest,
                      tabs: [
                        const Tab(text: 'Products Catalog'),
                        Tab(text: 'Current Bill (${_cartItems.length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildProductsPane(products),
                          _buildCartPane(data),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsPane(List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        return Padding(
          padding: EdgeInsets.all(isNarrow ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & AWR Rate Pills Toolbar matching Vercel
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search product, SKU or oil type…',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.text3),
                          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.text3),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRatePill(PricingType.retail, 'RETAIL'),
                        _buildRatePill(PricingType.wholesale, 'WHOLESALE'),
                        _buildRatePill(PricingType.agency, 'AGENCY'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Product Cards Grid matching .prod-picker & .prod-btn
              Expanded(
                child: products.isEmpty
                    ? const Center(
                        child: Text(
                          'No product matches your search.',
                          style: TextStyle(color: AppColors.text3, fontSize: 13),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isNarrow ? 170 : 200,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, idx) {
                          final p = products[idx];
                          final rate = p.getRateFor(_selectedPricing);
                          final inCart = _cartItems.any((it) => it.productId == p.id);
                          final isLow = p.stock <= p.minStock;

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: inCart ? AppColors.forest : AppColors.border,
                                width: inCart ? 1.5 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _addProductToCart(p),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(11),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceAlt,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                p.pack,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                              ),
                                            ),
                                            if (inCart)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.forest,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${_cartItems.firstWhere((it) => it.productId == p.id).qty.toInt()} in bill',
                                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                            color: AppColors.text,
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${rate.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                        Text(
                                          isLow ? '${p.stock.toInt()} low' : '${p.stock.toInt()} stock',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isLow ? FontWeight.w700 : FontWeight.w500,
                                            color: isLow ? AppColors.danger : AppColors.text3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartPane(DataProvider data) {
    double totalTaxable = 0.0;
    double totalGst = 0.0;
    double totalNet = 0.0;
    double totalQty = 0.0;

    for (final it in _cartItems) {
      totalTaxable += it.taxableAmount;
      totalGst += it.gstAmount;
      totalNet += it.finalAmount;
      totalQty += it.qty;
    }

    final grandTotal = totalNet.roundToDouble();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bill Head matching .bill-head
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Bill',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              Text(
                '${totalQty.toInt()} ${totalQty.toInt() == 1 ? "item" : "items"}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text3),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer Selector matching .bill-cust
          DropdownButtonFormField<Customer?>(
            value: _selectedCustomer,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            hint: const Text('Walk-in / Cash customer', style: TextStyle(fontSize: 13, color: AppColors.text)),
            items: [
              const DropdownMenuItem<Customer?>(
                value: null,
                child: Text('Walk-in / Cash customer', style: TextStyle(fontSize: 13)),
              ),
              ...data.customers.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (val) {
              setState(() {
                _selectedCustomer = val;
                if (val != null && val.priceList.isNotEmpty) {
                  _selectedPricing = PricingTypeExtension.fromString(val.priceList);
                }
              });
            },
          ),
          const SizedBox(height: 10),

          // Cart Items List matching .bill-lines
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.point_of_sale_outlined, size: 36, color: AppColors.text3),
                        SizedBox(height: 8),
                        Text(
                          'No items yet — click a product to add it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.text3, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) {
                      final item = _cartItems[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '₹${item.rate.toStringAsFixed(0)} · GST ${item.gstRate.toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.text3),
                                  ),
                                ],
                              ),
                            ),
                            // Qty Stepper matching .qty-step
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.surface2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _updateCartItem(i, item.qty - 1, item.discPercent),
                                    child: Container(
                                      width: 26,
                                      height: 28,
                                      alignment: Alignment.center,
                                      child: const Text('−', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
                                    ),
                                    child: Text('${item.qty.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                  InkWell(
                                    onTap: () => _updateCartItem(i, item.qty + 1, item.discPercent),
                                    child: Container(
                                      width: 26,
                                      height: 28,
                                      alignment: Alignment.center,
                                      child: const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 58,
                              child: Text(
                                '₹${item.finalAmount.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () => _updateCartItem(i, 0, item.discPercent),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bill Totals matching .bill-totals
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Taxable Subtotal', style: TextStyle(fontSize: 12.5, color: AppColors.text2)),
                    Text('₹${totalTaxable.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (widget.billingType == 'GST') ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Output GST Tax (5%)', style: TextStyle(fontSize: 12.5, color: AppColors.text2)),
                      Text('₹${totalGst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.borderStrong)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                      Text(
                        '₹${grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Payment Mode Selector matching .pay-modes
          Row(
            children: ['Cash', 'UPI', 'Card', 'Credit'].map((mode) {
              final isActive = _paymentMode == mode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _paymentMode = mode;
                        _payStatus = mode == 'Credit' ? 'Credit' : 'Paid';
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.forest : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isActive ? AppColors.forest : AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        mode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppColors.text2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Action Buttons matching .bill-actions
          Row(
            children: [
              OutlinedButton(
                onPressed: (_cartItems.isNotEmpty && !_isSaving) ? _clearBill : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: (_cartItems.isNotEmpty && !_isSaving) ? _previewPrintCurrentBill : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text2,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                child: const Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: (_cartItems.isNotEmpty && !_isSaving) ? () => _handleSaveBill(printAfterSave: false) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: Text(_isSaving ? 'Saving…' : 'Save', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 15),
                  label: Text(
                    widget.billingType == 'GST' ? 'Save & Print Tax Invoice' : 'Save & Print Voucher',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.forestDark,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    elevation: 1,
                  ),
                  onPressed: (_cartItems.isNotEmpty && !_isSaving) ? () => _handleSaveBill(printAfterSave: true) : null,
                ),
              ),
            ],
          ),

          // Post-Save Quick Actions Bar
          if (_lastSavedOrder != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '✅ Saved: ${_lastSavedOrder!.voucherNo} (₹${_lastSavedOrder!.grandTotal.toStringAsFixed(0)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestDark, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download, size: 13),
                              label: const Text('Print Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.forestDark,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                              onPressed: () {
                                InvoicePrintDialog.show(
                                  context,
                                  order: _lastSavedOrder!,
                                  company: widget.billingType == 'GST' ? data.company : data.company.copyWith(gstin: ''),
                                  customer: _lastSavedCustomer,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                setState(() => _lastSavedOrder = null);
                                _clearBill();
                              },
                              child: const Text('+ New Bill'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }
    }
