import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/sales_order.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/invoice_print_dialog.dart';

class ErpBillingScreen extends StatefulWidget {
  final String forcedBillingType; // 'GST' or 'NON_GST'

  const ErpBillingScreen({super.key, this.forcedBillingType = 'GST'});

  @override
  State<ErpBillingScreen> createState() => _ErpBillingScreenState();
}

class _ErpBillingScreenState extends State<ErpBillingScreen> {
  // Voucher Header Details
  Customer? _selectedCustomer;
  String _route = 'Dharmapuri Local';
  final _addressCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final String _deliveryMan = 'Srinivasan';
  String _godown = 'Main Godown';
  PricingType _pricingType = PricingType.retail;
  String _payMode = 'Cash';
  String _payStatus = 'Paid';

  // Dispatch & E-Way Details
  final _poNumberCtrl = TextEditingController();
  final _poDateCtrl = TextEditingController(text: '13/09/2026');
  final _dispatchThroughCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _deliveryNoteCtrl = TextEditingController();
  final _gatePassCtrl = TextEditingController();
  final _ewbNoCtrl = TextEditingController();
  final _transporterCtrl = TextEditingController();

  // Active Line Items
  final List<InvoiceItem> _items = [];

  // Fast Item Entry Form
  final _itemSearchCtrl = TextEditingController();
  String _itemSearchQuery = '';
  Product? _selectedProduct;
  final _qtyCtrl = TextEditingController(text: '1');
  final _rateCtrl = TextEditingController();
  final _discCtrl = TextEditingController(text: '0');

  // Bottom Tabs
  int _selectedBottomTab = 0; // 0: Dispatch, 1: E-Way Bill, 2: E-Invoice, 3: Tax Ledgers

  bool _isSaving = false;
  final Set<String> _submittedVouchers = {};
  SalesOrder? _lastSavedOrder;
  Customer? _lastSavedCustomer;

