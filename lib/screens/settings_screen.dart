import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/company.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _legalCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _stateCodeCtrl;
  late TextEditingController _fssaiCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _bankAccCtrl;
  late TextEditingController _bankIfscCtrl;

  final Map<String, bool> _alerts = {
    'Low stock alert': true,
    'Pending payment reminder': true,
    'Pending dispatch': true,
    'Production delay': true,
    'Supplier due': true,
    'Credit limit exceeded': true,
    'Expiry nearing': true,
    'Daily sales summary': true,
  };

  @override
  void initState() {
    super.initState();
    final comp = context.read<DataProvider>().company;
    _nameCtrl = TextEditingController(text: comp.name);
    _legalCtrl = TextEditingController(text: comp.legal ?? '');
    _addressCtrl = TextEditingController(text: comp.address);
    _gstinCtrl = TextEditingController(text: comp.gstin);
    _stateCtrl = TextEditingController(text: comp.state.isNotEmpty ? comp.state : 'Tamil Nadu');
    _stateCodeCtrl = TextEditingController(text: comp.stateCode.isNotEmpty ? comp.stateCode : '33');
    _fssaiCtrl = TextEditingController(text: comp.fssai ?? '');
    _phoneCtrl = TextEditingController(text: comp.phone);
    _emailCtrl = TextEditingController(text: comp.email);
    _bankNameCtrl = TextEditingController(text: comp.bank?.name ?? '');
    _bankAccCtrl = TextEditingController(text: comp.bank?.acc ?? '');
    _bankIfscCtrl = TextEditingController(text: comp.bank?.ifsc ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _legalCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _stateCtrl.dispose();
    _stateCodeCtrl.dispose();
    _fssaiCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccCtrl.dispose();
    _bankIfscCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCompanyProfile() async {
    final data = context.read<DataProvider>();
    final updated = data.company.copyWith(
      name: _nameCtrl.text.trim(),
      legal: _legalCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      stateCode: _stateCodeCtrl.text.trim(),
      fssai: _fssaiCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      bank: BankDetails(
        name: _bankNameCtrl.text.trim(),
        acc: _bankAccCtrl.text.trim(),
        ifsc: _bankIfscCtrl.text.trim(),
      ),
    );

    await data.saveCompany(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company profile saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showStaffDialog({AppUser? editUser}) {
    final auth = context.read<AuthProvider>();
    final userCtrl = TextEditingController(text: editUser?.username ?? '');
    final nameCtrl = TextEditingController(text: editUser?.name ?? '');
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: editUser?.phone ?? '');
    String role = editUser?.role ?? 'cashier';
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  editUser != null ? 'Edit staff · @${editUser.username}' : 'Add staff login',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (editUser == null) ...[
                      const Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: userCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. cashier1',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Anitha M',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Operational Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                        DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                        DropdownMenuItem(value: 'manager', child: Text('Manager')),
                        DropdownMenuItem(value: 'cashier', child: Text('Cashier / ERP Biller')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => role = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      editUser != null ? 'New Password (leave blank to keep current)' : 'Password (min 4 chars)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: editUser != null ? '••••••' : 'Enter password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Mobile Phone (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(hintText: '+91 98430 00000'),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              GoldButton(
                label: editUser != null ? 'Save Changes' : 'Add Staff',
                icon: Icons.check,
                onPressed: () async {
                  if (editUser != null) {
                    await auth.updateUser(editUser.id, {
                      'name': nameCtrl.text.trim(),
                      'role': role,
                      'phone': phoneCtrl.text.trim(),
                      if (passCtrl.text.trim().isNotEmpty) 'password': passCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  } else {
                    final res = await auth.addUser(
                      username: userCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      role: role,
                      password: passCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                    );
                    if (res['ok'] == true) {
                      if (ctx.mounted) Navigator.pop(ctx);
                    } else {
                      setDlgState(() => errorMsg = res['error'] ?? 'Could not add staff account.');
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header matching Vercel
          const Text('Settings', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 3),
          const Text('Company profile, staff logins, roles and data management.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 18),

          // Row 1: Company Profile + Your Session
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildCompanyProfileCard(isMobile)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildYourSessionCard(user, data)),
              ],
            )
          else ...[
            _buildCompanyProfileCard(isMobile),
            const SizedBox(height: 16),
            _buildYourSessionCard(user, data),
          ],

          const SizedBox(height: 18),

          // Row 2: Staff Logins Table Card
          _buildStaffLoginsCard(auth, user, isMobile),

          const SizedBox(height: 18),

          // Row 3: Notifications + Backend & Data Management
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildNotificationsCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildBackendAndDataCard(data)),
              ],
            )
          else ...[
            _buildNotificationsCard(),
            const SizedBox(height: 16),
            _buildBackendAndDataCard(data),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyProfileCard(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const Text('Printed on every tax invoice', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      icon: Icons.check,
                      label: 'Save profile',
                      onPressed: _saveCompanyProfile,
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Company Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Printed on every tax invoice', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  GoldButton(
                    icon: Icons.check,
                    label: 'Save profile',
                    onPressed: _saveCompanyProfile,
                  ),
                ],
              ),
            const Divider(height: 24),
            if (isMobile) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Business Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: _nameCtrl),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GSTIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: _gstinCtrl),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('State', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: _stateCtrl),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GST State Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _stateCodeCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FSSAI No.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _fssaiCtrl),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Factory Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: _addressCtrl),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: _phoneCtrl),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: _emailCtrl),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bank Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: _bankNameCtrl),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('A/C Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _bankAccCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('IFSC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _bankIfscCtrl),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Business Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _nameCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GSTIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _gstinCtrl),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('State', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _stateCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GST State Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _stateCodeCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FSSAI No.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _fssaiCtrl),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Factory Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: _addressCtrl),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _phoneCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _emailCtrl),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bank Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _bankNameCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('A/C Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _bankAccCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('IFSC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(controller: _bankIfscCtrl),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYourSessionCard(UserSession? user, DataProvider data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Text('Current login', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.green, Color(0xFF0F5E3C)],
                    ),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Center(
                    child: Text(
                      user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Super Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('@${user?.username ?? "admin"}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildKvRow('Role', user?.roleLabel ?? 'Super Administrator', isBadge: true),
            _buildKvRow('Access', user?.access == '*' ? 'All modules' : '${user?.access is List ? (user?.access as List).length : 0} modules'),
            _buildKvRow('Storage', data.isFirestoreConnected ? 'Cloud Firestore (kkk-oil-erp)' : 'This browser / Local Cache'),
            _buildKvRow('Session Mode', user?.isNonGstMode == true ? 'Non-GST Executive Mode' : 'GST Registered Mode'),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffLoginsCard(AuthProvider auth, UserSession? currentUser, bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Staff Logins', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const Text('Who can sign in — and what they can see', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: GoldButton(
                      icon: Icons.add,
                      label: 'Add staff / cashier',
                      onPressed: () => _showStaffDialog(),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Staff Logins', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Who can sign in — and what they can see', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  GoldButton(
                    icon: Icons.add,
                    label: 'Add staff / cashier',
                    onPressed: () => _showStaffDialog(),
                  ),
                ],
              ),
            const Divider(height: 24),
            if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: auth.users.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, idx) {
                  final u = auth.users[idx];
                  final roleDef = auth.roles[u.role];
                  final isYou = u.id == currentUser?.id || u.username.toLowerCase() == currentUser?.username.toLowerCase();
                  final isOwner = u.role == 'super_admin' || u.role == 'super_admin_nongst';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: Center(
                            child: Text(
                              u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldDeep, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('@${u.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (isYou) ...[
                                    const SizedBox(width: 4),
                                    const Text('· you', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(u.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      roleDef?.label ?? u.role,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.goldDeep),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    roleDef?.access == '*' ? 'All modules' : '${roleDef?.access is List ? (roleDef?.access as List).length : 0} mods',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                              tooltip: 'Edit / reset password',
                              onPressed: () => _showStaffDialog(editUser: u),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            if (!isOwner && !isYou)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                tooltip: 'Remove staff',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Remove staff account?'),
                                      content: Text('Are you sure you want to remove @${u.username}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await auth.deleteUser(u.id);
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 700),
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowHeight: 38,
                    headingTextStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                    columns: const [
                      DataColumn(label: Text('USERNAME')),
                      DataColumn(label: Text('NAME')),
                      DataColumn(label: Text('ROLE')),
                      DataColumn(label: Text('ACCESS')),
                      DataColumn(label: Text('')),
                    ],
                    rows: auth.users.map((u) {
                      final roleDef = auth.roles[u.role];
                      final isYou = u.id == currentUser?.id || u.username.toLowerCase() == currentUser?.username.toLowerCase();
                      final isOwner = u.role == 'super_admin' || u.role == 'super_admin_nongst';

                      return DataRow(
                        cells: [
                          DataCell(
                            Text('@${u.username}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Text(u.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                if (isYou) ...[
                                  const SizedBox(width: 6),
                                  const Text('· you', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green)),
                                ],
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.goldSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                roleDef?.label ?? u.role,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldDeep,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              roleDef?.access == '*' ? 'All modules' : '${roleDef?.access is List ? (roleDef?.access as List).length : 0} modules',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                                  tooltip: 'Edit / reset password',
                                  onPressed: () => _showStaffDialog(editUser: u),
                                ),
                                if (!isOwner && !isYou)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                    tooltip: 'Remove staff',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Remove staff account?'),
                                          content: Text('Are you sure you want to remove @${u.username}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await auth.deleteUser(u.id);
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications & Alerts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Text('Automatic triggers and notifications', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Divider(height: 24),
            ..._alerts.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.notifications_outlined, size: 16, color: AppColors.goldDeep),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Checkbox(
                      value: e.value,
                      activeColor: AppColors.forestMedium,
                      onChanged: (val) {
                        setState(() {
                          _alerts[e.key] = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendAndDataCard(DataProvider data) {
    final isConnected = data.isFirestoreConnected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backend & Cloud Database', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Text('Multiplatform real-time sync (Web, Android, iOS)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Divider(height: 24),
            _buildKvRow('Database', 'Firebase Firestore (kkk-oil-erp)'),
            _buildKvRow(
              'Connection',
              isConnected ? 'Connected & Synced' : 'Online Cache / Connecting',
              customValue: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.greenSoft : AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? AppColors.green : AppColors.amber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Connected' : 'Connecting',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? AppColors.green : AppColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync Firestore'),
                  onPressed: () async {
                    await data.syncWithFirestore();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Synced with Firestore!'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildKvRow('Build', 'v2.0 · Flutter Monolith'),
            _buildKvRow('Stack', 'Flutter Multiplatform · Web · iOS · Android'),
          ],
        ),
      ),
    );
  }

  Widget _buildKvRow(String key, String value, {bool isBadge = false, Widget? customValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          if (customValue != null)
            customValue
          else if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.goldDeep),
              ),
            )
          else
            Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

