import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/services/notification_service.dart';
import 'package:taskbell_app/logic/providers/theme_provider.dart';
import 'package:taskbell_app/presentation/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  runApp(
    const ProviderScope(
      child: TaskBellApp(),
    ),
  );
}

class TaskBellApp extends ConsumerWidget {
  const TaskBellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'TaskBell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}
