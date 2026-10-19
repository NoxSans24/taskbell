import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/presentation/screens/calendar_screen.dart';

Widget _app() {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CalendarScreen(),
    ),
  );
}

void main() {
  group('Calendar screen', () {
    testWidgets('shows month view by default', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('month-grid')), findsOneWidget);
      expect(find.byKey(const ValueKey('week-view')), findsNothing);
      expect(find.text('Bulan'), findsOneWidget);
      expect(find.text('Minggu'), findsOneWidget);
    });

    testWidgets('switches to week view', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Minggu'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('week-view')), findsOneWidget);
      expect(find.byKey(const ValueKey('month-grid')), findsNothing);
    });
  });
}
