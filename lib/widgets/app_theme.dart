import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'emission_tick_border.dart';
import 'spectrum.dart';

/// The Emission-Line Rail world as Material 3 themes.
///
/// Dark is the black plate with glowing lines; light is the bone
/// absorption plate with darkened lines. Every screen reads colours, type
/// and shapes from here, so no widget picks its own hex value or font size.
abstract final class AppTheme {
  /// The black plate, used when the phone is in dark mode.
  static ThemeData get dark => _build(_darkScheme, Spectrum.emission);

  /// The bone plate, used when the phone is in light mode.
  static ThemeData get light => _build(_lightScheme, Spectrum.absorption);

  /// The black plate for the Chinese words, set closer than the English
  /// tracked capitals, which would spread Chinese characters apart.
  static ThemeData get darkChinese {
    return _build(_darkScheme, Spectrum.emission, chinese: true);
  }

  /// The bone plate for the Chinese words; see [darkChinese].
  static ThemeData get lightChinese {
    return _build(_lightScheme, Spectrum.absorption, chinese: true);
  }

  /// The opposite plate, for the few surfaces drawn inverted, such as a
  /// snackbar: bone inside the black app, charcoal inside the bone one.
  static ThemeData inverseOf(BuildContext context) {
    final chinese = Localizations.maybeLocaleOf(context)?.languageCode == 'zh';
    return Theme.of(context).brightness == Brightness.dark
        ? (chinese ? lightChinese : light)
        : (chinese ? darkChinese : dark);
  }
}

/// Corner radius for every control and sheet: almost square, like a plate.
const _corner = Radius.circular(2);

/// The black plate. The ground and the frame around the site (app bar,
/// Browse strip, navigation bar) are one pure black, split only by
/// hairlines; sheets, filled controls and dialogs rise above it as
/// charcoal steps, lowest to highest.
const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE8E2D6),
  onPrimary: Color(0xFF1E1F22),
  primaryContainer: Color(0xFF3A3934),
  onPrimaryContainer: Color(0xFFE8E2D6),
  secondary: Color(0xFFA9A49A),
  onSecondary: Color(0xFF1E1F22),
  secondaryContainer: Color(0xFF2E2F33),
  onSecondaryContainer: Color(0xFFE8E2D6),
  tertiary: Color(0xFFF5C542),
  onTertiary: Color(0xFF1E1F22),
  tertiaryContainer: Color(0xFF3D331A),
  onTertiaryContainer: Color(0xFFF5C542),
  error: Color(0xFFFF6B5A),
  onError: Color(0xFF1E1F22),
  errorContainer: Color(0xFF3B201C),
  onErrorContainer: Color(0xFFFFB4A8),
  surface: Color(0xFF000000),
  onSurface: Color(0xFFE8E2D6),
  surfaceContainerLowest: Color(0xFF000000),
  surfaceContainerLow: Color(0xFF1B1C1F),
  surfaceContainer: Color(0xFF222326),
  surfaceContainerHigh: Color(0xFF28292D),
  surfaceContainerHighest: Color(0xFF2F3034),
  onSurfaceVariant: Color(0xFFA9A49A),
  outline: Color(0xFF6B6860),
  outlineVariant: Color(0xFF3A3B3E),
  inverseSurface: Color(0xFFE8E2D6),
  onInverseSurface: Color(0xFF1E1F22),
  inversePrimary: Color(0xFF3A3934),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0x00000000),
);

/// The bone plate: a flat bone ground, the frame one step lighter, and
/// darker bone steps for sheets, filled controls and dialogs.
const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1E1F22),
  onPrimary: Color(0xFFECE7DC),
  primaryContainer: Color(0xFFDCD5C7),
  onPrimaryContainer: Color(0xFF1E1F22),
  secondary: Color(0xFF55524B),
  onSecondary: Color(0xFFECE7DC),
  secondaryContainer: Color(0xFFE0D9CB),
  onSecondaryContainer: Color(0xFF1E1F22),
  tertiary: Color(0xFF8C6A00),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFF3E2B0),
  onTertiaryContainer: Color(0xFF3D2E00),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF5D9D4),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFECE7DC),
  onSurface: Color(0xFF1E1F22),
  surfaceContainerLowest: Color(0xFFF3EFE6),
  surfaceContainerLow: Color(0xFFE8E2D6),
  surfaceContainer: Color(0xFFE3DDD0),
  surfaceContainerHigh: Color(0xFFDDD6C8),
  surfaceContainerHighest: Color(0xFFD6CFC0),
  onSurfaceVariant: Color(0xFF55524B),
  outline: Color(0xFF8A857B),
  outlineVariant: Color(0xFFC9C2B4),
  inverseSurface: Color(0xFF1E1F22),
  onInverseSurface: Color(0xFFE8E2D6),
  inversePrimary: Color(0xFFE8E2D6),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0x00000000),
);

