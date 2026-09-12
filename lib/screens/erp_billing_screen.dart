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
import '../widgets/ui_components.dart';

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
      target = products.firstWhere(
        (p) =>
            p.status == 'Active' &&
            (p.name.toLowerCase().contains(_itemSearchQuery) ||
                p.code.toLowerCase().contains(_itemSearchQuery) ||
                p.sku.toLowerCase().contains(_itemSearchQuery)),
        orElse: () => products.firstWhere((p) => p.status == 'Active'),
      );
    }
    if (target != null) {
      _quickAddProduct(target);
      _itemSearchCtrl.clear();
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
      voucherType: widget.forcedBillingType == 'GST' ? 'GST Invoice' : 'Non-GST Voucher',
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
      payStatus: _payMode == 'Credit' ? 'Pending' : 'Paid',
      payMode: _payMode,
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      createdBy: user.id,
      createdByRole: user.role,
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
          content: Text('${widget.forcedBillingType == "GST" ? "GST Invoice" : "Non-GST Voucher"} ${saved.voucherNo} saved successfully! Total: ₹${saved.grandTotal.toStringAsFixed(2)}'),
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
      voucherType: widget.forcedBillingType == 'GST' ? 'GST Invoice' : 'Non-GST Voucher',
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
      payStatus: _payMode == 'Credit' ? 'Pending' : 'Paid',
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

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isGst = widget.forcedBillingType == 'GST';
    final activeProducts = data.products.where((p) => p.status == 'Active').toList();

    // Filter quick chips based on search query
    final filteredChips = _itemSearchQuery.isEmpty
        ? activeProducts
        : activeProducts.where((p) {
            return p.name.toLowerCase().contains(_itemSearchQuery) ||
                p.code.toLowerCase().contains(_itemSearchQuery) ||
                p.sku.toLowerCase().contains(_itemSearchQuery) ||
                p.oilType.toLowerCase().contains(_itemSearchQuery);
          }).toList();

    double subtotal = 0.0;
    double gstTotal = 0.0;
    double grandTotal = 0.0;

    for (final it in _items) {
      subtotal += it.taxableAmount;
      gstTotal += it.gstAmount;
      grandTotal += it.finalAmount;
    }

    final roundedGrand = grandTotal.roundToDouble();
    final roundOff = roundedGrand - grandTotal;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 760;
    final isWide = screenWidth >= 950;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. EXACT VERCEL HEADER BANNER (Forest Green + 3px Gold Bottom Border)
          Container(
            decoration: BoxDecoration(
              color: AppColors.forestDark,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                bottom: BorderSide(color: AppColors.gold, width: 3),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x1A10231B), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x29E3A92E),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.gold.withOpacity(0.6)),
                        ),
                        child: Text(
                          isGst ? 'KKK OIL FACTORY ERP' : 'NON-GST EXECUTIVE STATION',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isGst ? 'SALES INVOICE VOUCHER' : 'NON-GST SALES VOUCHER',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 21,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Ledger Billing Station · ${data.company.gstin.isNotEmpty ? "GSTIN: " + data.company.gstin : "Dharmapuri Unit"}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8FA298)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.forestMedium,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gold, width: 1.2),
                      ),
                      child: Text(
                        'VOUCHER: ${data.generateNextVoucherNo(widget.forcedBillingType)}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DATE: ${AppFormatters.todayISO()}',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. VOUCHER FORM TOP CARD (Party, AWR Rate selector, Route, Godown, Billed By)
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Party + AWR Rate Pills + Godown
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Party / Customer Dropdown
                      SizedBox(
                        width: isMobile ? double.infinity : 280,
                        child: DropdownButtonFormField<Customer?>(
                          value: _selectedCustomer,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Party / Customer Name',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          hint: const Text('Counter Cash Customer'),
                          items: [
                            const DropdownMenuItem<Customer?>(
                              value: null,
                              child: Text('Counter Cash Customer (Direct)'),
                            ),
                            ...data.customers.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name, overflow: TextOverflow.ellipsis),
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

                      // AWR Rate Selector Pills
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('RATE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                            ),
                            ...PricingType.values.map((pt) {
                              final isSel = _pricingType == pt;
                              return InkWell(
                                onTap: () => _setPricingType(pt, activeProducts),
                                borderRadius: BorderRadius.circular(7),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.gold : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    pt.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isSel ? AppColors.forestDark : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      // Godown Selector
                      SizedBox(
                        width: isMobile ? double.infinity : 160,
                        child: DropdownButtonFormField<String>(
                          value: _godown,
                          decoration: const InputDecoration(
                            labelText: 'Godown',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: AppConstants.godowns.map((g) {
                            return DropdownMenuItem(value: g, child: Text(g));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _godown = val);
                          },
                        ),
                      ),

                      // Salesperson / Billed By
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Billed: ${user?.name ?? "Cashier"}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.forestMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Optional row for Address & Customer GSTIN
                  if (_selectedCustomer != null || isGst) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _addressCtrl,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: const InputDecoration(
                              labelText: 'Delivery Address / Route',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        if (isGst) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _gstinCtrl,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: const InputDecoration(
                                labelText: 'Party GSTIN',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. ⚡ FAST ITEM ENTRY (SCAN BARCODE / SEARCH CODE OR NAME + QUICK CHIPS)
          Card(
            color: AppColors.surfaceAlt,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with bolt icon
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.gold, size: 20),
                      const SizedBox(width: 6),
                      const Text(
                        'FAST ITEM ENTRY (SCAN BARCODE / SEARCH CODE OR NAME)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.forestDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Input bar with Search, Qty, Rate, Disc %, Add Item button
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 720;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _itemSearchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Type product name, code (e.g. PRD-101)...',
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                                suffixIcon: _itemSearchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => _itemSearchCtrl.clear(),
                                      )
                                    : null,
                              ),
                              onSubmitted: (_) => _addItemFromInputs(activeProducts),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _qtyCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Qty', filled: true, fillColor: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _rateCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Rate (₹)', filled: true, fillColor: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _discCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Disc %', filled: true, fillColor: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoldButton(
                              icon: Icons.add,
                              label: '+ Add Item to Voucher',
                              height: 44,
                              onPressed: () => _addItemFromInputs(activeProducts),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: _itemSearchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Type product name, code (e.g. PRD-101)...',
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                                suffixIcon: _itemSearchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => _itemSearchCtrl.clear(),
                                      )
                                    : null,
                              ),
                              onSubmitted: (_) => _addItemFromInputs(activeProducts),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Qty', filled: true, fillColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _rateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Rate (₹)', filled: true, fillColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 85,
                            child: TextField(
                              controller: _discCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Disc %', filled: true, fillColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GoldButton(
                            icon: Icons.add,
                            label: 'Add Item',
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            onPressed: () => _addItemFromInputs(activeProducts),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // LIVE CLICKABLE PRODUCT QUICK-ADD CHIPS
                  const Text(
                    'Quick Add Items (Click to add directly to voucher):',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filteredChips.map((p) {
                      final rate = p.getRateFor(_pricingType);
                      final isLow = p.stock <= p.minStock;
                      final isSelected = _selectedProduct?.id == p.id;

                      return InkWell(
                        onTap: () => _quickAddProduct(p),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.gold : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? const [BoxShadow(color: Color(0x24E3A92E), blurRadius: 6, offset: Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 15, color: AppColors.goldDeep),
                              const SizedBox(width: 5),
                              Text(
                                '${p.name} (${p.pack})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forestDark),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.forestMedium,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '₹${rate.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gold),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '(${p.stock.toInt()})',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isLow ? AppColors.danger : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. VOUCHER LINE ITEMS TABLE (Columns: #, Item Code, Description, Pack/Unit, MRP, Qty, Rate, Disc %, Taxable, GST %, Tax Amt, Line Total, Action)
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Voucher Line Items (${_items.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      if (_items.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_sweep, size: 16, color: AppColors.danger),
                          label: const Text('Clear Table', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                          onPressed: () => setState(() => _items.clear()),
                        ),
                    ],
                  ),
                  const Divider(height: 20),

                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: const [
                          Icon(Icons.receipt_outlined, size: 40, color: AppColors.textMuted),
                          SizedBox(height: 10),
                          Text('No line items in voucher yet.', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('Click any product chip above to add items instantly.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  else if (isMobile)
                    // Mobile Card List with stepper controls
                    Column(
                      children: List.generate(_items.length, (idx) {
                        final item = _items[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
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
                                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
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
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Stepper controls
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
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Text('-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Text('${item.qty.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                        InkWell(
                                          onTap: () => _updateItemQty(idx, 1),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '× ₹${item.rate.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    '₹${item.finalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forestDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    )
                  else
                    // Desktop Full ERP Table Matching Vercel Oh
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
                        columnSpacing: 18,
                        columns: [
                          const DataColumn(label: Text('#')),
                          const DataColumn(label: Text('Item Code')),
                          const DataColumn(label: Text('Description of Goods')),
                          const DataColumn(label: Text('Pack / Unit')),
                          const DataColumn(label: Text('MRP (₹)')),
                          const DataColumn(label: Text('Qty')),
                          const DataColumn(label: Text('Rate (AWR)')),
                          const DataColumn(label: Text('Disc %')),
                          if (isGst) const DataColumn(label: Text('Taxable (₹)')),
                          if (isGst) const DataColumn(label: Text('GST %')),
                          if (isGst) const DataColumn(label: Text('Tax Amt (₹)')),
                          const DataColumn(label: Text('Line Total (₹)')),
                          const DataColumn(label: Text('Action')),
                        ],
                        rows: List.generate(_items.length, (idx) {
                          final item = _items[idx];
                          return DataRow(
                            cells: [
                              DataCell(Text('${idx + 1}')),
                              DataCell(Text(item.productCode, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(item.unit)),
                              DataCell(Text(item.mrp.toStringAsFixed(2))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _updateItemQty(idx, -1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(4)),
                                        child: const Icon(Icons.remove, size: 12),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text('${item.qty.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    InkWell(
                                      onTap: () => _updateItemQty(idx, 1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(4)),
                                        child: const Icon(Icons.add, size: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(item.rate.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text('${item.discPercent.toStringAsFixed(0)}%')),
                              if (isGst) DataCell(Text(item.taxableAmount.toStringAsFixed(2))),
                              if (isGst) DataCell(Text('${item.gstRate.toStringAsFixed(0)}%')),
                              if (isGst) DataCell(Text(item.gstAmount.toStringAsFixed(2))),
                              DataCell(Text('₹${item.finalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestMedium))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                  onPressed: () => setState(() => _items.removeAt(idx)),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. BOTTOM SECTION: 4-TAB DISPATCH ON LEFT & GOLDEN FRAME TOTALS ON RIGHT
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _buildDispatchTabsCard(isGst, subtotal, gstTotal, roundOff, roundedGrand)),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: _buildGoldenTotalsCard(isGst, subtotal, gstTotal, roundOff, roundedGrand, data)),
              ],
            )
          else
            Column(
              children: [
                _buildDispatchTabsCard(isGst, subtotal, gstTotal, roundOff, roundedGrand),
                const SizedBox(height: 16),
                _buildGoldenTotalsCard(isGst, subtotal, gstTotal, roundOff, roundedGrand, data),
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
        ],
      ),
    );
  }

  // 4-Tab Container matching Vercel left pane
  Widget _buildDispatchTabsCard(bool isGst, double subtotal, double gstTotal, double roundOff, double grandTotal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Pill Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabPill(0, '🚛 Dispatch Details'),
                  const SizedBox(width: 6),
                  _buildTabPill(1, '📄 E-Way Bill'),
                  const SizedBox(width: 6),
                  _buildTabPill(2, '⚡ E-Invoice IRN'),
                  const SizedBox(width: 6),
                  _buildTabPill(3, '📑 Tax Ledgers'),
                ],
              ),
            ),
            const Divider(height: 20),

            // Tab Content
            if (_selectedBottomTab == 0) ...[
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 170,
                    child: TextField(
                      controller: _vehicleNumberCtrl,
                      decoration: const InputDecoration(labelText: 'Vehicle Number', hintText: 'TN 29 AB 1234'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: TextField(
                      controller: _driverNameCtrl,
                      decoration: const InputDecoration(labelText: 'Driver & Phone'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: TextField(
                      controller: _poNumberCtrl,
                      decoration: const InputDecoration(labelText: 'PO Number'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: TextField(
                      controller: _deliveryNoteCtrl,
                      decoration: const InputDecoration(labelText: 'Delivery Note / DC'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: TextField(
                      controller: _gatePassCtrl,
                      decoration: const InputDecoration(labelText: 'Gate Pass No'),
                    ),
                  ),
                ],
              ),
            ] else if (_selectedBottomTab == 1) ...[
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _ewbNoCtrl,
                      decoration: const InputDecoration(labelText: 'E-Way Bill Number', hintText: '12-digit EWB No'),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _transporterCtrl,
                      decoration: const InputDecoration(labelText: 'Transporter Name / ID'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('E-Way Bill is mandatory for consignment value > ₹50,000.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ] else if (_selectedBottomTab == 2) ...[
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
                  _buildLedgerRow('Central GST Ledger (CGST 2.5%):', '₹${(gstTotal / 2).toStringAsFixed(2)}'),
                  _buildLedgerRow('State GST Ledger (SGST 2.5%):', '₹${(gstTotal / 2).toStringAsFixed(2)}'),
                  _buildLedgerRow('Round-off Ledger Account:', '₹${roundOff.toStringAsFixed(2)}'),
                  _buildLedgerRow('Total Net Receivable Account:', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String title) {
    final isSel = _selectedBottomTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedBottomTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? AppColors.forestMedium : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? AppColors.forestMedium : AppColors.border),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
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

  // Golden Frame Totals Card matching Vercel right pane
  Widget _buildGoldenTotalsCard(bool isGst, double subtotal, double gstTotal, double roundOff, double grandTotal, DataProvider data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x1AE3A92E), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Taxable Subtotal:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ],
          ),
          if (isGst) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CGST (2.5%):', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                Text('₹${(gstTotal / 2).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SGST (2.5%):', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                Text('₹${(gstTotal / 2).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Round Off:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('${roundOff >= 0 ? "+" : ""}₹${roundOff.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),

          // Grand Total Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.forestMedium,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total (Net):', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(
                  '₹${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold),
                ),
              ],
            ),
          ),
          if (grandTotal > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppFormatters.numberToWordsINR(grandTotal),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Payment Mode Selector Pills
          const Text('Payment Mode:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: ['Cash', 'UPI', 'Bank', 'Credit'].map((mode) {
              final isSel = _payMode == mode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _payMode = mode;
                        _payStatus = mode == 'Credit' ? 'Pending' : 'Paid';
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.forestMedium : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSel ? AppColors.forestMedium : AppColors.border),
                      ),
                      child: Text(
                        mode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _resetVoucher,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print_outlined, size: 15),
                  label: const Text('Print', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: (_items.isNotEmpty && !_isSaving) ? _previewPrintCurrentBill : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: GoldButton(
                  icon: Icons.print,
                  label: _isSaving ? 'Saving…' : 'Save & Print',
                  height: 44,
                  onPressed: (_items.isNotEmpty && !_isSaving) ? () => _saveVoucher(printAfterSave: true) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
