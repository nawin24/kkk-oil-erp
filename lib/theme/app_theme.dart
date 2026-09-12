import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand & Executive (Exact Vercel Tokens)
  static const Color gold = Color(0xFFE3A92E);          // var(--gold)
  static const Color goldSoft = Color(0xFFF7E7C4);      // var(--gold-soft)
  static const Color goldDeep = Color(0xFFB7791F);      // var(--gold-deep)
  static const Color goldDark = Color(0xFFB7791F);
  static const Color goldLight = Color(0xFFF7E7C4);

  // Operational Tones (Exact Vercel Tokens)
  static const Color green = Color(0xFF1F8A5B);         // var(--green)
  static const Color greenSoft = Color(0xFFE3F4EC);     // var(--green-soft)
  static const Color success = Color(0xFF1F8A5B);
  static const Color successBg = Color(0xFFE3F4EC);

  static const Color red = Color(0xFFDC2626);           // var(--red)
  static const Color redSoft = Color(0xFFFDEAEA);       // var(--red-soft)
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFDEAEA);

  static const Color blue = Color(0xFF2563EB);          // var(--blue)
  static const Color blueSoft = Color(0xFFE7EFFF);      // var(--blue-soft)
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFE7EFFF);

  static const Color amber = Color(0xFFD97706);         // var(--amber)
  static const Color amberSoft = Color(0xFFFDF0DB);     // var(--amber-soft)
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFDF0DB);

  static const Color purple = Color(0xFF7C3AED);        // var(--purple)
  static const Color purpleSoft = Color(0xFFF0E9FF);    // var(--purple-soft)
  static const Color purpleBg = Color(0xFFF0E9FF);

  static const Color teal = Color(0xFF0D9488);          // var(--teal)
  static const Color tealSoft = Color(0xFFD9F3F0);      // var(--teal-soft)

  // Neutral Surfaces & Borders (Exact Vercel Tokens)
  static const Color background = Color(0xFFF5F6F4);   // var(--bg)
  static const Color bg = Color(0xFFF5F6F4);
  static const Color surface = Color(0xFFFFFFFF);      // var(--surface)
  static const Color surface2 = Color(0xFFFAFBF9);     // var(--surface-2)
  static const Color surfaceAlt = Color(0xFFFAFBF9);
  static const Color surfaceWarm = Color(0xFFF7E7C4);
  static const Color border = Color(0xFFE7E9E5);       // var(--border)
  static const Color cardBorder = Color(0xFFE7E9E5);
  static const Color borderStrong = Color(0xFFD6D9D3); // var(--border-strong)
  static const Color textMain = Color(0xFF1A221E);     // var(--text)
  static const Color text = Color(0xFF1A221E);
  static const Color textPrimary = Color(0xFF1A221E);
  static const Color text2 = Color(0xFF5B665F);        // var(--text-2)
  static const Color textSecondary = Color(0xFF5B665F);
  static const Color text3 = Color(0xFF8B948D);        // var(--text-3)
  static const Color textMuted = Color(0xFF8B948D);

  // Forest aliases for existing component compatibility
  static const Color forest = Color(0xFF10231B);
  static const Color forest2 = Color(0xFF173026);
  static const Color forest3 = Color(0xFF1F3D30);
  static const Color forestDark = Color(0xFF10231B);
  static const Color forestMedium = Color(0xFF173026);
  static const Color forestLight = Color(0xFF1F3D30);
  static const Color forestAccent = Color(0xFF137A4D);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldDeep],
  );

  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forest, forest3, Color(0xFF0C2C1D)],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient activeNavGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x38E3A92E), Color(0x14E3A92E)],
  );

  // Shadows
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0F10231B),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadow = BoxShadow(
    color: Color(0x1210231B),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x2410231B),
    blurRadius: 40,
    offset: Offset(0, 12),
  );

  static const BoxShadow goldButtonShadow = BoxShadow(
    color: Color(0x4DE3A92E),
    blurRadius: 14,
    offset: Offset(0, 4),
  );
}

class AppTheme {
  /// Typography: Monospace for usernames, passwords, SKUs, and invoices
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Typography: KPI Values (18px, FontWeight.w800, letter spacing -0.5)
  static TextStyle kpiValue({Color? color}) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: color ?? AppColors.textMain,
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        primary: AppColors.forest,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.red,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: baseTextTheme.copyWith(
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.text,
          fontSize: 14,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.text2,
          fontSize: 12.5,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64, 44)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.border;
            }
            return AppColors.forest;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.text3;
            }
            return Colors.white;
          }),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withOpacity(0.18);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.forest3;
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(64, 44)),
          foregroundColor: WidgetStateProperty.all(AppColors.text),
          backgroundColor: WidgetStateProperty.all(AppColors.surface),
          side: WidgetStateProperty.all(const BorderSide(color: AppColors.borderStrong)),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.surface2;
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 40)),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 13.5),
        labelStyle: const TextStyle(color: AppColors.text2, fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
