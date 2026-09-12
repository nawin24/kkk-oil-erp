import 'product.dart';

class InvoiceItem {
  final String productId;
  final String productCode;
  final String productName;
  final String unit;
  final double qty;
  final double rate; // Effective selling rate snapshot
  final double mrp;
  final PricingType pricingType;
  final double appliedRate;
  final double discPercent;
  final double discAmount;
  final double schemeAmount;
  final double taxableAmount;
  final double gstRate; // e.g. 5%
  final double gstAmount;
  final double finalAmount;

  const InvoiceItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.rate,
    required this.mrp,
    required this.pricingType,
    required this.appliedRate,
    this.discPercent = 0.0,
    this.discAmount = 0.0,
    this.schemeAmount = 0.0,
    required this.taxableAmount,
    required this.gstRate,
    required this.gstAmount,
    required this.finalAmount,
  });

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productCode': productCode,
    'productName': productName,
    'unit': unit,
    'qty': qty,
    'rate': rate,
    'mrp': mrp,
    'pricingType': pricingType.key,
    'appliedRate': appliedRate,
    'discPercent': discPercent,
    'discAmount': discAmount,
    'schemeAmount': schemeAmount,
    'taxableAmount': taxableAmount,
    'gstRate': gstRate,
    'gstAmount': gstAmount,
    'finalAmount': finalAmount,
  };

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      productCode: map['productCode'] ?? '',
      productName: map['productName'] ?? '',
      unit: map['unit'] ?? 'Bottle',
      qty: (map['qty'] as num?)?.toDouble() ?? 1.0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      pricingType: PricingTypeExtension.fromString(map['pricingType']),
      appliedRate: (map['appliedRate'] as num?)?.toDouble() ?? (map['rate'] as num?)?.toDouble() ?? 0.0,
      discPercent: (map['discPercent'] as num?)?.toDouble() ?? 0.0,
      discAmount: (map['discAmount'] as num?)?.toDouble() ?? 0.0,
      schemeAmount: (map['schemeAmount'] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (map['taxableAmount'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 5.0,
      gstAmount: (map['gstAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['finalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DispatchDetails {
  final String? poNumber;
  final String? poDate;
  final String? dispatchThrough;
  final String? vehicleNumber;
  final String? driverName;
  final String? deliveryNote;
  final String? gatePassNo;

  const DispatchDetails({
    this.poNumber,
    this.poDate,
    this.dispatchThrough,
    this.vehicleNumber,
    this.driverName,
    this.deliveryNote,
    this.gatePassNo,
  });

  Map<String, dynamic> toMap() => {
    'poNumber': poNumber,
    'poDate': poDate,
    'dispatchThrough': dispatchThrough,
    'vehicleNumber': vehicleNumber,
    'driverName': driverName,
    'deliveryNote': deliveryNote,
    'gatePassNo': gatePassNo,
  };

  factory DispatchDetails.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DispatchDetails();
    return DispatchDetails(
      poNumber: map['poNumber'],
      poDate: map['poDate'],
      dispatchThrough: map['dispatchThrough'],
      vehicleNumber: map['vehicleNumber'],
      driverName: map['driverName'],
      deliveryNote: map['deliveryNote'],
      gatePassNo: map['gatePassNo'],
    );
  }
}

class EWayBillDetails {
  final String? supplyType;
  final String? supplySubType;
  final String? transportMode;
  final String? transporterName;
  final String? transporterId;
  final String? transDocNo;
  final String? transDocDate;
  final double? transportDistance;
  final String? ewbNo;
  final String? ewbDate;
  final String? validTill;

  const EWayBillDetails({
    this.supplyType,
    this.supplySubType,
    this.transportMode,
    this.transporterName,
    this.transporterId,
    this.transDocNo,
    this.transDocDate,
    this.transportDistance,
    this.ewbNo,
    this.ewbDate,
    this.validTill,
  });

  Map<String, dynamic> toMap() => {
    'supplyType': supplyType,
    'supplySubType': supplySubType,
    'transportMode': transportMode,
    'transporterName': transporterName,
    'transporterId': transporterId,
    'transDocNo': transDocNo,
    'transDocDate': transDocDate,
    'transportDistance': transportDistance,
    'ewbNo': ewbNo,
    'ewbDate': ewbDate,
    'validTill': validTill,
  };

  factory EWayBillDetails.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EWayBillDetails();
    return EWayBillDetails(
      supplyType: map['supplyType'],
      supplySubType: map['supplySubType'],
      transportMode: map['transportMode'],
      transporterName: map['transporterName'],
      transporterId: map['transporterId'],
      transDocNo: map['transDocNo'],
      transDocDate: map['transDocDate'],
      transportDistance: (map['transportDistance'] as num?)?.toDouble(),
      ewbNo: map['ewbNo'],
      ewbDate: map['ewbDate'],
      validTill: map['validTill'],
    );
  }
}

class SalesOrder {
  final String id;
  final String voucherNo;
  final String voucherType;
  final String billingType; // 'GST' | 'NON_GST'
  final PricingType pricingType;
  final String customerId;
  final String? customerName;
  final String date;
  final String time;
  final String salesperson;
  final String deliveryMan;
  final String godown;
  final String route;
  final String address;
  final String gstin;
  final String priceList;
  final String dispatch; // 'Delivered' | 'In Transit' | 'Loading' | 'Pending'
  final String payStatus; // 'Paid' | 'Credit' | 'Partial'
  final String payMode; // 'Cash' | 'UPI' | 'Card' | 'Credit'
  final String userId;
  final String userName;
  final String userRole;
  final String createdBy;
  final String createdByRole;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discountTotal;
  final double gstTotal;
  final double roundOff;
  final double grandTotal;
  final DispatchDetails? dispatchDetails;
  final EWayBillDetails? ewbDetails;
  final String status; // 'ACTIVE' | 'CANCELLED'
  final String? cancelledBy;
  final String? cancelledDate;
  final String? cancelledReason;
  final String createdAt;

  const SalesOrder({
    required this.id,
    required this.voucherNo,
    required this.voucherType,
    required this.billingType,
    required this.pricingType,
    required this.customerId,
    this.customerName,
    required this.date,
    required this.time,
    required this.salesperson,
    this.deliveryMan = 'Srinivasan',
    this.godown = 'Main Godown',
    this.route = 'Local',
    this.address = '',
    this.gstin = '',
    this.priceList = 'RETAIL',
    this.dispatch = 'Delivered',
    this.payStatus = 'Paid',
    this.payMode = 'Cash',
    this.userId = '',
    this.userName = '',
    this.userRole = 'cashier',
    this.createdBy = '',
    this.createdByRole = 'cashier',
    required this.items,
    required this.subtotal,
    this.discountTotal = 0.0,
    required this.gstTotal,
    this.roundOff = 0.0,
    required this.grandTotal,
    this.dispatchDetails,
    this.ewbDetails,
    this.status = 'ACTIVE',
    this.cancelledBy,
    this.cancelledDate,
    this.cancelledReason,
    required this.createdAt,
  });

  bool get isGst => billingType == 'GST';
  bool get isNonGst => billingType == 'NON_GST';
  bool get isCancelled => status == 'CANCELLED';

  SalesOrder copyWith({
    String? id,
    String? voucherNo,
    String? voucherType,
    String? billingType,
    PricingType? pricingType,
    String? customerId,
    String? customerName,
    String? date,
    String? time,
    String? salesperson,
    String? deliveryMan,
    String? godown,
    String? route,
    String? address,
    String? gstin,
    String? priceList,
    String? dispatch,
    String? payStatus,
    String? payMode,
    String? userId,
    String? userName,
    String? userRole,
    String? createdBy,
    String? createdByRole,
    List<InvoiceItem>? items,
    double? subtotal,
    double? discountTotal,
    double? gstTotal,
    double? roundOff,
    double? grandTotal,
    DispatchDetails? dispatchDetails,
    EWayBillDetails? ewbDetails,
    String? status,
    String? cancelledBy,
    String? cancelledDate,
    String? cancelledReason,
    String? createdAt,
  }) {
    return SalesOrder(
      id: id ?? this.id,
      voucherNo: voucherNo ?? this.voucherNo,
      voucherType: voucherType ?? this.voucherType,
      billingType: billingType ?? this.billingType,
      pricingType: pricingType ?? this.pricingType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      time: time ?? this.time,
      salesperson: salesperson ?? this.salesperson,
      deliveryMan: deliveryMan ?? this.deliveryMan,
      godown: godown ?? this.godown,
      route: route ?? this.route,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      priceList: priceList ?? this.priceList,
      dispatch: dispatch ?? this.dispatch,
      payStatus: payStatus ?? this.payStatus,
      payMode: payMode ?? this.payMode,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      createdBy: createdBy ?? this.createdBy,
      createdByRole: createdByRole ?? this.createdByRole,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountTotal: discountTotal ?? this.discountTotal,
      gstTotal: gstTotal ?? this.gstTotal,
      roundOff: roundOff ?? this.roundOff,
      grandTotal: grandTotal ?? this.grandTotal,
      dispatchDetails: dispatchDetails ?? this.dispatchDetails,
      ewbDetails: ewbDetails ?? this.ewbDetails,
      status: status ?? this.status,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledDate: cancelledDate ?? this.cancelledDate,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'voucherNo': voucherNo,
    'voucherType': voucherType,
    'billingType': billingType,
    'pricingType': pricingType.key,
    'customerId': customerId,
    'customerName': customerName,
    'date': date,
    'time': time,
    'salesperson': salesperson,
    'deliveryMan': deliveryMan,
    'godown': godown,
    'route': route,
    'address': address,
    'gstin': gstin,
    'priceList': priceList,
    'dispatch': dispatch,
    'payStatus': payStatus,
    'payMode': payMode,
    'userId': userId,
    'userName': userName,
    'userRole': userRole,
    'createdBy': createdBy,
    'createdByRole': createdByRole,
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal,
    'discountTotal': discountTotal,
    'gstTotal': gstTotal,
    'roundOff': roundOff,
    'grandTotal': grandTotal,
    'dispatchDetails': dispatchDetails?.toMap(),
    'ewbDetails': ewbDetails?.toMap(),
    'status': status,
    'cancelledBy': cancelledBy,
    'cancelledDate': cancelledDate,
    'cancelledReason': cancelledReason,
    'createdAt': createdAt,
  };

  factory SalesOrder.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? [];
    return SalesOrder(
      id: map['id'] ?? '',
      voucherNo: map['voucherNo'] ?? '',
      voucherType: map['voucherType'] ?? 'GST Invoice',
      billingType: map['billingType'] ?? 'GST',
      pricingType: PricingTypeExtension.fromString(map['pricingType']),
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'],
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      salesperson: map['salesperson'] ?? 'Srinivasan',
      deliveryMan: map['deliveryMan'] ?? 'Srinivasan',
      godown: map['godown'] ?? 'Main Godown',
      route: map['route'] ?? 'Local',
      address: map['address'] ?? '',
      gstin: map['gstin'] ?? '',
      priceList: map['priceList'] ?? 'RETAIL',
      dispatch: map['dispatch'] ?? 'Delivered',
      payStatus: map['payStatus'] ?? 'Paid',
      payMode: map['payMode'] ?? 'Cash',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? 'cashier',
      createdBy: map['createdBy'] ?? '',
      createdByRole: map['createdByRole'] ?? 'cashier',
      items: rawItems.map((it) => InvoiceItem.fromMap(it as Map<String, dynamic>)).toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountTotal: (map['discountTotal'] as num?)?.toDouble() ?? 0.0,
      gstTotal: (map['gstTotal'] as num?)?.toDouble() ?? 0.0,
      roundOff: (map['roundOff'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      dispatchDetails: DispatchDetails.fromMap(map['dispatchDetails']),
      ewbDetails: EWayBillDetails.fromMap(map['ewbDetails']),
      status: map['status'] ?? 'ACTIVE',
      cancelledBy: map['cancelledBy'],
      cancelledDate: map['cancelledDate'],
      cancelledReason: map['cancelledReason'],
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
