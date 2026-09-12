enum PricingType { agency, wholesale, retail }

extension PricingTypeExtension on PricingType {
  String get key {
    switch (this) {
      case PricingType.agency:
        return 'AGENCY';
      case PricingType.wholesale:
        return 'WHOLESALE';
      case PricingType.retail:
        return 'RETAIL';
    }
  }

  String get label {
    switch (this) {
      case PricingType.agency:
        return 'Agency Rate';
      case PricingType.wholesale:
        return 'Wholesale Rate';
      case PricingType.retail:
        return 'Retail Rate';
    }
  }

  static PricingType fromString(String? val) {
    if (val == null) return PricingType.retail;
    final upper = val.toUpperCase();
    if (upper == 'AGENCY') return PricingType.agency;
    if (upper == 'WHOLESALE') return PricingType.wholesale;
    return PricingType.retail;
  }
}

class Brand {
  final String id;
  final String name;
  final String type;
  final String color;
  final String contact;
  final String phone;
  final String gstin;

  const Brand({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.contact,
    required this.phone,
    required this.gstin,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'color': color,
    'contact': contact,
    'phone': phone,
    'gstin': gstin,
  };

  factory Brand.fromMap(Map<String, dynamic> map) {
    return Brand(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Own Brand',
      color: map['color'] ?? '#e3a92e',
      contact: map['contact'] ?? '',
      phone: map['phone'] ?? '',
      gstin: map['gstin'] ?? '',
    );
  }
}

class Product {
  final String id;
  final String code;
  final String brandId;
  final String name;
  final String category;
  final String? group;
  final String oilType;
  final String pack;
  final String unit;
  final String sku;
  final String hsn;
  final double gst;
  final double cost;
  final double price; // fallback retail
  final double agencyRate;
  final double wholesaleRate;
  final double retailRate;
  final double mrp;
  final double minStock;
  final double stock;
  final String status; // 'Active' | 'Inactive'
  final String? createdDate;
  final String? updatedDate;

  const Product({
    required this.id,
    required this.code,
    required this.brandId,
    required this.name,
    required this.category,
    this.group,
    required this.oilType,
    required this.pack,
    required this.unit,
    required this.sku,
    required this.hsn,
    required this.gst,
    required this.cost,
    required this.price,
    required this.agencyRate,
    required this.wholesaleRate,
    required this.retailRate,
    required this.mrp,
    required this.minStock,
    required this.stock,
    this.status = 'Active',
    this.createdDate,
    this.updatedDate,
  });

  double getRateFor(PricingType type) {
    switch (type) {
      case PricingType.agency:
        return agencyRate > 0 ? agencyRate : price;
      case PricingType.wholesale:
        return wholesaleRate > 0 ? wholesaleRate : price;
      case PricingType.retail:
        return retailRate > 0 ? retailRate : price;
    }
  }

  Product copyWith({
    String? id,
    String? code,
    String? brandId,
    String? name,
    String? category,
    String? group,
    String? oilType,
    String? pack,
    String? unit,
    String? sku,
    String? hsn,
    double? gst,
    double? cost,
    double? price,
    double? agencyRate,
    double? wholesaleRate,
    double? retailRate,
    double? mrp,
    double? minStock,
    double? stock,
    String? status,
    String? createdDate,
    String? updatedDate,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      category: category ?? this.category,
      group: group ?? this.group,
      oilType: oilType ?? this.oilType,
      pack: pack ?? this.pack,
      unit: unit ?? this.unit,
      sku: sku ?? this.sku,
      hsn: hsn ?? this.hsn,
      gst: gst ?? this.gst,
      cost: cost ?? this.cost,
      price: price ?? this.price,
      agencyRate: agencyRate ?? this.agencyRate,
      wholesaleRate: wholesaleRate ?? this.wholesaleRate,
      retailRate: retailRate ?? this.retailRate,
      mrp: mrp ?? this.mrp,
      minStock: minStock ?? this.minStock,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'brandId': brandId,
    'name': name,
    'category': category,
    'group': group,
    'oilType': oilType,
    'pack': pack,
    'unit': unit,
    'sku': sku,
    'hsn': hsn,
    'gst': gst,
    'cost': cost,
    'price': price,
    'agencyRate': agencyRate,
    'wholesaleRate': wholesaleRate,
    'retailRate': retailRate,
    'mrp': mrp,
    'minStock': minStock,
    'stock': stock,
    'status': status,
    'createdDate': createdDate,
    'updatedDate': updatedDate,
  };

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      brandId: map['brandId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'Edible Oils',
      group: map['group'],
      oilType: map['oilType'] ?? 'Groundnut Oil',
      pack: map['pack'] ?? '1 L',
      unit: map['unit'] ?? 'Bottle',
      sku: map['sku'] ?? '',
      hsn: map['hsn'] ?? '1508',
      gst: (map['gst'] as num?)?.toDouble() ?? 5.0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      agencyRate: (map['agencyRate'] as num?)?.toDouble() ?? 0.0,
      wholesaleRate: (map['wholesaleRate'] as num?)?.toDouble() ?? 0.0,
      retailRate: (map['retailRate'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      minStock: (map['minStock'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Active',
      createdDate: map['createdDate'],
      updatedDate: map['updatedDate'],
    );
  }
}

class RawMaterial {
  final String id;
  final String name;
  final String unit;
  final double stock;
  final double minStock;
  final double cost;
  final String godown;

  const RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.cost,
    required this.godown,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'unit': unit,
    'stock': stock,
    'minStock': minStock,
    'cost': cost,
    'godown': godown,
  };

  factory RawMaterial.fromMap(Map<String, dynamic> map) {
    return RawMaterial(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'kg',
      stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
      minStock: (map['minStock'] as num?)?.toDouble() ?? 0.0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      godown: map['godown'] ?? 'Main Godown',
    );
  }
}

class PriceHistoryRecord {
  final String id;
  final String productId;
  final String productName;
  final PricingType pricingType;
  final double oldRate;
  final double newRate;
  final String effectiveDate;
  final String updatedBy;
  final String updatedAt;

  const PriceHistoryRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pricingType,
    required this.oldRate,
    required this.newRate,
    required this.effectiveDate,
    required this.updatedBy,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'pricingType': pricingType.key,
    'oldRate': oldRate,
    'newRate': newRate,
    'effectiveDate': effectiveDate,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
  };

  factory PriceHistoryRecord.fromMap(Map<String, dynamic> map) {
    return PriceHistoryRecord(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      pricingType: PricingTypeExtension.fromString(map['pricingType']),
      oldRate: (map['oldRate'] as num?)?.toDouble() ?? 0.0,
      newRate: (map['newRate'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: map['effectiveDate'] ?? '',
      updatedBy: map['updatedBy'] ?? 'Admin',
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class AuditRecord {
  final String id;
  final String user;
  final String userId;
  final String role;
  final String action;
  final String module;
  final String details;
  final String timestamp;

  const AuditRecord({
    required this.id,
    required this.user,
    required this.userId,
    required this.role,
    required this.action,
    required this.module,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user': user,
    'userId': userId,
    'role': role,
    'action': action,
    'module': module,
    'details': details,
    'timestamp': timestamp,
  };

  factory AuditRecord.fromMap(Map<String, dynamic> map) {
    return AuditRecord(
      id: map['id'] ?? '',
      user: map['user'] ?? 'System',
      userId: map['userId'] ?? 'sys',
      role: map['role'] ?? 'System',
      action: map['action'] ?? '',
      module: map['module'] ?? '',
      details: map['details'] ?? '',
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}
