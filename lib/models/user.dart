class RoleDefinition {
  final String id;
  final String key;
  final String label;
  final String desc;
  final String tone; // 'gold' | 'green' | 'blue' | 'amber' | 'purple' | 'red'
  final dynamic access; // '*' or List<String>
  final String superiorRole;
  final int rank;
  final bool isSystem;

  const RoleDefinition({
    required this.id,
    required this.key,
    required this.label,
    required this.desc,
    this.tone = 'gold',
    required this.access,
    this.superiorRole = '',
    this.rank = 1,
    this.isSystem = true,
  });

  bool canAccess(String moduleKey) {
    if (access == '*') return true;
    if (access is List) {
      return (access as List).contains(moduleKey);
    }
    return false;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'key': key,
    'label': label,
    'desc': desc,
    'tone': tone,
    'access': access,
    'superiorRole': superiorRole,
    'rank': rank,
    'isSystem': isSystem,
  };

  factory RoleDefinition.fromMap(Map<String, dynamic> map) {
    return RoleDefinition(
      id: map['id'] ?? '',
      key: map['key'] ?? '',
      label: map['label'] ?? '',
      desc: map['desc'] ?? '',
      tone: map['tone'] ?? 'gold',
      access: map['access'] ?? '*',
      superiorRole: map['superiorRole'] ?? '',
      rank: map['rank'] ?? 1,
      isSystem: map['isSystem'] ?? false,
    );
  }
}

class AppUser {
  final String id;
  final String username;
  final String name;
  final String role;
  final String passwordHash;
  final String? plainPassword;
  final String? phone;
  final String? email;
  final bool active;
  final String? firedReason;
  final String? firedDate;
  final String? createdDate;

  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.passwordHash,
    this.plainPassword,
    this.phone,
    this.email,
    this.active = true,
    this.firedReason,
    this.firedDate,
    this.createdDate,
  });

  AppUser copyWith({
    String? id,
    String? username,
    String? name,
    String? role,
    String? passwordHash,
    String? plainPassword,
    String? phone,
    String? email,
    bool? active,
    String? firedReason,
    String? firedDate,
    String? createdDate,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      plainPassword: plainPassword ?? this.plainPassword,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      active: active ?? this.active,
      firedReason: firedReason ?? this.firedReason,
      firedDate: firedDate ?? this.firedDate,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'name': name,
    'role': role,
    'passwordHash': passwordHash,
    'plainPassword': plainPassword,
    'phone': phone,
    'email': email,
    'active': active,
    'firedReason': firedReason,
    'firedDate': firedDate,
    'createdDate': createdDate,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'cashier',
      passwordHash: map['passwordHash'] ?? '',
      plainPassword: map['plainPassword'],
      phone: map['phone'],
      email: map['email'],
      active: map['active'] ?? true,
      firedReason: map['firedReason'],
      firedDate: map['firedDate'],
      createdDate: map['createdDate'],
    );
  }
}

enum BillingMode { gst, nonGst }

class UserSession {
  final String id;
  final String username;
  final String name;
  final String role;
  final String roleLabel;
  final dynamic access;
  final BillingMode activeMode;

  const UserSession({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.roleLabel,
    required this.access,
    this.activeMode = BillingMode.gst,
  });

  bool get isSuperAdmin => role == 'super_admin' || role == 'super_admin_nongst';
  bool get isAdmin => isSuperAdmin || role == 'admin';
  bool get isManager => isAdmin || role == 'manager';
  bool get isCashier => role == 'cashier';
  bool get isNonGstMode => isSuperAdmin && activeMode == BillingMode.nonGst;

  bool can(String moduleKey) {
    if (isSuperAdmin) return true;
    if (access == '*') return true;
    if (access is List) {
      return (access as List).contains(moduleKey);
    }
    return false;
  }

  UserSession copyWith({
    String? id,
    String? username,
    String? name,
    String? role,
    String? roleLabel,
    dynamic access,
    BillingMode? activeMode,
  }) {
    return UserSession(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
      roleLabel: roleLabel ?? this.roleLabel,
      access: access ?? this.access,
      activeMode: activeMode ?? this.activeMode,
    );
  }
}

/// Role Hierarchy Permission Rules:
/// Rank 1: Super Admin (Executive authority, superior to all)
/// Rank 2: Admin (ERP Administrator, reports to Super Admin)
/// Rank 3: Manager (Reports to Admin)
/// Rank 4+: Cashier, Production Staff, Logistics, and custom roles
bool canManageUser(UserSession? actor, AppUser target, Map<String, RoleDefinition> roles) {
  if (actor == null || actor.id == target.id) return false;
  // Super Admin can manage all
  if (actor.role == 'super_admin' || actor.role == 'super_admin_nongst') return true;
  // Super Admin is ALWAYS protected from regular Admins
  if (target.role == 'super_admin' ||
      target.role == 'super_admin_nongst' ||
      target.username.toLowerCase() == 'admin') {
    return false;
  }
  // Admin cannot edit another Admin (peer protection)
  if (target.role == 'admin' && actor.role == 'admin') return false;
  // Rank check: Actor must be strictly superior (lower rank number)
  final actorRank = roles[actor.role]?.rank ?? 99;
  final targetRank = roles[target.role]?.rank ?? 99;
  return actorRank < targetRank;
}

List<RoleDefinition> getAssignableRoles(UserSession? actor, Map<String, RoleDefinition> roles) {
  if (actor == null) return [];
  if (actor.role == 'super_admin' || actor.role == 'super_admin_nongst') {
    return roles.values.where((r) => r.key != 'super_admin_nongst').toList();
  }
  final actorRank = roles[actor.role]?.rank ?? 99;
  // Admin can ONLY assign roles strictly below Admin's rank (rank > 2).
  // Admin CANNOT create or assign Super Admin or Admin!
  return roles.values
      .where((r) => r.rank > actorRank && r.key != 'super_admin' && r.key != 'admin')
      .toList();
}

