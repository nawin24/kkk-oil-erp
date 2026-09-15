import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAllPasswords = false;
  final Set<String> _revealedUsers = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all' | 'active' | 'inactive'

  // The 15 ERP Modules Matrix
  static const List<Map<String, String>> availableModules = [
    {'key': 'dashboard', 'label': 'Dashboard Overview', 'path': '/'},
    {'key': 'billing', 'label': 'Billing & POS Invoices', 'path': '/gst-billing'},
    {'key': 'products', 'label': 'Products Master', 'path': '/products'},
    {'key': 'price_management', 'label': 'Price Management', 'path': '/price-management'},
    {'key': 'price_history', 'label': 'Price Revision History', 'path': '/price-history'},
    {'key': 'inventory', 'label': 'Inventory & Stock Valuation', 'path': '/inventory'},
    {'key': 'purchase', 'label': 'Purchase & Inward', 'path': '/purchase'},
    {'key': 'production', 'label': 'Production Milling', 'path': '/production'},
    {'key': 'sales', 'label': 'Sales & Dispatch Ledger', 'path': '/sales'},
    {'key': 'logistics', 'label': 'Logistics & Gate Passes', 'path': '/logistics'},
    {'key': 'customers', 'label': 'Customers & Accounts', 'path': '/customers'},
    {'key': 'suppliers', 'label': 'Suppliers & Millers', 'path': '/suppliers'},
    {'key': 'reports', 'label': 'Reports & Tax Analytics', 'path': '/reports'},
    {'key': 'employees', 'label': 'Employees & Roles', 'path': '/employees'},
    {'key': 'settings', 'label': 'Company Settings', 'path': '/settings'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Color mapper for role themes
  Color _getToneColor(String tone) {
    switch (tone.toLowerCase()) {
      case 'gold':
        return AppColors.gold;
      case 'blue':
        return AppColors.blue;
      case 'green':
        return AppColors.green;
      case 'amber':
        return AppColors.amber;
      case 'purple':
        return AppColors.purple;
      case 'red':
        return AppColors.red;
      default:
        return AppColors.forestAccent;
    }
  }

  // ==========================================
  // ADD EMPLOYEE MODAL / BOTTOM SHEET
  // ==========================================
  void _showAddEmployeeSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final assignableRoles = getAssignableRoles(currentUser, auth.roles);

    if (assignableRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to create accounts.')),
      );
      return;
    }

    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'staff123');
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = assignableRoles.first.key;
    bool obscurePassword = true;

    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget formContent(void Function(void Function()) setModalState) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_add, color: AppColors.goldDeep, size: 20),
                      SizedBox(width: 8),
                      Text('Add Staff Employee Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Staff Login Username',
                  hintText: 'e.g. cashier_suresh',
                  prefixIcon: Icon(Icons.alternate_email, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Suresh Kumar',
                  prefixIcon: Icon(Icons.badge_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Operational Role',
                  prefixIcon: Icon(Icons.shield_outlined, size: 18),
                ),
                items: assignableRoles.map((r) {
                  return DropdownMenuItem(
                    value: r.key,
                    child: Text('${r.label} (Rank ${r.rank})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: obscurePassword,
                style: AppTheme.mono(fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Initial Password',
                  hintText: 'e.g. staff123',
                  prefixIcon: const Icon(Icons.key, size: 18, color: AppColors.goldDark),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Phone',
                  hintText: '+91 98430 00000',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Work Email (Optional)',
                  hintText: 'suresh@kkkoil.in',
                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  GoldButton(
                    label: 'Create Staff Account',
                    icon: Icons.check,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () async {
                      if (userCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Username and Full Name are required.')),
                        );
                        return;
                      }
                      final res = await auth.addUser(
                        username: userCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        role: selectedRole,
                        password: passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : 'staff123',
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        if (res['ok'] == true) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Staff employee account created successfully!'), backgroundColor: AppColors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['error'] ?? 'Error creating account')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(builder: (c, setDlg) => formContent(setDlg)),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: StatefulBuilder(builder: (c, setDlg) => formContent(setDlg)),
          ),
        ),
      );
    }
  }

  // ==========================================
  // EDIT EMPLOYEE MODAL / BOTTOM SHEET
  // ==========================================
  void _showEditEmployeeSheet(BuildContext context, AppUser user) {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final assignableRoles = getAssignableRoles(currentUser, auth.roles);

    // If target's current role is not in assignable list (e.g. Super Admin editing another Super Admin), keep it accessible
    final roleOptions = List<RoleDefinition>.from(assignableRoles);
    if (!roleOptions.any((r) => r.key == user.role) && auth.roles.containsKey(user.role)) {
      roleOptions.insert(0, auth.roles[user.role]!);
    }

    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final newPassCtrl = TextEditingController();
    String selectedRole = user.role;
    bool obscureNewPass = true;
    bool revealCurrentPassword = false;

    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget formContent(void Function(void Function()) setModalState) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined, color: AppColors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text('Edit Account: @${user.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Super Admin Password Inspection Banner
              if (currentUser?.isSuperAdmin == true) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_outlined, size: 18, color: AppColors.goldDeep),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT STORED PASSWORD (SUPER ADMIN)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              revealCurrentPassword
                                  ? (user.plainPassword ?? 'admin123')
                                  : '••••••••',
                              style: AppTheme.mono(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: revealCurrentPassword ? AppColors.textMain : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          revealCurrentPassword ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                          color: AppColors.goldDeep,
                        ),
                        tooltip: revealCurrentPassword ? 'Hide plain password' : 'Reveal plain password',
                        onPressed: () => setModalState(() => revealCurrentPassword = !revealCurrentPassword),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.badge_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Operational Role',
                  prefixIcon: Icon(Icons.shield_outlined, size: 18),
                ),
                items: roleOptions.map((r) {
                  return DropdownMenuItem(
                    value: r.key,
                    child: Text('${r.label} (Rank ${r.rank})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Phone',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Work Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: obscureNewPass,
                style: AppTheme.mono(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'New Password (Leave blank to keep unchanged)',
                  hintText: 'Enter new password',
                  prefixIcon: const Icon(Icons.lock_reset, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPass ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setModalState(() => obscureNewPass = !obscureNewPass),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final patch = <String, dynamic>{
                        'name': nameCtrl.text.trim(),
                        'role': selectedRole,
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                      };
                      if (newPassCtrl.text.trim().isNotEmpty) {
                        patch['password'] = newPassCtrl.text.trim();
                      }
                      await auth.updateUser(user.id, patch);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Employee profile updated successfully!'), backgroundColor: AppColors.green),
                        );
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(builder: (c, setDlg) => formContent(setDlg)),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: StatefulBuilder(builder: (c, setDlg) => formContent(setDlg)),
          ),
        ),
      );
    }
  }

  // ==========================================
  // DYNAMIC CUSTOM ROLE CREATOR (15 MODULES)
  // ==========================================
  void _showAddRoleSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final keyCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String superiorRole = 'admin';
    String colorTone = 'gold'; // gold, blue, green, amber, purple, red
    final Set<String> selectedModules = {'dashboard', 'billing', 'inventory', 'customers'};

    // Available superior roles (Rank < 4: Super Admin, Admin, Manager)
    final superiorOptions = auth.roles.entries
        .where((e) => e.value.rank <= 3)
        .toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget formContent(void Function(void Function()) setModalState) {
      final superiorDef = auth.roles[superiorRole];
      final computedRank = (superiorDef?.rank ?? 2) + 1;

      // Detect subordinates: roles whose superiorRole is this key
      final currentKey = keyCtrl.text.trim().toLowerCase();
      final subordinates = currentKey.isEmpty
          ? <String>[]
          : auth.roles.values.where((r) => r.superiorRole == currentKey).map((r) => r.label).toList();

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, color: AppColors.goldDeep, size: 20),
                      SizedBox(width: 8),
                      Text('Create Custom Role (15 ERP Modules)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Role Name (பதவியின் பெயர்)',
                  hintText: 'e.g. Quality Auditor',
                  prefixIcon: Icon(Icons.badge_outlined, size: 18),
                ),
                onChanged: (val) {
                  if (keyCtrl.text.isEmpty || keyCtrl.text == val.toLowerCase().replaceAll(' ', '_')) {
                    setModalState(() {
                      keyCtrl.text = val.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                style: AppTheme.mono(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Role Key (System Identifier)',
                  hintText: 'quality_auditor',
                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Role Description',
                  hintText: 'e.g. Responsible for quality testing & milling audits',
                  prefixIcon: Icon(Icons.description_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 14),

              // Color Theme Selector
              const Text('Color Theme (வண்ண அடையாளம்):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final t in ['gold', 'blue', 'green', 'amber', 'purple', 'red']) ...[
                    InkWell(
                      onTap: () => setModalState(() => colorTone = t),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _getToneColor(t),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorTone == t ? AppColors.textMain : Colors.transparent,
                            width: colorTone == t ? 2.5 : 0,
                          ),
                          boxShadow: colorTone == t
                              ? [BoxShadow(color: _getToneColor(t).withOpacity(0.4), blurRadius: 6, spreadRadius: 1)]
                              : null,
                        ),
                        child: colorTone == t ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Superior Role Dropdown (மேலதிகாரி)
              DropdownButtonFormField<String>(
                value: superiorRole,
                decoration: InputDecoration(
                  labelText: 'Superior Role / மேலதிகாரி (Rank $computedRank)',
                  prefixIcon: const Icon(Icons.arrow_upward, size: 18),
                ),
                items: superiorOptions.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text('${e.value.label} (Rank ${e.value.rank})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => superiorRole = val);
                },
              ),
              const SizedBox(height: 12),

              // Live Hierarchy Preview Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LIVE HIERARCHY PREVIEW (அதிகார வரிசை):', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                            child: Text('Superior: [${superiorDef?.label ?? superiorRole}]', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward, size: 14, color: AppColors.goldDeep),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _getToneColor(colorTone).withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: _getToneColor(colorTone))),
                            child: Text('This: [${labelCtrl.text.isNotEmpty ? labelCtrl.text : "New Role"}]', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _getToneColor(colorTone))),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward, size: 14, color: AppColors.goldDeep),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surfaceWarm, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                            child: Text(
                              'Subordinates: [${subordinates.isNotEmpty ? subordinates.join(", ") : "None"}]',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Allowed ERP Paths Checklist (15 Modules)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Allowed Modules (${selectedModules.length}/15):',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () {
                          setModalState(() {
                            selectedModules.addAll(availableModules.map((m) => m['key']!));
                          });
                        },
                        child: const Text('Select All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.blue)),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () {
                          setModalState(() {
                            selectedModules.clear();
                            selectedModules.addAll(['dashboard', 'billing']);
                          });
                        },
                        child: const Text('Reset to Min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: availableModules.map((m) {
                  final isSel = selectedModules.contains(m['key']!);
                  return FilterChip(
                    selected: isSel,
                    label: Text(
                      m['label']!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel ? Colors.white : AppColors.textMain,
                      ),
                    ),
                    selectedColor: _getToneColor(colorTone),
                    checkmarkColor: Colors.white,
                    backgroundColor: AppColors.surface2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSel ? _getToneColor(colorTone) : AppColors.border),
                    ),
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          selectedModules.add(m['key']!);
                        } else {
                          selectedModules.remove(m['key']!);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  GoldButton(
                    label: 'Save Custom Role',
                    icon: Icons.check,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () async {
                      if (keyCtrl.text.trim().isEmpty || labelCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Role Name and Role Key are required.')),
                        );
                        return;
                      }

                      final newRole = RoleDefinition(
                        id: 'role-${keyCtrl.text.trim().toLowerCase()}',
                        key: keyCtrl.text.trim().toLowerCase(),
                        label: labelCtrl.text.trim(),
                        desc: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : labelCtrl.text.trim(),
                        tone: colorTone,
                        access: selectedModules.toList(),
                        superiorRole: superiorRole,
                        rank: computedRank,
                        isSystem: false,
                      );

                      await auth.addRole(newRole);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Custom role "${newRole.label}" created successfully!'), backgroundColor: AppColors.green),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(builder: (c, setDlg) => formContent(setDlg)),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: StatefulBuilder(builder: (c, setDlg) => formContent(setDlg)),
          ),
        ),
      );
    }
  }

  void _confirmDeleteUser(AppUser u, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to permanently delete employee @${u.username}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () {
              auth.deleteUser(u.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRole(RoleDefinition r, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to delete the custom role "${r.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () {
              auth.deleteRole(r.key);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffAccountRow(AppUser u, AuthProvider auth, UserSession? currentUser, bool isMobile) {
    final roleDef = auth.roles[u.role];
    final roleTone = roleDef?.tone ?? 'green';
    final toneColor = _getToneColor(roleTone);
    final canManage = canManageUser(currentUser, u, auth.roles);
    final isSuperAdmin = currentUser?.isSuperAdmin == true;
    final isRevealed = (_showAllPasswords || _revealedUsers.contains(u.id)) && isSuperAdmin;
    final displayPassword = isRevealed ? (u.plainPassword ?? 'admin123') : '••••••••';

    if (!isMobile) {
      // Desktop: Clean single horizontal row
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: toneColor,
              foregroundColor: Colors.white,
              radius: 16,
              child: Text(
                u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '@${u.username}${u.phone != null && u.phone!.isNotEmpty ? " · ${u.phone}" : ""}',
                    style: AppTheme.mono(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: toneColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                roleDef?.label ?? u.role,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: toneColor),
              ),
            ),
            const SizedBox(width: 10),
            if (!u.active)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                ),
                child: const Text('FIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.red)),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key, size: 14, color: AppColors.goldDeep),
                  const SizedBox(width: 5),
                  Text(displayPassword, style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.w700, color: isRevealed ? AppColors.textMain : AppColors.textMuted)),
                  if (isSuperAdmin) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_revealedUsers.contains(u.id)) {
                            _revealedUsers.remove(u.id);
                          } else {
                            _revealedUsers.add(u.id);
                          }
                        });
                      },
                      child: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 15, color: AppColors.goldDeep),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (canManage) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.blue),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _showEditEmployeeSheet(context, u),
              ),
              IconButton(
                icon: Icon(u.active ? Icons.block_outlined : Icons.check_circle_outline, size: 16, color: u.active ? AppColors.danger : AppColors.success),
                tooltip: u.active ? 'Fire / Deactivate' : 'Reactivate',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => auth.toggleUserActive(u.id),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => _confirmDeleteUser(u, auth),
              ),
            ] else if (u.id != currentUser?.id)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.gold),
                ),
                child: const Text('🔒 Protected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.goldDeep)),
              ),
          ],
        ),
      );
    }

    // Mobile compact card: 2 compact rows without overspace
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: toneColor,
                foregroundColor: Colors.white,
                radius: 14,
                child: Text(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        u.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textMain),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '@${u.username}',
                      style: AppTheme.mono(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: toneColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: toneColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  roleDef?.label ?? u.role,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: toneColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Password badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.key, size: 12, color: AppColors.goldDeep),
                    const SizedBox(width: 4),
                    Text(displayPassword, style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w700)),
                    if (isSuperAdmin) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (_revealedUsers.contains(u.id)) {
                              _revealedUsers.remove(u.id);
                            } else {
                              _revealedUsers.add(u.id);
                            }
                          });
                        },
                        child: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 14, color: AppColors.goldDeep),
                      ),
                    ],
                  ],
                ),
              ),
              // Action buttons
              if (canManage)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.blue),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () => _showEditEmployeeSheet(context, u),
                    ),
                    IconButton(
                      icon: Icon(u.active ? Icons.block_outlined : Icons.check_circle_outline, size: 16, color: u.active ? AppColors.danger : AppColors.success),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () => auth.toggleUserActive(u.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      onPressed: () => _confirmDeleteUser(u, auth),
                    ),
                  ],
                )
              else if (!u.active)
                const Text('FIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.red))
              else
                const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPACT SINGLE-ROW KPI STAT CARD (52px)
  // ==========================================
  Widget _buildKpiCard({
    required IconData icon,
    required Color color,
    required Color softColor,
    required String value,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? softColor : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: const [AppColors.shadowSm],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: AppTheme.kpiValue(color: color).copyWith(fontSize: 15, height: 1.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    // KPI Counts
    final totalStaff = auth.users.length;
    final activeStaff = auth.users.where((u) => u.active).length;
    final inactiveStaff = auth.users.where((u) => !u.active).length;
    final totalRoles = auth.roles.length;

    // Filter list
    final filteredUsers = auth.users.where((u) {
      if (_filterStatus == 'active' && !u.active) return false;
      if (_filterStatus == 'inactive' && u.active) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // 1. COMPACT SINGLE-ROW / 2x2 KPI ENGINE (Fits Screen Without Horizontal Scroll)
          // ----------------------------------------------------
          if (isMobile)
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildKpiCard(
                        icon: Icons.people_alt,
                        color: AppColors.goldDeep,
                        softColor: AppColors.goldSoft,
                        value: '$totalStaff',
                        label: 'Total Staff',
                        isSelected: _filterStatus == 'all',
                        onTap: () {
                          setState(() {
                            _filterStatus = 'all';
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildKpiCard(
                        icon: Icons.check_circle,
                        color: AppColors.green,
                        softColor: AppColors.greenSoft,
                        value: '$activeStaff',
                        label: 'Active Staff',
                        isSelected: _filterStatus == 'active',
                        onTap: () {
                          setState(() {
                            _filterStatus = _filterStatus == 'active' ? 'all' : 'active';
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildKpiCard(
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.red,
                        softColor: AppColors.redSoft,
                        value: '$inactiveStaff',
                        label: 'Fired / Inactive',
                        isSelected: _filterStatus == 'inactive',
                        onTap: () {
                          setState(() {
                            _filterStatus = _filterStatus == 'inactive' ? 'all' : 'inactive';
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildKpiCard(
                        icon: Icons.settings,
                        color: AppColors.purple,
                        softColor: AppColors.purpleSoft,
                        value: '$totalRoles',
                        label: 'Distinct Roles',
                        isSelected: false,
                        onTap: () {
                          _tabController.animateTo(1);
                        },
                      ),
                    ),
                  ],
                );
              },
            )
          else
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.people_alt,
                      color: AppColors.goldDeep,
                      softColor: AppColors.goldSoft,
                      value: '$totalStaff',
                      label: 'Total Staff',
                      isSelected: _filterStatus == 'all',
                      onTap: () {
                        setState(() {
                          _filterStatus = 'all';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.check_circle,
                      color: AppColors.green,
                      softColor: AppColors.greenSoft,
                      value: '$activeStaff',
                      label: 'Active Staff',
                      isSelected: _filterStatus == 'active',
                      onTap: () {
                        setState(() {
                          _filterStatus = _filterStatus == 'active' ? 'all' : 'active';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.red,
                      softColor: AppColors.redSoft,
                      value: '$inactiveStaff',
                      label: 'Fired / Inactive',
                      isSelected: _filterStatus == 'inactive',
                      onTap: () {
                        setState(() {
                          _filterStatus = _filterStatus == 'inactive' ? 'all' : 'inactive';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.settings,
                      color: AppColors.purple,
                      softColor: AppColors.purpleSoft,
                      value: '$totalRoles',
                      label: 'Distinct Roles',
                      isSelected: false,
                      onTap: () {
                        _tabController.animateTo(1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // ----------------------------------------------------
          // 2. TABS BAR (Staff Accounts / Roles & Hierarchy)
          // ----------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.forestDark,
              indicatorColor: AppColors.goldDeep,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelColor: AppColors.textMuted,
              tabs: [
                Tab(
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  text: 'Staff Accounts (${filteredUsers.length})',
                ),
                Tab(
                  icon: const Icon(Icons.account_tree_outlined, size: 18),
                  text: 'Roles & Hierarchy ($totalRoles)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ----------------------------------------------------
          // 3. TAB BAR VIEW CONTENT
          // ----------------------------------------------------
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ==========================================
                // TAB 1: STAFF ACCOUNTS
                // ==========================================
                Column(
                  children: [
                    // Responsive Toolbar
                    ResponsiveFilterBar(
                      searchWidget: SearchInput(
                        controller: _searchCtrl,
                        hint: 'Search staff by name, username, or role...',
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      filterWidget: OutlinedButton.icon(
                        icon: Icon(
                          _showAllPasswords ? Icons.visibility_off : Icons.visibility,
                          size: 16,
                          color: _showAllPasswords ? AppColors.goldDeep : AppColors.textMain,
                        ),
                        label: Text(
                          _showAllPasswords ? 'Hide All Passwords' : 'View All Passwords',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _showAllPasswords ? AppColors.goldDeep : AppColors.textMain,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _showAllPasswords ? AppColors.goldSoft : Colors.white,
                          side: BorderSide(color: _showAllPasswords ? AppColors.gold : AppColors.border),
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: () {
                          setState(() {
                            _showAllPasswords = !_showAllPasswords;
                          });
                        },
                      ),
                      actionWidget: GoldButton(
                        icon: Icons.person_add,
                        label: 'Add Staff Account',
                        height: 46,
                        onPressed: () => _showAddEmployeeSheet(context),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Status Indicator Pill (if filtered)
                    if (_filterStatus != 'all') ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'Filter: Showing ${_filterStatus.toUpperCase()} staff only',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(() => _filterStatus = 'all'),
                              child: const Text('Clear Filter', style: TextStyle(fontSize: 12, color: AppColors.blue, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Staff List
                    Expanded(
                      child: Card(
                        child: filteredUsers.isEmpty
                            ? const Center(
                                child: Text('No staff employees found matching criteria.', style: TextStyle(color: AppColors.textMuted)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredUsers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, idx) {
                                  final u = filteredUsers[idx];
                                  return _buildStaffAccountRow(u, auth, currentUser, isMobile);
                                },
                              ),
                      ),
                    ),
                  ],
                ),

                // ==========================================
                // TAB 2: ROLES & HIERARCHY
                // ==========================================
                Column(
                  children: [
                    if (auth.isSuperAdmin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Organizational Hierarchy & Modules',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            GoldButton(
                              icon: Icons.add,
                              label: 'Create Custom Role',
                              height: 42,
                              onPressed: () => _showAddRoleSheet(context),
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: Card(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: isMobile ? 180 : 160,
                              ),
                              itemCount: auth.roles.length,
                              itemBuilder: (context, idx) {
                                final entry = auth.roles.entries.elementAt(idx);
                                final r = entry.value;
                                final toneColor = _getToneColor(r.tone);
                                final superiorDef = auth.roles[r.superiorRole];

                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: toneColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: toneColor.withOpacity(0.4)),
                                                ),
                                                child: Text(
                                                  'Rank ${r.rank}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 10.5,
                                                    color: toneColor,
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  r.superiorRole.isNotEmpty
                                                      ? 'மேலதிகாரி: ${superiorDef?.label ?? r.superiorRole}'
                                                      : 'Top Authority',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    color: r.superiorRole.isNotEmpty ? AppColors.textMuted : AppColors.goldDeep,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            r.label,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.textMain),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '(${r.key})',
                                            style: AppTheme.mono(fontSize: 10, color: AppColors.textMuted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            r.desc,
                                            style: const TextStyle(fontSize: 11, color: AppColors.text2),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (r.access == '*')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.goldSoft,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.gold),
                                              ),
                                              child: const Text(
                                                'All 15 ERP Modules (*)',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.goldDeep),
                                              ),
                                            )
                                          else if (r.access is List)
                                            Text(
                                              'Modules: ${(r.access as List).take(3).join(", ")}${(r.access as List).length > 3 ? " +${(r.access as List).length - 3}" : ""}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.forestMedium),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (!r.isSystem && auth.isSuperAdmin) ...[
                                            const SizedBox(height: 4),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: InkWell(
                                                onTap: () => _confirmDeleteRole(r, auth),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 2),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.delete_outline, size: 14, color: AppColors.red),
                                                      SizedBox(width: 2),
                                                      Text('Delete', style: TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