  @override
  void initState() {
    super.initState();
    _itemSearchCtrl.addListener(() {
      setState(() {
        _itemSearchQuery = _itemSearchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _poNumberCtrl.dispose();
    _poDateCtrl.dispose();
    _dispatchThroughCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _driverNameCtrl.dispose();
    _deliveryNoteCtrl.dispose();
    _gatePassCtrl.dispose();
    _ewbNoCtrl.dispose();
    _transporterCtrl.dispose();
    _itemSearchCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  void _quickAddProduct(Product p, {double? customQty}) {
    final qty = customQty ?? (double.tryParse(_qtyCtrl.text) ?? 1.0);
    if (qty <= 0) return;

    final rate = _selectedProduct?.id == p.id && _rateCtrl.text.isNotEmpty
        ? (double.tryParse(_rateCtrl.text) ?? p.getRateFor(_pricingType))
        : p.getRateFor(_pricingType);

    final discPercent = double.tryParse(_discCtrl.text) ?? 0.0;

    final gross = qty * rate;
    final discAmt = gross * (discPercent / 100);
    final netLine = gross - discAmt;
    final gstRate = widget.forcedBillingType == 'GST' ? p.gst : 0.0;
    final taxable = widget.forcedBillingType == 'GST' ? netLine / (1 + (gstRate / 100)) : netLine;
    final gstAmt = netLine - taxable;

    setState(() {
      // If product already in voucher table, increment its qty!
      final existingIdx = _items.indexWhere((it) => it.productId == p.id);
      if (existingIdx >= 0) {
        final existing = _items[existingIdx];
        final newQty = existing.qty + qty;
        final newGross = newQty * rate;
        final newDiscAmt = newGross * (existing.discPercent / 100);
        final newNet = newGross - newDiscAmt;
        final newTaxable = widget.forcedBillingType == 'GST' ? newNet / (1 + (gstRate / 100)) : newNet;
        final newGstAmt = newNet - newTaxable;

        _items[existingIdx] = InvoiceItem(
          productId: p.id,
          productCode: p.code,
          productName: p.name,
          unit: p.unit,
          qty: newQty,
          rate: rate,
          mrp: p.mrp,
          pricingType: _pricingType,
          appliedRate: rate,
          discPercent: existing.discPercent,
          discAmount: newDiscAmt,
          taxableAmount: newTaxable,
          gstRate: gstRate,
          gstAmount: newGstAmt,
          finalAmount: newNet,
        );
      } else {
        _items.add(
          InvoiceItem(
            productId: p.id,
            productCode: p.code,
            productName: p.name,
            unit: p.unit,
            qty: qty,
            rate: rate,
            mrp: p.mrp,
            pricingType: _pricingType,
            appliedRate: rate,
            discPercent: discPercent,
            discAmount: discAmt,
            taxableAmount: taxable,
            gstRate: gstRate,
            gstAmount: gstAmt,
            finalAmount: netLine,
          ),
        );
      }

      _selectedProduct = p;
      _rateCtrl.text = rate.toStringAsFixed(2);
      _qtyCtrl.text = '1';
    });
  }

  void _addItemFromInputs(List<Product> products) {
    Product? target = _selectedProduct;
    if (target == null && _itemSearchQuery.isNotEmpty) {
      final matches = products.where(
        (p) =>
            p.status == 'Active' &&
            (p.name.toLowerCase().contains(_itemSearchQuery) ||
                p.code.toLowerCase().contains(_itemSearchQuery) ||
                p.sku.toLowerCase().contains(_itemSearchQuery) ||
                p.oilType.toLowerCase().contains(_itemSearchQuery)),
      ).toList();
      if (matches.isNotEmpty) {
        target = matches.first;
      }
    }
    if (target == null && products.isNotEmpty) {
      final active = products.where((p) => p.status == 'Active').toList();
      if (active.isNotEmpty) {
        target = active.first;
      }
    }
    if (target != null) {
      _quickAddProduct(target);
      _itemSearchCtrl.clear();
      setState(() {
        _itemSearchQuery = '';
        _selectedProduct = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${target.name} to voucher'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or search for a product first'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updateItemQty(int index, double delta) {
    if (index < 0 || index >= _items.length) return;
    final it = _items[index];
    final newQty = it.qty + delta;
    if (newQty <= 0) {
      setState(() => _items.removeAt(index));
      return;
    }

    final gross = newQty * it.rate;
    final discAmt = gross * (it.discPercent / 100);
    final netLine = gross - discAmt;
    final taxable = widget.forcedBillingType == 'GST' ? netLine / (1 + (it.gstRate / 100)) : netLine;
    final gstAmt = netLine - taxable;

    setState(() {
      _items[index] = InvoiceItem(
        productId: it.productId,
        productCode: it.productCode,
        productName: it.productName,
        unit: it.unit,
        qty: newQty,
        rate: it.rate,
        mrp: it.mrp,
        pricingType: it.pricingType,
        appliedRate: it.rate,
        discPercent: it.discPercent,
        discAmount: discAmt,
        taxableAmount: taxable,
        gstRate: it.gstRate,
        gstAmount: gstAmt,
        finalAmount: netLine,
      );
    });
  }

  void _setPricingType(PricingType newType, List<Product> allProducts) {
    setState(() {
      _pricingType = newType;
      final prodMap = {for (final p in allProducts) p.id: p};
      for (int i = 0; i < _items.length; i++) {
        final it = _items[i];
        final prod = prodMap[it.productId];
        if (prod != null) {
          final newRate = prod.getRateFor(newType);
          final gross = it.qty * newRate;
          final discAmt = gross * (it.discPercent / 100);
          final netLine = gross - discAmt;
          final taxable = widget.forcedBillingType == 'GST' ? netLine / (1 + (it.gstRate / 100)) : netLine;
          final gstAmt = netLine - taxable;

          _items[i] = InvoiceItem(
            productId: it.productId,
            productCode: it.productCode,
            productName: it.productName,
            unit: it.unit,
            qty: it.qty,
            rate: newRate,
            mrp: it.mrp,
            pricingType: newType,
            appliedRate: newRate,
            discPercent: it.discPercent,
            discAmount: discAmt,
            taxableAmount: taxable,
            gstRate: it.gstRate,
            gstAmount: gstAmt,
            finalAmount: netLine,
          );
        }
      }
      if (_selectedProduct != null) {
        _rateCtrl.text = _selectedProduct!.getRateFor(newType).toStringAsFixed(2);
      }
    });
  }

  void _resetVoucher() {
    setState(() {
      _items.clear();
      _selectedCustomer = null;
      _addressCtrl.clear();
      _gstinCtrl.clear();
      _poNumberCtrl.clear();
      _poDateCtrl.text = '13/09/2026';
      _dispatchThroughCtrl.clear();
      _vehicleNumberCtrl.clear();
      _driverNameCtrl.clear();
      _deliveryNoteCtrl.clear();
      _gatePassCtrl.clear();
      _ewbNoCtrl.clear();
      _transporterCtrl.clear();
      _itemSearchCtrl.clear();
      _selectedProduct = null;
      _qtyCtrl.text = '1';
      _rateCtrl.clear();
      _discCtrl.text = '0';
      _payMode = 'Cash';
      _payStatus = 'Paid';
    });
  }

  Future<void> _saveVoucher({bool printAfterSave = false}) async {
    if (_isSaving) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item to the voucher.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    double totalTaxable = 0.0;
    double totalDiscount = 0.0;
    double totalGst = 0.0;
    double totalNet = 0.0;

    for (final it in _items) {
      totalTaxable += it.taxableAmount;
      totalDiscount += it.discAmount;
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

    final voucherNo = data.generateNextVoucherNo(widget.forcedBillingType);
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
      voucherType: widget.forcedBillingType == 'GST' ? 'Billing Voucher' : 'Non-GST Voucher',
      billingType: widget.forcedBillingType,
      pricingType: _pricingType,
      customerId: _selectedCustomer?.id ?? 'C-CASH',
      customerName: _selectedCustomer?.name ?? 'Direct Counter Customer',
      date: AppFormatters.todayISO(),
      time: AppFormatters.currentTimeStr(),
      salesperson: billedByStr,
      deliveryMan: _deliveryMan,
      godown: _godown,
      route: _route,
      address: _addressCtrl.text.trim(),
      gstin: widget.forcedBillingType == 'GST' ? _gstinCtrl.text.trim() : '',
      priceList: _pricingType.key,
      dispatch: _deliveryNoteCtrl.text.isNotEmpty ? 'In Transit' : 'Delivered',
      payStatus: _payStatus,
      payMode: _payMode,
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      createdBy: user.id,
      createdByRole: user.role,
      items: List.from(_items),
      subtotal: totalTaxable,
      discountTotal: totalDiscount,
      gstTotal: totalGst,
      roundOff: roundOff,
      grandTotal: grandTotal,
      dispatchDetails: DispatchDetails(
        poNumber: _poNumberCtrl.text.trim(),
        poDate: _poDateCtrl.text.trim(),
        dispatchThrough: _dispatchThroughCtrl.text.trim(),
        vehicleNumber: _vehicleNumberCtrl.text.trim(),
        driverName: _driverNameCtrl.text.trim(),
        deliveryNote: _deliveryNoteCtrl.text.trim(),
        gatePassNo: _gatePassCtrl.text.trim(),
      ),
      ewbDetails: EWayBillDetails(
        ewbNo: _ewbNoCtrl.text.trim(),
        transporterName: _transporterCtrl.text.trim(),
      ),
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
      _resetVoucher();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.forcedBillingType == "GST" ? "Billing Voucher" : "Non-GST Voucher"} ${saved.voucherNo} saved successfully! Total: ₹${saved.grandTotal.toStringAsFixed(2)}'),
          backgroundColor: AppColors.success,
        ),
      );

      if (printAfterSave) {
        InvoicePrintDialog.show(
          context,
          order: saved,
          company: widget.forcedBillingType == 'GST' ? data.company : data.company.copyWith(gstin: ''),
          customer: savedCustomer,
        );
      }
    }
  }

  void _previewPrintCurrentBill() {
    if (_items.isEmpty) return;
    final data = context.read<DataProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    double totalTaxable = 0.0;
    double totalGst = 0.0;
    double totalNet = 0.0;

    for (final it in _items) {
      totalTaxable += it.taxableAmount;
      totalGst += it.gstAmount;
      totalNet += it.finalAmount;
    }

    final roundNet = totalNet.roundToDouble();
    final roundOff = roundNet - totalNet;
    final grandTotal = roundNet;
    final voucherNo = data.generateNextVoucherNo(widget.forcedBillingType);

    final billedByStr = (user?.isSuperAdmin ?? false)
        ? '${user?.name ?? "Super Admin"} (Super Admin)'
        : '${user?.name ?? "Staff"} (${user?.roleLabel ?? "Staff"})';

    final previewOrder = SalesOrder(
      id: 'PREVIEW',
      voucherNo: voucherNo,
      voucherType: widget.forcedBillingType == 'GST' ? 'Billing Voucher' : 'Non-GST Voucher',
      billingType: widget.forcedBillingType,
      pricingType: _pricingType,
      customerId: _selectedCustomer?.id ?? 'C-CASH',
      customerName: _selectedCustomer?.name ?? 'Counter Cash Customer',
      date: AppFormatters.todayISO(),
      time: AppFormatters.currentTimeStr(),
      salesperson: billedByStr,
      deliveryMan: _deliveryMan,
      godown: _godown,
      route: _route,
      address: _addressCtrl.text.trim(),
      gstin: widget.forcedBillingType == 'GST' ? _gstinCtrl.text.trim() : '',
      priceList: _pricingType.key,
      dispatch: _deliveryNoteCtrl.text.isNotEmpty ? 'In Transit' : 'Delivered',
      payStatus: _payStatus,
      payMode: _payMode,
      userId: user?.id ?? '',
      userName: user?.name ?? '',
      userRole: user?.role ?? '',
      createdBy: user?.id ?? '',
      createdByRole: user?.role ?? '',
      items: List.from(_items),
      subtotal: totalTaxable,
      discountTotal: 0.0,
      gstTotal: totalGst,
      roundOff: roundOff,
      grandTotal: grandTotal,
      dispatchDetails: DispatchDetails(
        poNumber: _poNumberCtrl.text.trim(),
        vehicleNumber: _vehicleNumberCtrl.text.trim(),
        driverName: _driverNameCtrl.text.trim(),
        deliveryNote: _deliveryNoteCtrl.text.trim(),
        gatePassNo: _gatePassCtrl.text.trim(),
      ),
      ewbDetails: EWayBillDetails(
        ewbNo: _ewbNoCtrl.text.trim(),
        transporterName: _transporterCtrl.text.trim(),
      ),
      createdAt: DateTime.now().toIso8601String(),
    );

    InvoicePrintDialog.show(
      context,
      order: previewOrder,
      company: widget.forcedBillingType == 'GST' ? data.company : data.company.copyWith(gstin: ''),
      customer: _selectedCustomer,
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB45309),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPriceListToggle(String label, PricingType type, List<Product> activeProducts) {
    final isSel = _pricingType == type;
    return Expanded(
      child: InkWell(
        onTap: () => _setPricingType(type, activeProducts),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFD97706) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isSel ? Colors.white : const Color(0xFF5B665F),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isGst = widget.forcedBillingType == 'GST';
    final activeProducts = data.products.where((p) => p.status == 'Active').toList();

    // Filter quick chips dynamically ONLY when search query is typed (e.g. "kk")
    final filteredChips = _itemSearchQuery.isEmpty
        ? <Product>[]
        : activeProducts.where((p) {
            return p.name.toLowerCase().contains(_itemSearchQuery) ||
                p.code.toLowerCase().contains(_itemSearchQuery) ||
                p.sku.toLowerCase().contains(_itemSearchQuery) ||
                p.oilType.toLowerCase().contains(_itemSearchQuery);
          }).take(8).toList();

    double subtotal = 0.0;
    double totalDiscount = 0.0;
    double gstTotal = 0.0;
    double grandTotal = 0.0;

    for (final it in _items) {
      subtotal += it.taxableAmount;
      totalDiscount += it.discAmount;
      gstTotal += it.gstAmount;
      grandTotal += it.finalAmount;
    }

    final roundedGrand = grandTotal.roundToDouble();
    final roundOff = roundedGrand - grandTotal;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 760;
    final isWide = screenWidth >= 950;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. EXACT HORIZON ERP TITLE HEADER BAR (Matching Vercel & Web App)
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: isMobile ? 10 : 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE3A92E), width: 2.5),
              ),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${data.company.name.isNotEmpty ? data.company.name.toUpperCase() : "KKK OIL FACTORY"} ERP',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E9FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDDD6FE)),
                            ),
                            child: Text(
                              'VOUCHER: ${data.generateNextVoucherNo(widget.forcedBillingType)}',
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isGst ? 'SALES INVOICE VOUCHER' : 'NON-GST SALES VOUCHER',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF834006),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        isGst ? 'Ledger Billing Station' : 'Sales Voucher Station',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFC86D1E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${data.company.name.isNotEmpty ? data.company.name.toUpperCase() : "KKK OIL FACTORY"} ERP',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGst ? 'SALES INVOICE VOUCHER' : 'NON-GST SALES VOUCHER',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF834006),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                isGst ? 'Ledger Billing Station' : 'Sales Voucher Station',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFC86D1E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E9FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Text(
                          'VOUCHER: ${data.generateNextVoucherNo(widget.forcedBillingType)}',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // 2. HORIZON ERP HEADER INFORMATION PANEL (8-Field Compact Wrap)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(color: const Color(0xFFE7E9E5)),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                // Voucher Type
                SizedBox(
                  width: isMobile ? double.infinity : 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Voucher Type'),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE7E9E5)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isGst ? 'Billing Voucher' : 'Non-GST Voucher',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1A221E)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Voucher No.
                SizedBox(
                  width: isMobile ? double.infinity : 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Voucher No.'),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBFBF9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE7E9E5)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          data.generateNextVoucherNo(widget.forcedBillingType),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Voucher Date
                SizedBox(
                  width: isMobile ? double.infinity : 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Voucher Date'),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE7E9E5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppFormatters.todayISO(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.text3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Party Ledger / Customer
                SizedBox(
                  width: isMobile ? double.infinity : 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Party Ledger / Customer'),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE7E9E5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Customer?>(
                            value: _selectedCustomer,
                            isExpanded: true,
                            hint: const Text('Walk-in / Cash Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            items: [
                              const DropdownMenuItem<Customer?>(
                                value: null,
                                child: Text('Walk-in / Cash Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              ...data.customers.map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedCustomer = val;
                                if (val != null) {
                                  _addressCtrl.text = val.address;
                                  _gstinCtrl.text = val.gstin;
                                  _route = val.route;
                                  if (val.priceList.isNotEmpty) {
                                    _setPricingType(PricingTypeExtension.fromString(val.priceList), activeProducts);
                                  }
                                } else {
                                  _addressCtrl.clear();
                                  _gstinCtrl.clear();
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Price List (AWR Rates) Toggle Buttons
                SizedBox(
                  width: isMobile ? double.infinity : 210,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Price List (AWR Rates)'),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6F4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE7E9E5)),
                        ),
                        child: Row(
                          children: [
                            _buildPriceListToggle('AGENCY', PricingType.agency, activeProducts),
                            const SizedBox(width: 3),
                            _buildPriceListToggle('WHOLESALE', PricingType.wholesale, activeProducts),
                            const SizedBox(width: 3),
                            _buildPriceListToggle('RETAIL', PricingType.retail, activeProducts),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Delivery Address
                SizedBox(
                  width: isMobile ? double.infinity : 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Delivery Address'),
                      SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _addressCtrl,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Delivery Address / Town',
                            hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.text3),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD97706))),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sales Man
                SizedBox(
                  width: isMobile ? double.infinity : 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Sales Man'),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE7E9E5)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          user?.name ?? 'Super Admin',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Godown Location
                SizedBox(
                  width: isMobile ? double.infinity : 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Godown Location'),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE7E9E5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _godown,
                            isExpanded: true,
                            items: AppConstants.godowns.map((g) {
                              return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _godown = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. ⚡ FAST ITEM ENTRY (SCAN BARCODE / SEARCH CODE OR NAME)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBF9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7E9E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFFD97706), size: 17),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'FAST ITEM ENTRY (SCAN BARCODE / SEARCH CODE OR NAME)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFFB45309),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Responsive Search Bar + Product Dropdown + Qty + Disc % + Add Item Button
                if (isMobile) ...[
                  // Mobile Row 1: Direct Product Dropdown Selector
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE7E9E5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProduct?.id,
                        hint: const Text('Select product from list...', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD97706)),
                        items: activeProducts.map((p) {
                          final rate = p.getRateFor(_pricingType);
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              '${p.name} (${p.code}) — ₹${rate.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (prodId) {
                          if (prodId != null) {
                            final p = activeProducts.where((prod) => prod.id == prodId).firstOrNull;
                            if (p != null) {
                              setState(() {
                                _selectedProduct = p;
                                _rateCtrl.text = p.getRateFor(_pricingType).toStringAsFixed(2);
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mobile Row 2: Search Input
                  SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _itemSearchCtrl,
                      onChanged: (val) => setState(() => _itemSearchQuery = val.toLowerCase().trim()),
                      onSubmitted: (_) => _addItemFromInputs(activeProducts),
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Or type product name / code / barcode...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.text3),
                        prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.text3),
                        suffixIcon: _itemSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _itemSearchCtrl.clear();
                                  setState(() => _itemSearchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD97706))),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mobile Row 3: Qty, Disc %, Add Item
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Qty',
                              labelStyle: const TextStyle(fontSize: 11),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD97706))),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _discCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Disc %',
                              labelStyle: const TextStyle(fontSize: 11),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD97706))),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () => _addItemFromInputs(activeProducts),
                            icon: const Icon(Icons.add_shopping_cart, size: 15),
                            label: const Text('Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Desktop Row: Product Dropdown + Search Box + Qty + Disc % + Add Item
                  Row(
                    children: [
                      // Product Dropdown
                      SizedBox(
                        width: 220,
                        height: 38,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE7E9E5)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedProduct?.id,
                              hint: const Text('Select Product...', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD97706)),
                              items: activeProducts.map((p) {
                                final rate = p.getRateFor(_pricingType);
                                return DropdownMenuItem<String>(
                                  value: p.id,
                                  child: Text(
                                    '${p.name} — ₹${rate.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (prodId) {
                                if (prodId != null) {
                                  final p = activeProducts.where((prod) => prod.id == prodId).firstOrNull;
                                  if (p != null) {
                                    setState(() {
                                      _selectedProduct = p;
                                      _rateCtrl.text = p.getRateFor(_pricingType).toStringAsFixed(2);
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Search Box
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _itemSearchCtrl,
                            onChanged: (val) => setState(() => _itemSearchQuery = val.toLowerCase().trim()),
                            onSubmitted: (_) => _addItemFromInputs(activeProducts),
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Or search name, code (e.g. PRD-101)...',
                              hintStyle: const TextStyle(fontSize: 12, color: AppColors.text3),
                              prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.text3),
                              suffixIcon: _itemSearchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _itemSearchCtrl.clear();
                                        setState(() => _itemSearchQuery = '');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD97706))),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 75,
                        height: 38,
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Qty',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD97706))),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 75,
                        height: 38,
                        child: TextField(
                          controller: _discCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Disc %',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD97706))),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () => _addItemFromInputs(activeProducts),
                          icon: const Icon(Icons.add_shopping_cart, size: 15),
                          label: const Text('+ Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // DYNAMIC PRODUCT PILL CHIPS (QUICK ADD WHEN SEARCH EMPTY, FILTERED WHEN TYPING)
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE7E9E5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _itemSearchQuery.isEmpty ? Icons.touch_app_outlined : Icons.search,
                            size: 13,
                            color: _itemSearchQuery.isEmpty ? AppColors.textMuted : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _itemSearchQuery.isEmpty
                                ? '⚡ Quick Add Products (Tap to Add):'
                                : '🔍 Matching Products (${filteredChips.length}):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _itemSearchQuery.isEmpty ? AppColors.textSecondary : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_itemSearchQuery.isNotEmpty && filteredChips.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'No products matched "$_itemSearchQuery". Try searching by code or oil type.',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (_itemSearchQuery.isEmpty ? activeProducts.take(8).toList() : filteredChips).map((p) {
                            final rate = p.getRateFor(_pricingType);
                            final isFiltered = _itemSearchQuery.isNotEmpty;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _quickAddProduct(p);
                                  _itemSearchCtrl.clear();
                                  setState(() => _itemSearchQuery = '');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added ${p.name} to voucher'),
                                      duration: const Duration(milliseconds: 1000),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isFiltered ? const Color(0xFFB45309) : AppColors.surfaceAlt,
                                    gradient: isFiltered
                                        ? const LinearGradient(
                                            colors: [Color(0xFFD97706), Color(0xFFB45309)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isFiltered ? const Color(0xFFB45309) : AppColors.border,
                                    ),
                                    boxShadow: isFiltered
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x22B45309),
                                              blurRadius: 3,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 13,
                                        color: isFiltered ? Colors.white : AppColors.forestLight,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${p.name} — ₹${rate.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isFiltered ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${p.stock.toInt()} left)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isFiltered ? Colors.white.withOpacity(0.85) : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. VOUCHER LINE ITEMS TABLE
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE7E9E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  // Mobile Card List
                  if (_items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      alignment: Alignment.center,
                      child: const Text(
                        'No items in voucher. Use the fast entry bar above to scan or search products.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: List.generate(_items.length, (idx) {
                          final item = _items[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('#${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                          Text('${item.productCode} · ${item.unit}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => setState(() => _items.removeAt(idx)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(6),
                                        color: Colors.white,
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => _updateItemQty(idx, -1),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              child: Text('-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            child: Text('${item.qty.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                          ),
                                          InkWell(
                                            onTap: () => _updateItemQty(idx, 1),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              child: Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text('× ₹${item.rate.toStringAsFixed(item.rate % 1 == 0 ? 0 : 2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    Text('₹${item.finalAmount.toStringAsFixed(item.finalAmount % 1 == 0 ? 0 : 2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                ] else ...[
                  // Desktop Full ERP Table Matching Vercel & Web Screenshot
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: screenWidth - (isMobile ? 20 : 64)),
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 38,
                        dataRowMaxHeight: 44,
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFBF9)),
                        horizontalMargin: 12,
                        columnSpacing: 14,
                        columns: [
                          const DataColumn(label: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(label: Text('ITEM CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(label: Text('DESCRIPTION OF GOODS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(label: Text('PACK / UNIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(numeric: true, label: Text('MRP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(numeric: true, label: Text('QTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          DataColumn(numeric: true, label: Text('RATE (${_pricingType.key.toUpperCase()})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(numeric: true, label: Text('DISC %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(numeric: true, label: Text('TAXABLE AMT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          if (isGst) const DataColumn(label: Text('GST %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          if (isGst) const DataColumn(numeric: true, label: Text('TAX AMT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(numeric: true, label: Text('LINE TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                          const DataColumn(label: SizedBox(width: 24)),
                        ],
                        rows: List.generate(_items.length, (idx) {
                          final item = _items[idx];
                          return DataRow(
                            cells: [
                              DataCell(Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5))),
                              DataCell(Text(item.productCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFFD97706)))),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                    const Text('Category: Edible Oils', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF0F1EE), borderRadius: BorderRadius.circular(4)),
                                child: Text(item.unit, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              )),
                              DataCell(Text('₹${item.mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _updateItemQty(idx, -1),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(4)),
                                        child: const Icon(Icons.remove, size: 10),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text('${item.qty.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    InkWell(
                                      onTap: () => _updateItemQty(idx, 1),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(4)),
                                        child: const Icon(Icons.add, size: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text('₹${item.rate.toStringAsFixed(item.rate % 1 == 0 ? 0 : 2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                              DataCell(Text('${item.discPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12))),
                              DataCell(Text('₹${item.taxableAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                              if (isGst) DataCell(Text('${item.gstRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12))),
                              if (isGst) DataCell(Text('₹${item.gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12))),
                              DataCell(Text('₹${item.finalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFFD97706)))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(() => _items.removeAt(idx)),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  if (_items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      alignment: Alignment.center,
                      child: const Text(
                        'No items in voucher. Use the fast entry bar above to scan or search products.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. BOTTOM SECTION: 4-TAB DISPATCH ON LEFT & GOLDEN FRAME TOTALS ON RIGHT
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _buildDispatchTabsCard(isGst, subtotal, totalDiscount, gstTotal, roundOff, roundedGrand, isMobile)),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: _buildGoldenTotalsCard(isGst, subtotal, totalDiscount, gstTotal, roundOff, roundedGrand, data, isMobile)),
              ],
            )
          else
            Column(
              children: [
                _buildDispatchTabsCard(isGst, subtotal, totalDiscount, gstTotal, roundOff, roundedGrand, isMobile),
                const SizedBox(height: 16),
                _buildGoldenTotalsCard(isGst, subtotal, totalDiscount, gstTotal, roundOff, roundedGrand, data, isMobile),
              ],
            ),

          // Post-Save Quick Actions Notification Bar
          if (_lastSavedOrder != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.4)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '✅ Saved Bill: ${_lastSavedOrder!.voucherNo} (₹${_lastSavedOrder!.grandTotal.toStringAsFixed(2)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestDark, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text('Print Bill Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.forestDark,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                        onPressed: () {
                          InvoicePrintDialog.show(
                            context,
                            order: _lastSavedOrder!,
                            company: widget.forcedBillingType == 'GST' ? data.company : data.company.copyWith(gstin: ''),
                            customer: _lastSavedCustomer,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('+ Create New Bill'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          setState(() => _lastSavedOrder = null);
                          _resetVoucher();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 4-Tab Container matching Vercel left pane
  Widget _buildDispatchTabsCard(bool isGst, double subtotal, double totalDiscount, double gstTotal, double roundOff, double grandTotal, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E9E5)),
      ),
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Pills Selector - WRAPPED IN WRAP SO IT FITS THE SCREEN CLEANLY WITHOUT HORIZONTAL SCROLL
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTabPill(0, '🚚 Dispatch Details'),
              if (isGst) ...[
                _buildTabPill(1, '📄 E-Way Bill'),
                _buildTabPill(2, '⚡ E-Invoice IRN'),
              ],
              _buildTabPill(3, '📑 Tax Ledgers'),
            ],
          ),
          const SizedBox(height: 14),

          // Tab Content
          if (_selectedBottomTab == 0) ...[
            if (isMobile) ...[
              // Stack fields cleanly on mobile screens
              _buildFieldLabel('PO NUMBER'),
              const SizedBox(height: 4),
              _buildDispatchInput(_poNumberCtrl, 'PO-1002'),
              const SizedBox(height: 10),
              _buildFieldLabel('PO DATE'),
              const SizedBox(height: 4),
              _buildDispatchInput(_poDateCtrl, '13/09/2026', suffixIcon: Icons.calendar_today_outlined),
              const SizedBox(height: 10),
              _buildFieldLabel('DISPATCH VIA'),
              const SizedBox(height: 4),
              _buildDispatchInput(_dispatchThroughCtrl, 'VRL Logistics'),
              const SizedBox(height: 10),
              _buildFieldLabel('VEHICLE NO.'),
              const SizedBox(height: 4),
              _buildDispatchInput(_vehicleNumberCtrl, 'TN29BF6289', isBold: true),
              const SizedBox(height: 10),
              _buildFieldLabel('DRIVER NAME'),
              const SizedBox(height: 4),
              _buildDispatchInput(_driverNameCtrl, ''),
              const SizedBox(height: 10),
              _buildFieldLabel('GATE PASS NO'),
              const SizedBox(height: 4),
              _buildDispatchInput(_gatePassCtrl, ''),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('PO NUMBER'),
                        const SizedBox(height: 4),
                        _buildDispatchInput(_poNumberCtrl, 'PO-1002'),
                        const SizedBox(height: 10),
                        _buildFieldLabel('DISPATCH VIA'),
                        const SizedBox(height: 4),
                        _buildDispatchInput(_dispatchThroughCtrl, 'VRL Logistics'),
                        const SizedBox(height: 10),
                        _buildFieldLabel('DRIVER NAME'),
                        const SizedBox(height: 4),
                        _buildDispatchInput(_driverNameCtrl, ''),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Column 2
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('PO DATE'),
                        const SizedBox(height: 4),
                        _buildDispatchInput(_poDateCtrl, '13/09/2026', suffixIcon: Icons.calendar_today_outlined),
                        const SizedBox(height: 10),
                        _buildFieldLabel('VEHICLE NO.'),
                        const SizedBox(height: 4),
                        _buildDispatchInput(_vehicleNumberCtrl, 'TN29BF6289', isBold: true),
                        const SizedBox(height: 10),
                        _buildFieldLabel('GATE PASS NO'),
                        const SizedBox(height: 4),
                        _buildDispatchInput(_gatePassCtrl, ''),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ] else if (_selectedBottomTab == 1 && isGst) ...[
            if (isMobile) ...[
              _buildFieldLabel('E-WAY BILL NUMBER'),
              const SizedBox(height: 4),
              _buildDispatchInput(_ewbNoCtrl, '12-digit EWB No'),
              const SizedBox(height: 10),
              _buildFieldLabel('TRANSPORTER NAME / ID'),
              const SizedBox(height: 4),
              _buildDispatchInput(_transporterCtrl, 'Transporter ID'),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('E-WAY BILL NUMBER'),
                        const SizedBox(height: 4),
                        _buildDispatchInput(_ewbNoCtrl, '12-digit EWB No'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('TRANSPORTER NAME / ID'),
                        const SizedBox(height: 4),
                        _buildDispatchInput(_transporterCtrl, 'Transporter ID'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Text('E-Way Bill is mandatory for consignment value > ₹50,000.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ] else if (_selectedBottomTab == 2 && isGst) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('⚡ NIC E-Invoice System Integration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  SizedBox(height: 4),
                  Text('IRN and QR code are automatically registered upon saving the invoice series.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('Status: Active Ready · Digital Signature Enabled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                ],
              ),
            ),
          ] else ...[
            // Tax Ledgers
            Column(
              children: [
                _buildLedgerRow('Gross Taxable Amount:', '₹${subtotal.toStringAsFixed(2)}'),
                if (isGst) ...[
                  _buildLedgerRow('Central GST Ledger (CGST 2.5%):', '₹${(gstTotal / 2).toStringAsFixed(2)}'),
                  _buildLedgerRow('State GST Ledger (SGST 2.5%):', '₹${(gstTotal / 2).toStringAsFixed(2)}'),
                ],
                _buildLedgerRow('Round-off Ledger Account:', '${roundOff >= 0 ? "+" : ""}₹${roundOff.toStringAsFixed(2)}'),
                _buildLedgerRow('Total Net Receivable Account:', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDispatchInput(TextEditingController ctrl, String hint, {bool isBold = false, IconData? suffixIcon}) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: ctrl,
        style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 14, color: AppColors.textMuted) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE7E9E5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD97706))),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String title) {
    final isSel = _selectedBottomTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedBottomTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF10231B) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSel ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isBold ? AppColors.forestDark : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  // Golden Frame Totals Card matching Vercel right pane & screenshot
  Widget _buildGoldenTotalsCard(bool isGst, double subtotal, double totalDiscount, double gstTotal, double roundOff, double grandTotal, DataProvider data, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3A92E), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x1AE3A92E), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'VOUCHER BILL TOTALS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'MODE: ${_payMode.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD97706),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildTotalsRow('Gross Taxable Subtotal', '₹${subtotal.toStringAsFixed(subtotal % 1 == 0 ? 0 : 2)}'),
          const SizedBox(height: 6),
          _buildTotalsRow(
            'Item Discounts Total',
            totalDiscount > 0 ? '− ₹${totalDiscount.toStringAsFixed(totalDiscount % 1 == 0 ? 0 : 2)}' : '− ₹0',
          ),
          const SizedBox(height: 6),
          _buildTotalsRow(
            'Output GST Tax',
            isGst ? '₹${gstTotal.toStringAsFixed(2)}' : '₹0 (Non-GST)',
            valueColor: isGst ? const Color(0xFFD97706) : AppColors.textMuted,
          ),
          const SizedBox(height: 6),
          _buildTotalsRow(
            'Round Off (+/-)',
            '${roundOff >= 0 ? "+" : ""}₹${roundOff.toStringAsFixed(roundOff % 1 == 0 ? 0 : 2)}',
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE7E9E5)),
          const SizedBox(height: 12),

          // GRAND NET PAYABLE DISPLAY
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'GRAND NET PAYABLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${grandTotal.toStringAsFixed(grandTotal % 1 == 0 ? 0 : 2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD97706),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (grandTotal > 0) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppFormatters.numberToWordsINR(grandTotal),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // PAYMENT TYPE
          const Text(
            'PAYMENT TYPE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['Cash', 'Credit', 'UPI', 'Card'].map((mode) {
              final isSel = _payMode == mode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _payMode = mode;
                        _payStatus = mode == 'Credit' ? 'Pending' : 'Paid';
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFD97706) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel ? const Color(0xFFD97706) : const Color(0xFFE7E9E5),
                        ),
                      ),
                      child: Text(
                        mode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 4 Action Buttons: 2x2 Grid on Mobile (Zero overflow!) vs 1 Row on Desktop
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    // 1. Clear
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _resetVoucher,
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: Color(0xFFD6D9D3)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 2. Print Bill
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_items.isNotEmpty && !_isSaving) ? _previewPrintCurrentBill : null,
                        icon: const Icon(Icons.print_outlined, size: 15),
                        label: const Text('Print Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: Color(0xFFD6D9D3)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 3. Save (F2)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_items.isNotEmpty && !_isSaving) ? () => _saveVoucher(printAfterSave: false) : null,
                        icon: const Icon(Icons.check, size: 15, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Saving…' : 'Save (F2)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10231B),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 4. Save & Print
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_items.isNotEmpty && !_isSaving) ? () => _saveVoucher(printAfterSave: true) : null,
                        icon: const Icon(Icons.download, size: 15, color: Colors.white),
                        label: const Text(
                          'Save & Print',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                // 1. Clear
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _resetVoucher,
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Clear', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: Color(0xFFD6D9D3)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 2. Print Bill
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: (_items.isNotEmpty && !_isSaving) ? _previewPrintCurrentBill : null,
                    icon: const Icon(Icons.print_outlined, size: 14),
                    label: const Text('Print Bill', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: Color(0xFFD6D9D3)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 3. Save (F2)
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: (_items.isNotEmpty && !_isSaving) ? () => _saveVoucher(printAfterSave: false) : null,
                    icon: const Icon(Icons.check, size: 14, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Saving…' : 'Save (F2)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10231B),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // 4. Save & Print
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: (_items.isNotEmpty && !_isSaving) ? () => _saveVoucher(printAfterSave: true) : null,
                    icon: const Icon(Icons.download, size: 14, color: Colors.white),
                    label: const Text(
                      'Save & Print',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}
