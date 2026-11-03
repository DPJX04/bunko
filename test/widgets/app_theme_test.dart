import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/widgets/app_theme.dart';
import 'package:light_novel_downloader/widgets/spectrum.dart';

/// The WCAG contrast ratio between two opaque colours, from 1 to 21.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const black = Color(0xFF000000);

  test('dark mode is one black plate: ground, app bar and frame', () {
    final theme = AppTheme.dark;

    expect(theme.scaffoldBackgroundColor, black);
    expect(theme.appBarTheme.backgroundColor, black);
    expect(theme.navigationBarTheme.backgroundColor, black);
    expect(theme.colorScheme.surfaceContainerLowest, black);
  });

  test('dark sheets, filled controls and dialogs rise above black', () {
    final scheme = AppTheme.dark.colorScheme;
    final steps = [
      scheme.surface,
      scheme.surfaceContainerLow,
      scheme.surfaceContainer,
      scheme.surfaceContainerHigh,
      scheme.surfaceContainerHighest,
    ];

    for (var i = 1; i < steps.length; i++) {
      expect(
        steps[i].computeLuminance(),
        greaterThan(steps[i - 1].computeLuminance()),
      );
    }
  });

  test('dark text, outlines and hairlines read on black', () {
    final scheme = AppTheme.dark.colorScheme;
    final grounds = [
      scheme.surface,
      scheme.surfaceContainerLow,
      scheme.surfaceContainerHigh,
    ];

    for (final ground in grounds) {
      expect(contrast(scheme.onSurfaceVariant, ground), greaterThan(4.5));
    }
    expect(contrast(scheme.outline, scheme.surface), greaterThan(3));
    expect(contrast(scheme.outlineVariant, scheme.surface), greaterThan(1.5));
  });

  test('light mode keeps the flat bone plate', () {
    expect(AppTheme.light.scaffoldBackgroundColor, const Color(0xFFECE7DC));
  });

  test('every book line reads on its plate and differs from the next', () {
    final plates = {
      Spectrum.emission: AppTheme.dark.scaffoldBackgroundColor,
      Spectrum.absorption: AppTheme.light.scaffoldBackgroundColor,
    };
    for (final MapEntry(key: spectrum, value: plate) in plates.entries) {
      expect(spectrum.books, hasLength(6));
      for (final line in spectrum.books) {
        expect(contrast(line, plate), greaterThan(3));
        expect(line, isNot(spectrum.sodium));
        expect(line, isNot(spectrum.red));
      }
      expect(spectrum.books.toSet(), hasLength(spectrum.books.length));
      expect(spectrum.book(6), spectrum.book(0));
    }
  });
}
