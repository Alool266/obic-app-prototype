// Made by Dr Ali
// Material theme — layered depth, OBIC navy/blue, professional (no purple AI look).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'obic_colors.dart';
import 'obic_elevation.dart';

/// Bundled families — Arabic primary + SC/Roboto fallbacks (never Ahem tofu).
const String kObicFontArabic = 'NotoSansArabic';
const String kObicFontLatin = 'Roboto';
const List<String> kObicFontFallbacks = [
  kObicFontArabic,
  'NotoSansSC',
  kObicFontLatin,
];

/// Locale-aware fallbacks — avoid loading ~5MB NotoSansSC into RAM for AR/EN.
List<String> obicFontFallbacksFor(String? langCode) {
  switch (langCode) {
    case 'zh':
      return const ['NotoSansSC', kObicFontLatin, kObicFontArabic];
    case 'en':
      return const [kObicFontLatin, kObicFontArabic];
    case 'ar':
    default:
      return const [kObicFontArabic, kObicFontLatin];
  }
}

String obicPrimaryFontFor(String? langCode) {
  switch (langCode) {
    case 'zh':
      return 'NotoSansSC';
    case 'en':
      return kObicFontLatin;
    case 'ar':
    default:
      return kObicFontArabic;
  }
}

ThemeData buildObicTheme({String? fontFamily, String? langCode}) {
  final base = ColorScheme.fromSeed(
    seedColor: ObicColors.blue,
    primary: ObicColors.blue,
    secondary: ObicColors.navy,
    surface: ObicColors.card,
    brightness: Brightness.light,
  );

  // Prefer bundled Noto for AR/CJK glyphs; Roboto covers Latin digits/currency.
  final family = fontFamily ?? obicPrimaryFontFor(langCode);
  final fallbacks = obicFontFallbacksFor(langCode);
  const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontWeight: FontWeight.w800,
      color: ObicColors.navy,
      letterSpacing: -0.6,
      height: 1.1,
      fontSize: 32,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.w700,
      color: ObicColors.navy,
      letterSpacing: -0.35,
      fontSize: 22,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w700,
      color: ObicColors.navy,
      letterSpacing: -0.25,
      fontSize: 18,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w700,
      color: ObicColors.navy,
      letterSpacing: -0.2,
      fontSize: 16,
    ),
    bodyLarge: TextStyle(color: ObicColors.ink, height: 1.4, fontSize: 15),
    bodyMedium: TextStyle(color: ObicColors.muted, height: 1.45, fontSize: 14),
    bodySmall: TextStyle(
      color: ObicColors.muted,
      height: 1.4,
      fontSize: 12.5,
    ),
    labelLarge: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
      fontSize: 15,
    ),
  );

  TextStyle withFallback(TextStyle style) => style.copyWith(
        fontFamily: family,
        fontFamilyFallback: fallbacks,
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: family,
    colorScheme: base.copyWith(
      surfaceContainerHighest: ObicColors.blueSoft,
      outline: ObicColors.line,
    ),
    scaffoldBackgroundColor: ObicColors.background,
    textTheme: TextTheme(
      displaySmall: withFallback(textTheme.displaySmall!),
      headlineMedium: withFallback(textTheme.headlineMedium!),
      titleLarge: withFallback(textTheme.titleLarge!),
      titleMedium: withFallback(textTheme.titleMedium!),
      bodyLarge: withFallback(textTheme.bodyLarge!),
      bodyMedium: withFallback(textTheme.bodyMedium!),
      bodySmall: withFallback(textTheme.bodySmall!),
      labelLarge: withFallback(textTheme.labelLarge!),
    ),
    // Light chrome: ink on white — never white/washed icons on light surfaces.
    appBarTheme: AppBarTheme(
      backgroundColor: ObicColors.card,
      foregroundColor: ObicColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      // M3 tint + zoom-snapshot remounts flash leading/actions.
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: true,
      iconTheme: const IconThemeData(color: ObicColors.ink, size: 24),
      actionsIconTheme: const IconThemeData(color: ObicColors.ink, size: 24),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: const TextStyle(
        color: ObicColors.navy,
        fontWeight: FontWeight.w700,
        fontSize: 17,
        letterSpacing: 0.2,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(0),
        ),
      ),
    ),
    // Kill lingering Ink/overlay flash on AppBar BackButton + action icons
    // (and elsewhere) when routes rebuild or setState during polls.
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(ObicColors.ink),
        iconColor: const WidgetStatePropertyAll(ObicColors.ink),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: ObicColors.navy,
      unselectedLabelColor: ObicColors.muted,
      indicatorColor: ObicColors.blueDeep,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    cardTheme: CardThemeData(
      color: ObicColors.card,
      elevation: 0,
      shadowColor: ObicColors.navy.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObicElevation.radiusMd),
        side: ObicElevation.hairlineSoft,
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ObicColors.card,
      elevation: 0,
      height: 68,
      indicatorColor: ObicColors.blueSoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.1,
          color: selected ? ObicColors.blue : ObicColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? ObicColors.blue : ObicColors.muted,
          size: selected ? 24 : 22,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: ObicColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ObicElevation.radiusXl),
        ),
      ),
      dragHandleColor: ObicColors.line,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ObicColors.navy,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: ObicColors.line.withValues(alpha: 0.85),
      thickness: 0.5,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ObicColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        elevation: 2,
        shadowColor: ObicColors.blue.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ObicColors.navy,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: ObicColors.line.withValues(alpha: 0.95)),
        backgroundColor: ObicColors.card.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    // blueDeep reads clearly on light AppBars (Save / Back text); avoid washed blue.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ObicColors.blueDeep,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ObicColors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ObicColors.cardRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ObicColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ObicColors.line.withValues(alpha: 0.9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ObicColors.blue, width: 1.6),
      ),
      labelStyle: const TextStyle(color: ObicColors.muted),
      hintStyle: TextStyle(color: ObicColors.muted.withValues(alpha: 0.75)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: ObicColors.blue,
      textColor: ObicColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    // Zoom + route snapshotting remounts AppBar icons as a visible flash on
    // push/pop (back + actions). Prefer slide/fade builders instead.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Dark appearance — WeChat-like charcoal surfaces + OBIC blue (no purple seed).
ThemeData buildObicDarkTheme({String? fontFamily, String? langCode}) {
  const darkInk = ObicColors.darkInk;
  const darkMuted = ObicColors.darkMuted;
  const darkCard = ObicColors.darkSurface;
  const darkCardRaised = ObicColors.darkSurfaceRaised;
  const darkBackground = ObicColors.darkCanvas;
  const darkLine = ObicColors.darkLine;

  final base = ColorScheme.fromSeed(
    seedColor: ObicColors.blue,
    primary: ObicColors.blue,
    secondary: ObicColors.blueDeep,
    surface: darkCard,
    brightness: Brightness.dark,
  );

  final family = fontFamily ?? obicPrimaryFontFor(langCode);
  final fallbacks = obicFontFallbacksFor(langCode);

  TextStyle withFallback(TextStyle style) => style.copyWith(
        fontFamily: family,
        fontFamilyFallback: fallbacks,
        color: style.color ?? darkInk,
      );

  const headlineStyle = TextStyle(
    fontWeight: FontWeight.w700,
    color: darkInk,
    letterSpacing: -0.25,
    fontSize: 18,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: family,
    colorScheme: base.copyWith(
      surfaceContainerHighest: ObicColors.darkBlueSoft,
      outline: darkLine,
      onSurface: darkInk,
      onSurfaceVariant: ObicColors.darkMuted,
    ),
    scaffoldBackgroundColor: darkBackground,
    canvasColor: darkBackground,
    dividerColor: darkLine,
    textTheme: TextTheme(
      displaySmall: withFallback(
        headlineStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w800),
      ),
      headlineMedium: withFallback(headlineStyle.copyWith(fontSize: 22)),
      titleLarge: withFallback(headlineStyle),
      titleMedium: withFallback(headlineStyle.copyWith(fontSize: 16)),
      bodyLarge: withFallback(
        const TextStyle(color: darkInk, height: 1.4, fontSize: 15),
      ),
      bodyMedium: withFallback(
        const TextStyle(color: darkMuted, height: 1.45, fontSize: 14),
      ),
      bodySmall: withFallback(
        const TextStyle(color: darkMuted, height: 1.4, fontSize: 12.5),
      ),
      labelLarge: withFallback(
        const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
          fontSize: 15,
          color: darkInk,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkCard,
      foregroundColor: darkInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: true,
      iconTheme: const IconThemeData(color: darkInk, size: 24),
      actionsIconTheme: const IconThemeData(color: darkInk, size: 24),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: const TextStyle(
        color: darkInk,
        fontWeight: FontWeight.w700,
        fontSize: 17,
        letterSpacing: 0.2,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(darkInk),
        iconColor: const WidgetStatePropertyAll(darkInk),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: darkInk,
      unselectedLabelColor: ObicColors.darkNavIdle,
      indicatorColor: ObicColors.blue,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObicElevation.radiusMd),
        side: const BorderSide(color: darkLine),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkCard,
      elevation: 0,
      height: 68,
      indicatorColor: ObicColors.darkBlueSoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? ObicColors.blue : ObicColors.darkNavIdle,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? ObicColors.blue : ObicColors.darkNavIdle,
          size: selected ? 24 : 22,
        );
      }),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ObicElevation.radiusXl),
        ),
      ),
      dragHandleColor: darkLine,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardRaised,
      contentTextStyle: const TextStyle(color: darkInk, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: darkLine,
      thickness: 0.5,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ObicColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkInk,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: darkLine),
        backgroundColor: darkCardRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ObicColors.blue,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ObicColors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ObicColors.blue, width: 1.6),
      ),
      labelStyle: const TextStyle(color: darkMuted),
      hintStyle: TextStyle(color: darkMuted.withValues(alpha: 0.75)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: ObicColors.blue,
      textColor: darkInk,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
