class ProductionBatch {
  final String id;
  final String productId;
  final double plannedQty;
  final double outputQty;
  final double wastage;
  final String status; // 'Completed' | 'In Progress' | 'Planned'
  final String startDate;
  final String mfgDate;
  final String expDate;
  final double rawCost;
  final double packCost;
  final double labourCost;

  const ProductionBatch({
    required this.id,
    required this.productId,
    required this.plannedQty,
    required this.outputQty,
    this.wastage = 0.0,
    this.status = 'Completed',
    required this.startDate,
    required this.mfgDate,
    required this.expDate,
    this.rawCost = 0.0,
    this.packCost = 0.0,
    this.labourCost = 0.0,
  });

  double get totalCost => rawCost + packCost + labourCost;
  double get recoveryYield => plannedQty > 0 ? (outputQty / plannedQty) * 100 : 0.0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'plannedQty': plannedQty,
    'outputQty': outputQty,
    'wastage': wastage,
    'status': status,
    'startDate': startDate,
    'mfgDate': mfgDate,
    'expDate': expDate,
    'rawCost': rawCost,
    'packCost': packCost,
    'labourCost': labourCost,
  };

  factory ProductionBatch.fromMap(Map<String, dynamic> map) {
    return ProductionBatch(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      plannedQty: (map['plannedQty'] as num?)?.toDouble() ?? 0.0,
      outputQty: (map['outputQty'] as num?)?.toDouble() ?? 0.0,
      wastage: (map['wastage'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Completed',
      startDate: map['startDate'] ?? '',
      mfgDate: map['mfgDate'] ?? '',
      expDate: map['expDate'] ?? '',
      rawCost: (map['rawCost'] as num?)?.toDouble() ?? 0.0,
      packCost: (map['packCost'] as num?)?.toDouble() ?? 0.0,
      labourCost: (map['labourCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Purchase {
  final String id;
  final String supplierId;
  final String date;
  final String material;
  final double qty;
  final String unit;
  final double rate;
  final double gst;
  final String qc; // 'Passed' | 'Pending'
  final String payStatus; // 'Paid' | 'Pending' | 'Partial'
  final bool inward;

  const Purchase({
    required this.id,
    required this.supplierId,
    required this.date,
    required this.material,
    required this.qty,
    required this.unit,
    required this.rate,
    this.gst = 5.0,
    this.qc = 'Passed',
    this.payStatus = 'Paid',
    this.inward = true,
  });

  double get totalAmount => (qty * rate) * (1 + (gst / 100));

  Map<String, dynamic> toMap() => {
    'id': id,
    'supplierId': supplierId,
    'date': date,
    'material': material,
    'qty': qty,
    'unit': unit,
    'rate': rate,
    'gst': gst,
    'qc': qc,
    'payStatus': payStatus,
    'inward': inward,
  };

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] ?? '',
      supplierId: map['supplierId'] ?? '',
      date: map['date'] ?? '',
      material: map['material'] ?? '',
      qty: (map['qty'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      gst: (map['gst'] as num?)?.toDouble() ?? 5.0,
      qc: map['qc'] ?? 'Passed',
      payStatus: map['payStatus'] ?? 'Paid',
      inward: map['inward'] ?? true,
    );
  }
}

class Dispatch {
  final String id;
  final String soId;
  final String vehicle;
  final String driver;
  final String route;
  final String status; // 'Delivered' | 'In Transit' | 'Loading'
  final double transport;
  final bool pod;

  const Dispatch({
    required this.id,
    required this.soId,
    required this.vehicle,
    required this.driver,
    required this.route,
    required this.status,
    this.transport = 0.0,
    this.pod = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'soId': soId,
    'vehicle': vehicle,
    'driver': driver,
    'route': route,
    'status': status,
    'transport': transport,
    'pod': pod,
  };

  factory Dispatch.fromMap(Map<String, dynamic> map) {
    return Dispatch(
      id: map['id'] ?? '',
      soId: map['soId'] ?? '',
      vehicle: map['vehicle'] ?? '',
      driver: map['driver'] ?? '',
      route: map['route'] ?? '',
      status: map['status'] ?? 'Delivered',
      transport: (map['transport'] as num?)?.toDouble() ?? 0.0,
      pod: map['pod'] ?? false,
    );
  }
}

class Expense {
  final String id;
  final String date;
  final String head;
  final String note;
  final double amount;

  const Expense({
    required this.id,
    required this.date,
    required this.head,
    required this.note,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'head': head,
    'note': note,
    'amount': amount,
  };

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      head: map['head'] ?? 'General',
      note: map['note'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
