import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/logic/providers/sync_provider.dart';
import 'package:taskbell_app/presentation/screens/calendar_screen.dart';
import 'package:taskbell_app/presentation/screens/dashboard_screen.dart';
import 'package:taskbell_app/presentation/screens/task_list_screen.dart';
import 'package:taskbell_app/presentation/screens/telegram_settings_screen.dart';
import 'package:taskbell_app/presentation/widgets/app_icon.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    TaskListScreen(),
    CalendarScreen(),
    TelegramSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(syncControllerProvider.notifier).syncNow();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncControllerProvider.notifier).syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(
            top: BorderSide(color: palette.border, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.18),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(palette, 0, AppIcons.home, "Beranda"),
                _buildNavItem(palette, 1, AppIcons.tasks, "Tugas"),
                _buildNavItem(palette, 2, AppIcons.calendarDays, "Agenda"),
                _buildNavItem(palette, 3, AppIcons.send, "Telegram"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    AppPalette palette,
    int index,
    String icon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: InkWell(
          key: ValueKey('nav-$index'),
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            widthFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: isSelected
                  ? BoxDecoration(
                      color: palette.secondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: palette.shadow,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    )
                  : null,
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      icon,
                      color: isSelected ? palette.onAccent : palette.ink,
                      size: isSelected ? 24 : 26,
                    ),
                    if (isSelected)
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: palette.onAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
