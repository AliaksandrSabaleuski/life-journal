import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    // Тёплая палитра под референс: бежевый фон + карамельный акцент.
    const seed = Color(0xFFFF7A00); // дефолтный акцент (выполнение/селектор/кнопки/+)
    final scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
      // Фиксируем primary ровно в брендовый оранжевый (без "тонирования" от seed).
      primary: seed,
      onPrimary: Colors.white,
      secondary: const Color(0xFFE91E8C),
    );

    const radius12 = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    const radius16 = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
    );

    return base.copyWith(
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: const Color(0xFFF6EEE5),
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.7),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        iconTheme: IconThemeData(
          color: scheme.onSurface.withValues(alpha: 0.70),
        ),
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface.withValues(alpha: 0.78),
        ),
      ),
      cardTheme: const CardThemeData().copyWith(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.72),
        shape: radius16,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        shape: radius16,
        backgroundColor: scheme.surfaceContainerHigh,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface.withValues(alpha: 0.96),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: radius12,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: radius12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: radius12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: radius12,
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface.withValues(alpha: 0.70),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.75),
            width: 2,
          ),
        ),
        labelStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.55);
          }
          return scheme.surfaceContainerHighest.withValues(alpha: 0.85);
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(radius12),
          textStyle: WidgetStateProperty.all(
            base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: radius12,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        labelStyle: base.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: base.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  static ThemeData get dark {
    const seed = Color(0xFF5B5CE2); // мягкий индиго, хорошо дружит с dark UI
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFFE91E8C), // акцент онбординга
    );

    const radius12 = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    const radius16 = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.6),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        shape: radius16,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        shape: radius16,
        backgroundColor: scheme.surfaceContainerHigh,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface.withValues(alpha: 0.96),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: radius12,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: radius12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: radius12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: radius12,
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.75),
            width: 2,
          ),
        ),
        labelStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.55);
          }
          return scheme.surfaceContainerHighest.withValues(alpha: 0.8);
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(radius12),
          textStyle: WidgetStateProperty.all(
            base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: radius12,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        labelStyle: base.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: base.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