/// Builds one theme from a colour scheme and its emission lines, with
/// Chinese letter spacing when [chinese].
ThemeData _build(
  ColorScheme scheme,
  Spectrum spectrum, {
  bool chinese = false,
}) {
  final text = _textTheme(
    chinese: chinese,
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Archivo',
    textTheme: text,
    extensions: [spectrum],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
    appBarTheme: _appBarTheme(scheme, text),
    navigationBarTheme: _navigationBarTheme(scheme, text),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      highlightElevation: 4,
      extendedTextStyle: text.labelLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _controlStyle(
        scheme,
        text,
        tick: spectrum.cyan,
        plate: scheme.surfaceContainerHigh,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _controlStyle(scheme, text, tick: scheme.onSurfaceVariant),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _controlStyle(scheme, text, tick: scheme.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      modalBackgroundColor: scheme.surfaceContainerLow,
      dragHandleColor: scheme.outline,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: _corner),
      ),
    ),
    // A raised plate one tonal step up with a hairline edge, flat and
    // almost square; the scrim dims what is behind it.
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(_corner),
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: spectrum.sodium,
      linearTrackColor: scheme.outlineVariant,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 0),
    // An inverted plate that floats flat: no shadow, almost square.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(_corner),
      ),
    ),
  );
}

/// The app bar: flat plate, a hairline below, tracked capitals for titles.
AppBarTheme _appBarTheme(ColorScheme scheme, TextTheme text) {
  final isDark = scheme.brightness == Brightness.dark;
  return AppBarTheme(
    backgroundColor: scheme.surface,
    foregroundColor: scheme.onSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: text.titleLarge,
    shape: Border(bottom: BorderSide(color: scheme.outlineVariant, width: 0)),
    systemOverlayStyle: isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
  );
}

/// The navigation bar: no pill. The open tab is marked by the emission tick
/// drawn above the bar, its icon and its brighter label.
NavigationBarThemeData _navigationBarTheme(ColorScheme scheme, TextTheme text) {
  return NavigationBarThemeData(
    backgroundColor: scheme.surfaceContainerLowest,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    height: 68,
    indicatorColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return text.labelSmall?.copyWith(
        color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(
        size: 22,
        color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
      );
    }),
  );
}

/// Every button is the world's control: a hairline plate with an emission
/// tick on its leading edge, dashed while pressed. [plate] fills primary
/// buttons; secondary ones stay transparent on the ground.
ButtonStyle _controlStyle(
  ColorScheme scheme,
  TextTheme text, {
  required Color tick,
  Color plate = Colors.transparent,
}) {
  return ButtonStyle(
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    backgroundColor: WidgetStatePropertyAll(plate),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      final disabled = states.contains(WidgetState.disabled);
      return disabled
          ? scheme.onSurface.withValues(alpha: 0.38)
          : scheme.onSurface;
    }),
    shape: tickShape(tick: tick, outline: scheme.outline),
    // Buttons copy this side onto the shape, so it must be the hairline too.
    side: WidgetStatePropertyAll(BorderSide(color: scheme.outline, width: 1)),
    padding: const WidgetStatePropertyAll(
      EdgeInsetsDirectional.fromSTEB(26, 14, 20, 14),
    ),
  );
}

/// One grotesque at a narrow range of sizes, ranked by width, tracking and
/// weight rather than by big size jumps. Labels are condensed and tracked;
/// for the Chinese words, [chinese], the wide tracking closes up.
TextTheme _textTheme({bool chinese = false}) {
  double track(double latin) => chinese && latin > 0.5 ? 0.5 : latin;
  return TextTheme(
    displaySmall: _archivo(36, width: 75, weight: 400, tracking: 0.5),
    headlineSmall: _archivo(24, width: 75, weight: 500, tracking: track(1)),
    titleLarge: _archivo(20, width: 75, weight: 500, tracking: track(2.4)),
    titleMedium: _archivo(16, weight: 500, tracking: 0.2),
    titleSmall: _archivo(14, weight: 600, tracking: 0.2),
    bodyLarge: _archivo(16, height: 1.5),
    bodyMedium: _archivo(14, height: 1.45),
    bodySmall: _archivo(12, tracking: 0.2, height: 1.4),
    labelLarge: _archivo(14, width: 80, weight: 600, tracking: track(1.6)),
    labelMedium: _archivo(12, width: 80, weight: 600, tracking: track(1.6)),
    labelSmall: _archivo(11, width: 80, weight: 600, tracking: track(1.8)),
  );
}

/// An Archivo style; [width] is the font's width axis, 62 to 125 percent.
TextStyle _archivo(
  double size, {
  double width = 100,
  double weight = 400,
  double tracking = 0.1,
  double height = 1.3,
}) {
  return TextStyle(
    fontFamily: 'Archivo',
    fontSize: size,
    fontWeight: FontWeight.values[(weight / 100).round() - 1],
    fontVariations: [FontVariation.width(width), FontVariation.weight(weight)],
    letterSpacing: tracking,
    height: height,
  );
}
