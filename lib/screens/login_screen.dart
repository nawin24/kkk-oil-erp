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
          // Left: Official KKK Brand Banner Side (Fitted to Resolution)
          Expanded(
            flex: 11,
            child: Container(
              color: const Color(0xFFDE0A14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Subtle Radial Depth Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [
                          Color(0xFFEA1D27),
                          Color(0xFFC00710),
                          Color(0xFFA0050C),
                        ],
                      ),
                    ),
                  ),
                  // Centered Official KKK Brand Logo Banner (Fits Resolution)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Image.asset(
                          'assets/images/kkk_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Bottom System Subtitle & Version Info
                  Positioned(
                    left: 36,
                    right: 36,
                    bottom: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_outlined, size: 14, color: AppColors.gold),
                              SizedBox(width: 6),
                              Text(
                                'KKK Oil Factory · Enterprise ERP & Billing',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Text(
                            'Tamil Nadu · Official Portal',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
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
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFDE0A14),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDE0A14).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Image.asset('assets/images/kkk_logo.png', fit: BoxFit.contain),
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
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickBtn(
                          label: '🔑 Super Admin (GST Login)',
                          u: 'admin',
                          p: 'admin123',
                          isGold: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickBtn(
                          label: '🔒 Super Admin (Non-GST Login)',
                          u: 'admin',
                          p: 'admin123n',
                          isPrimary: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickBtn(
                          label: '👤 Admin',
                          u: 'admin_staff',
                          p: 'admin123',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickBtn(
                          label: '📊 Manager',
                          u: 'mgr',
                          p: 'mgr123',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
    Color bg = Colors.white;
    Color fg = AppColors.text;
    Border? border = Border.all(color: const Color(0xFFE5E7EB));

    if (isGold) {
      bg = const Color(0xFFD97706);
      fg = Colors.black;
      border = null;
    } else if (isPrimary) {
      bg = const Color(0xFF10231B);
      fg = Colors.white;
      border = null;
    }

    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _quickLogin(u, p),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
