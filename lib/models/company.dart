class BankDetails {
  final String name;
  final String acc;
  final String ifsc;

  const BankDetails({
    required this.name,
    required this.acc,
    required this.ifsc,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'acc': acc,
    'ifsc': ifsc,
  };

  factory BankDetails.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const BankDetails(name: '', acc: '', ifsc: '');
    }
    return BankDetails(
      name: map['name'] ?? '',
      acc: map['acc'] ?? '',
      ifsc: map['ifsc'] ?? '',
    );
  }
}

class Company {
  final String name;
  final String? legal;
  final String address;
  final String gstin;
  final String stateCode;
  final String state;
  final String phone;
  final String email;
  final String? fssai;
  final BankDetails? bank;

  const Company({
    required this.name,
    this.legal,
    required this.address,
    required this.gstin,
    required this.stateCode,
    required this.state,
    required this.phone,
    required this.email,
    this.fssai,
    this.bank,
  });

  Company copyWith({
    String? name,
    String? legal,
    String? address,
    String? gstin,
    String? stateCode,
    String? state,
    String? phone,
    String? email,
    String? fssai,
    BankDetails? bank,
  }) {
    return Company(
      name: name ?? this.name,
      legal: legal ?? this.legal,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      stateCode: stateCode ?? this.stateCode,
      state: state ?? this.state,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fssai: fssai ?? this.fssai,
      bank: bank ?? this.bank,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'legal': legal,
    'address': address,
    'gstin': gstin,
    'stateCode': stateCode,
    'state': state,
    'phone': phone,
    'email': email,
    'fssai': fssai,
    'bank': bank?.toMap(),
  };

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      name: map['name'] ?? 'KKK Oil Factory',
      legal: map['legal'],
      address: map['address'] ?? '',
      gstin: map['gstin'] ?? '',
      stateCode: map['stateCode'] ?? '33',
      state: map['state'] ?? 'Tamil Nadu',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      fssai: map['fssai'],
      bank: map['bank'] != null ? BankDetails.fromMap(map['bank']) : null,
    );
  }

  static const Company defaultCompany = Company(
    name: 'KKK OIL FACTORY',
    legal: 'KKK Oils & Agro Industries Pvt Ltd',
    address: 'Plot 12-14, SIPCOT Industrial Complex, Dharmapuri - 636701, Tamil Nadu',
    gstin: '33AAECK1234F1Z5',
    stateCode: '33',
    state: 'Tamil Nadu',
    phone: '+91 98430 11111 / +91 98430 22222',
    email: 'billing@kkkoil.in',
    fssai: '12421004000123',
    bank: BankDetails(
      name: 'State Bank of India',
      acc: '39485720194',
      ifsc: 'SBIN0001234',
    ),
  );
}
