import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oly/widgets/motion/oly_page_route.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF090A0D); // Deep Obsidian
  static const Color canvasObsidian = Color(0xFF090A0D);
  static const Color surfaceCard = Color(0xFF14161E); // Dark Carbon
  static const Color surfaceElevated = Color(0xFF1C1F2B);
  static const Color surfaceGlass = Color(0xDD151722);
  static const Color borderColor = Color(0xFF282C3A);
  static const Color borderSubtle = Color(0x1AFFFFFF);
  static const Color borderMedium = Color(0x33FFFFFF);
  static const Color borderActiveAmber = Color(0x66FF9F0A);
  static const Color borderActiveCyan = Color(0x6600D2FF);

  static const Color primaryAmber = Color(0xFFFF9F0A); // Neon Amber
  static const Color secondaryCyan = Color(0xFF00D2FF); // Neon Cyan
  static const Color accentBlue = Color(0xFF00D2FF); // Neon Cyan / Accent Blue
  static const Color successGreen = Color(0xFF30D158); // Neon Green
  static const Color warningOrange = Color(0xFFFF5E00);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentCrimson = Color(0xFFFF3B30);

  // IWF Bumper Plate Color Codes
  static const Color plateRed = Color(0xFFE02424);
  static const Color plateBlue = Color(0xFF1C64F2);
  static const Color plateYellow = Color(0xFFE3A008);
  static const Color plateGreen = Color(0xFF057A55);
  static const Color plateWhite = Color(0xFF9CA3AF);

  static const Color textPrimary = Color(0xFFF2F4F8);
  static const Color textSecondary = Color(0xFF8E95A5);

  // Standard Gradients
  static const LinearGradient metallicObsidianGradient = LinearGradient(
    colors: <Color>[Color(0xFF1E222E), Color(0xFF111319)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroAmberGradient = LinearGradient(
    colors: <Color>[Color(0xFFFFB340), Color(0xFFFF8000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cryoCyanGradient = LinearGradient(
    colors: <Color>[Color(0xFF38E1FF), Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient retestCrimsonGradient = LinearGradient(
    colors: <Color>[Color(0xFFFF453A), Color(0xFF9E0B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldFuelGradient = LinearGradient(
    colors: <Color>[Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Atmospheric Ambient Backlight Gradients
  static const RadialGradient ambientAmberRadial = RadialGradient(
    center: Alignment(-0.2, -0.6),
    radius: 1.2,
    colors: <Color>[
      Color(0x33FF9F0A),
      Color(0x0A090A0D),
    ],
    stops: <double>[0, 1],
  );

  static const RadialGradient ambientCyanRadial = RadialGradient(
    center: Alignment(0.2, -0.6),
    radius: 1.2,
    colors: <Color>[
      Color(0x2E00D2FF),
      Color(0x0A090A0D),
    ],
    stops: <double>[0, 1],
  );

  static const RadialGradient ambientEmeraldRadial = RadialGradient(
    center: Alignment(0, -0.5),
    radius: 1.2,
    colors: <Color>[
      Color(0x2910B981),
      Color(0x0A090A0D),
    ],
    stops: <double>[0, 1],
  );

  // Precision Metallic Barbell Gradients
  static const LinearGradient barbellSteelGradient = LinearGradient(
    colors: <Color>[
      Color(0xFF6B7280),
      Color(0xFFE5E7EB),
      Color(0xFF9CA3AF),
      Color(0xFF4B5563),
    ],
    stops: <double>[0, 0.35, 0.7, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient collarChromeGradient = LinearGradient(
    colors: <Color>[
      Color(0xFF475569),
      Color(0xFFCBD5E1),
      Color(0xFF94A3B8),
      Color(0xFF334155),
    ],
    stops: <double>[0, 0.3, 0.7, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Specular Highlight Border (uniform for rounded containers)
  static Border get specularBorderTop => Border.all(
        color: Colors.white.withValues(alpha: 0.12),
      );

  // Standard BoxShadows
  static List<BoxShadow> glowAmber({double radius = 16.0, double opacity = 0.25}) =>
      <BoxShadow>[
        BoxShadow(
          color: primaryAmber.withValues(alpha: opacity),
          blurRadius: radius,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> glowCyan({double radius = 16.0, double opacity = 0.25}) =>
      <BoxShadow>[
        BoxShadow(
          color: secondaryCyan.withValues(alpha: opacity),
          blurRadius: radius,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> cardShadow({double opacity = 0.4}) => <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryAmber,
        secondary: secondaryCyan,
        surface: surfaceCard,
        error: accentCrimson,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderColor),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryAmber,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelColor: primaryAmber,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryAmber,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primaryAmber,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: OlyPageTransitionsBuilder(),
          TargetPlatform.android: OlyPageTransitionsBuilder(),
          TargetPlatform.macOS: OlyPageTransitionsBuilder(),
        },
      ),
    );
  }
}
