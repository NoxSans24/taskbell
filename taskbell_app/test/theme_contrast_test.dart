import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';

double _contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectTextContrast(AppPalette palette, String mode) {
  final pairs = <String, List<Color>>{
    'ink / canvas': [palette.ink, palette.canvas],
    'ink / surface': [palette.ink, palette.surface],
    'muted / canvas': [palette.muted, palette.canvas],
    'muted / surface': [palette.muted, palette.surface],
    'onAccent / secondary': [palette.onAccent, palette.secondary],
    'onPrimary / primary': [palette.onPrimary, palette.primary],
    'error / surface': [palette.error, palette.surface],
    'success / surface': [palette.success, palette.surface],
    'ink / secondarySoft': [palette.ink, palette.secondarySoft],
    'ink / errorSoft': [palette.ink, palette.errorSoft],
  };

  pairs.forEach((label, colors) {
    final ratio = _contrastRatio(colors[0], colors[1]);
    expect(
      ratio,
      greaterThanOrEqualTo(4.5),
      reason: '$mode: "$label" hanya $ratio:1 (minimum WCAG AA 4.5:1)',
    );
  });
}

void main() {
  test('palet terang memenuhi kontras WCAG AA untuk teks', () {
    _expectTextContrast(AppPalette.light, 'terang');
  });

  test('palet gelap memenuhi kontras WCAG AA untuk teks', () {
    _expectTextContrast(AppPalette.dark, 'gelap');
  });
}
