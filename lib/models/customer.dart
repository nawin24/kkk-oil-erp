class Customer {
  final String id;
  final String? code;
  final String name;
  final String type; // 'Supermarket', 'Wholesaler', 'Retail Store', etc.
  final String contact;
  final String phone;
  final String gstin;
  final String address;
  final String area;
  final String route;
  final String priceList; // 'AGENCY', 'WHOLESALE', 'RETAIL'
  final double creditLimit;
  final double outstanding;
  final String brandPref;

  const Customer({
    required this.id,
    this.code,
    required this.name,
    required this.type,
    required this.contact,
    required this.phone,
    required this.gstin,
    this.address = '',
    required this.area,
    required this.route,
    this.priceList = 'RETAIL',
    this.creditLimit = 0.0,
    this.outstanding = 0.0,
    this.brandPref = 'KKK Gold',
  });

  Customer copyWith({
    String? id,
    String? code,
    String? name,
    String? type,
    String? contact,
    String? phone,
    String? gstin,
    String? address,
    String? area,
    String? route,
    String? priceList,
    double? creditLimit,
    double? outstanding,
    String? brandPref,
  }) {
    return Customer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      contact: contact ?? this.contact,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      area: area ?? this.area,
      route: route ?? this.route,
      priceList: priceList ?? this.priceList,
      creditLimit: creditLimit ?? this.creditLimit,
      outstanding: outstanding ?? this.outstanding,
      brandPref: brandPref ?? this.brandPref,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'name': name,
    'type': type,
    'contact': contact,
    'phone': phone,
    'gstin': gstin,
    'address': address,
    'area': area,
    'route': route,
    'priceList': priceList,
    'creditLimit': creditLimit,
    'outstanding': outstanding,
    'brandPref': brandPref,
  };

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      code: map['code'],
      name: map['name'] ?? '',
      type: map['type'] ?? 'Retail Store',
      contact: map['contact'] ?? '',
      phone: map['phone'] ?? '',
      gstin: map['gstin'] ?? '',
      address: map['address'] ?? '',
      area: map['area'] ?? '',
      route: map['route'] ?? '',
      priceList: map['priceList'] ?? 'RETAIL',
      creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0.0,
      outstanding: (map['outstanding'] as num?)?.toDouble() ?? 0.0,
      brandPref: map['brandPref'] ?? 'KKK Gold',
    );
  }
}

class Supplier {
  final String id;
  final String name;
  final String material;
  final String contact;
  final String phone;
  final String gstin;
  final String address;
  final double rating;
  final double due;

  const Supplier({
    required this.id,
    required this.name,
    required this.material,
    required this.contact,
    required this.phone,
    required this.gstin,
    required this.address,
    this.rating = 4.5,
    this.due = 0.0,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? material,
    String? contact,
    String? phone,
    String? gstin,
    String? address,
    double? rating,
    double? due,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      material: material ?? this.material,
      contact: contact ?? this.contact,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      due: due ?? this.due,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'material': material,
    'contact': contact,
    'phone': phone,
    'gstin': gstin,
    'address': address,
    'rating': rating,
    'due': due,
  };

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      material: map['material'] ?? '',
      contact: map['contact'] ?? '',
      phone: map['phone'] ?? '',
      gstin: map['gstin'] ?? '',
      address: map['address'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      due: (map['due'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
