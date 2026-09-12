import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController(text: 'ERP@2026G');
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  Future<void> _handleLogin({String? overrideUser, String? overridePass}) async {
    final user = overrideUser ?? _usernameCtrl.text;
    final pass = overridePass ?? _passwordCtrl.text;

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final res = await auth.login(user, pass);

    if (mounted) {
      setState(() {
        _busy = false;
        if (res['ok'] != true) {
          _error = res['error'] ?? 'Login failed.';
        }
      });
    }
  }

  void _quickLogin(String u, String p) {
    _usernameCtrl.text = u;
    _passwordCtrl.text = p;
    _handleLogin(overrideUser: u, overridePass: p);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 860;

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _buildMobileBrandHeader(),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildLoginForm(isMobile: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // Left: Brand Hero Art Side
          Expanded(
            flex: 11,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.forestGradient,
              ),
              child: Stack(
                children: [
                  // Ambient Gold Radial Glow
                  Positioned(
                    right: -120,
                    bottom: -120,
                    width: 420,
                    height: 420,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withOpacity(0.35),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo & Brand Header
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: const [AppColors.goldButtonShadow],
                              ),
                              child: const Center(
                                child: Text(
                                  'KKK',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KKK Oil Factory',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                Text(
                                  'Tamil Nadu · Billing & ERP System',
                                  style: TextStyle(
                                    color: Color(0xFF8FA298),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Main Headline
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Run your entire ERP business from one professional platform.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 14),
                              Text(
                                'AWR pricing model (Agency, Wholesale, Retail), effective date pricing, role-based navigation, and official billing vouchers.',
                                style: TextStyle(
                                  color: Color(0xFFA9BCB1),
                                  fontSize: 14.5,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stats & Chips
                        Row(
                          children: [
                            _buildArtStat('AWR', '3 Pricing Rates'),
                            const SizedBox(width: 32),
                            _buildArtStat('ERP', 'Voucher Billing'),
                            const SizedBox(width: 32),
                            _buildArtStat('4', 'Primary Roles'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Login Form Side
          Expanded(
            flex: 10,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: _buildLoginForm(isMobile: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBrandHeader() {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [AppColors.goldButtonShadow],
          ),
          child: const Center(
            child: Text(
              'KKK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'KKK Oil Factory',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Tamil Nadu · Billing & ERP System',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.text2,
          ),
        ),
      ],
    );
  }

  Widget _buildArtStat(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFA9BCB1),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Sign in 👋',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your staff credentials or select a role account below.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.text2,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),

        // Error message
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.redSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.red.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 17, color: AppColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Username
        const Text(
          'Username',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _usernameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'e.g. admin',
            prefixIcon: Icon(Icons.person_outline, size: 19, color: AppColors.text3),
          ),
        ),
        const SizedBox(height: 16),

        // Password
        const Text(
          'Password',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 19, color: AppColors.text3),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 19,
                color: AppColors.text3,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Sign In Button (btn-gold)
        Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [AppColors.goldButtonShadow],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _busy ? null : () => _handleLogin(),
              child: Center(
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.forest,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, size: 17, color: AppColors.forest),
                          SizedBox(width: 8),
                          Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Quick Role Test Logins
        Container(
          padding: const EdgeInsets.only(top: 18),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              const Text(
                'QUICK ROLE TEST LOGINS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.text3,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickBtn(
                    label: '👑 Super Admin (GST Login)',
                    u: 'admin',
                    p: 'ERP@2026G',
                    isGold: true,
                  ),
                  _buildQuickBtn(
                    label: '🔒 Super Admin (Non-GST Login)',
                    u: 'admin',
                    p: 'ERP@2026N',
                    isPrimary: true,
                  ),
                  _buildQuickBtn(
                    label: '🛡️ Admin',
                    u: 'admin_staff',
                    p: 'admin123',
                  ),
                  _buildQuickBtn(
                    label: '📊 Manager',
                    u: 'mgr',
                    p: 'mgr123',
                  ),
                  _buildQuickBtn(
                    label: '💳 Cashier ERP Billing (Save & Print)',
                    u: 'cashier',
                    p: 'cashier123',
                    isFullWidth: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickBtn({
    required String label,
    required String u,
    required String p,
    bool isGold = false,
    bool isPrimary = false,
    bool isFullWidth = false,
  }) {
    Color bg = AppColors.surface;
    Color fg = AppColors.text;
    Border? border = Border.all(color: AppColors.borderStrong);
    Gradient? grad;

    if (isGold) {
      grad = AppColors.goldGradient;
      fg = AppColors.forest;
      border = null;
    } else if (isPrimary) {
      bg = AppColors.forest;
      fg = Colors.white;
      border = null;
    }

    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: bg,
        gradient: grad,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _quickLogin(u, p),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
