// Chủ đề sáng/tối và tương phản cao dùng FlexColorScheme, GoogleFonts và DynamicColor.

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color _seedPrimary = Color(0xFF0F766E);
  static const Color _seedSecondary = Color(0xFF1E40AF);

  static ThemeData light({
    ColorScheme? dynamicScheme,
    bool highContrast = false,
  }) {
    if (highContrast) {
      return _applyAccessibleTypography(
        FlexThemeData.light(
          useMaterial3: true,
          colorScheme: const ColorScheme.highContrastLight(
            primary: Color(0xFF003D38),
            primaryContainer: Color(0xFFD6F5F0),
            secondary: Color(0xFF102A7A),
            secondaryContainer: Color(0xFFDCE4FF),
            tertiary: Color(0xFF7C2D12),
            tertiaryContainer: Color(0xFFFFEDD5),
          ),
          surface: Colors.white,
          scaffoldBackground: Colors.white,
          subThemesData: _subThemes,
        ),
        Brightness.light,
      );
    }

    final base = FlexThemeData.light(
      useMaterial3: true,
      colorScheme: dynamicScheme,
      colors: dynamicScheme == null
          ? const FlexSchemeColor(
              primary: _seedPrimary,
              primaryContainer: Color(0xFFCCFBF1),
              secondary: _seedSecondary,
              secondaryContainer: Color(0xFFDBEAFE),
              tertiary: Color(0xFF9A3412),
              tertiaryContainer: Color(0xFFFFEDD5),
            )
          : null,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 4,
      subThemesData: _subThemes,
    );

    return _applyAccessibleTypography(base, Brightness.light);
  }

  static ThemeData dark({
    ColorScheme? dynamicScheme,
    bool highContrast = false,
  }) {
    if (highContrast) {
      return _applyAccessibleTypography(
        FlexThemeData.dark(
          useMaterial3: true,
          colorScheme: const ColorScheme.highContrastDark(
            primary: Color(0xFF99F6E4),
            primaryContainer: Color(0xFF064E3B),
            secondary: Color(0xFFBFDBFE),
            secondaryContainer: Color(0xFF1E3A8A),
            tertiary: Color(0xFFFDE68A),
            tertiaryContainer: Color(0xFF78350F),
          ),
          surface: const Color(0xFF000000),
          scaffoldBackground: const Color(0xFF000000),
          subThemesData: _subThemes,
        ),
        Brightness.dark,
      );
    }

    final base = FlexThemeData.dark(
      useMaterial3: true,
      colorScheme: dynamicScheme,
      colors: dynamicScheme == null
          ? const FlexSchemeColor(
              primary: Color(0xFF5EEAD4),
              primaryContainer: Color(0xFF115E59),
              secondary: Color(0xFF93C5FD),
              secondaryContainer: Color(0xFF1E3A8A),
              tertiary: Color(0xFFFCD34D),
              tertiaryContainer: Color(0xFF78350F),
            )
          : null,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 8,
      subThemesData: _subThemes,
    );

    return _applyAccessibleTypography(base, Brightness.dark);
  }

  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    defaultRadius: 12,
    inputDecoratorRadius: 10,
    cardRadius: 14,
    elevatedButtonRadius: 12,
    filledButtonRadius: 12,
    outlinedButtonRadius: 12,
    chipRadius: 10,
    navigationBarIndicatorOpacity: 0.18,
  );

  static ThemeData _applyAccessibleTypography(
    ThemeData base,
    Brightness brightness,
  ) {
    final textTheme = GoogleFonts.beVietnamProTextTheme(base.textTheme).copyWith(
      headlineSmall: GoogleFonts.beVietnamPro(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.beVietnamPro(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.beVietnamPro(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: base.colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: base.colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: base.colorScheme.onSurface,
      ),
      labelLarge: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    final mutedColor = brightness == Brightness.light
        ? const Color(0xFF52525B) // Tương phản > 7:1 trên trắng
        : const Color(0xFFD4D4D8); // Tương phản > 11:1 trên nền tối

    return base.copyWith(
      textTheme: textTheme.copyWith(
        bodySmall: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mutedColor,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
  }
}
