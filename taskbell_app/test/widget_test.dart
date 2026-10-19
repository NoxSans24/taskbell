import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/api/api_client.dart';
import 'package:taskbell_app/data/models/auth_session.dart';
import 'package:taskbell_app/data/models/task_model.dart';
import 'package:taskbell_app/data/repositories/auth_repository.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';
import 'package:taskbell_app/main.dart';
import 'package:taskbell_app/presentation/screens/add_edit_task_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.session);

  final AuthSession? session;

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final active = session;
    if (active == null) {
      throw const ApiException('Email atau password salah', statusCode: 401);
    }
    return active;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final active = session;
    if (active == null) {
      throw const ApiException('Registrasi gagal', statusCode: 400);
    }
    return active;
  }

  @override
  Future<void> logout() async {}
}

const _authenticatedSession = AuthSession(
  token: 'test-token',
  userId: 'user-123',
  email: 'siti@kampus.ac.id',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskModel Unit Tests', () {
    test('TaskModel toMap and fromMap serialization should match', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 1,
        syncId: 'test-sync-uuid-1234',
        title: 'Mengerjakan Audit Proyek',
        description: 'Detail tugas verifikasi QA',
        category: 'Kuliah',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now,
      );

      final map = task.toMap();
      expect(map['title'], 'Mengerjakan Audit Proyek');
      expect(map['priority'], TaskPriority.high.index);
      expect(map['status'], TaskStatus.pending.index);
      expect(map['category'], 'Kuliah');

      final reconstructed = TaskModel.fromMap(map);
      expect(reconstructed.id, task.id);
      expect(reconstructed.syncId, task.syncId);
      expect(reconstructed.title, task.title);
      expect(reconstructed.category, task.category);
      expect(reconstructed.priority, task.priority);
      expect(reconstructed.status, task.status);
    });

    test('TaskModel copyWith should update specified fields only', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 10,
        syncId: 'sync-10',
        title: 'Judul Asli',
        category: 'Kerja',
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        createdAt: now,
      );

      final updated = task.copyWith(
        title: 'Judul Baru',
        status: TaskStatus.completed,
      );

      expect(updated.id, 10);
      expect(updated.title, 'Judul Baru');
      expect(updated.status, TaskStatus.completed);
      expect(updated.category, 'Kerja');
      expect(updated.priority, TaskPriority.low);
    });

    test(
        'Completed task condition should not qualify for notification scheduling',
        () {
      final futureDate = DateTime.now().add(const Duration(hours: 5));
      final completedTask = TaskModel(
        id: 99,
        title: 'Tugas Selesai',
        category: 'Pribadi',
        priority: TaskPriority.medium,
        status: TaskStatus.completed,
        dueDate: futureDate,
        createdAt: DateTime.now(),
      );

      final shouldSchedule = completedTask.status != TaskStatus.completed &&
          completedTask.dueDate != null &&
          completedTask.dueDate!.isAfter(DateTime.now());

      expect(shouldSchedule, isFalse,
          reason:
              'Tugas berstatus completed tidak boleh menjadwalkan notifikasi');

      final pendingTask = completedTask.copyWith(status: TaskStatus.pending);
      final shouldSchedulePending =
          pendingTask.status != TaskStatus.completed &&
              pendingTask.dueDate != null &&
              pendingTask.dueDate!.isAfter(DateTime.now());

      expect(shouldSchedulePending, isTrue,
          reason:
              'Tugas berstatus pending dengan tenggat masa depan harus dijadwalkan');
    });
  });

  group('AddEditTaskScreen UI & Delete Tests', () {
    testWidgets(
        'AddEditTaskScreen in create mode does not show delete button in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            themeMode: ThemeMode.light,
            home: AddEditTaskScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tambah Tugas'), findsOneWidget);
      expect(find.text('Simpan Tugas'), findsOneWidget);
      expect(find.byTooltip('Hapus Tugas'), findsNothing);
    });

    testWidgets(
        'AddEditTaskScreen in edit mode shows delete button and triggers confirmation dialog',
        (WidgetTester tester) async {
      final existingTask = TaskModel(
        id: 42,
        syncId: 'sync-42',
        title: 'Tugas Uji Hapus',
        description: 'Deskripsi uji',
        category: 'Kuliah',
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AddEditTaskScreen(task: existingTask),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Tugas'), findsOneWidget);
      expect(find.text('Update Tugas'), findsOneWidget);

      final deleteBtnFinder = find.byTooltip('Hapus Tugas');
      expect(deleteBtnFinder, findsOneWidget);

      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Hapus Tugas?'), findsOneWidget);
      expect(
          find.text(
              'Apakah kamu yakin ingin menghapus tugas "Tugas Uji Hapus"?'),
          findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Tugas'), findsOneWidget);
    });
  });

  group('Authentication Gate', () {
    testWidgets('shows login form when no session is stored',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository(null)),
          ],
          child: const TaskBellApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TaskBell'), findsOneWidget);
      expect(find.text('Buat Akun'), findsNothing);
      expect(find.text('Belum punya akun? Daftar'), findsOneWidget);
    });

    testWidgets('validates empty credentials before submitting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository(null)),
          ],
          child: const TaskBellApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk').last);
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });

    testWidgets('switches to registration mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository(null)),
          ],
          child: const TaskBellApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Belum punya akun? Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Buat Akun'), findsOneWidget);
      expect(find.text('Daftar'), findsWidgets);
    });
  });

  group('TaskBell Main Navigation Tests', () {
    testWidgets('renders dashboard and navigation for authenticated user',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeAuthRepository(_authenticatedSession),
            ),
          ],
          child: const TaskBellApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Halo, Siti!'), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-3')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-3')));
      await tester.pumpAndSettle();

      expect(find.text('Integrasi Telegram'), findsOneWidget);
      expect(find.text('Telegram Bot'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-0')));
      await tester.pumpAndSettle();

      expect(find.text('Halo, Siti!'), findsOneWidget);
      expect(find.text('+ Tambah Tugas Baru'), findsOneWidget);
    });

    testWidgets('switches between light and dark theme from account sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeAuthRepository(_authenticatedSession),
            ),
          ],
          child: const TaskBellApp(),
        ),
      );

      await tester.pumpAndSettle();

      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app().themeMode, ThemeMode.system);
      expect(app().darkTheme, isNotNull);

      await tester.tap(find.byKey(const ValueKey('account-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();

      expect(app().themeMode, ThemeMode.dark);

      await tester.tap(find.text('Terang'));
      await tester.pumpAndSettle();

      expect(app().themeMode, ThemeMode.light);
    });
  });
}
