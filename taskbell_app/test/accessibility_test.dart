import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/presentation/screens/add_edit_task_screen.dart';
import 'package:taskbell_app/presentation/screens/calendar_screen.dart';
import 'package:taskbell_app/presentation/screens/dashboard_screen.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('Accessibility: text scaling', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('layar utama tidak overflow pada skala teks $scale',
          (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(
          tester.platformDispatcher.clearTextScaleFactorTestValue,
        );

        final screens = <Widget>[
          const AddEditTaskScreen(),
          const DashboardScreen(),
          const CalendarScreen(),
        ];

        for (final screen in screens) {
          await tester.pumpWidget(_wrap(screen));
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} overflow pada skala teks $scale',
          );
        }
      });
    }
  });
}
