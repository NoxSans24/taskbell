import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';
import 'package:taskbell_app/data/models/category_model.dart';
import 'package:taskbell_app/data/repositories/category_repository.dart';
import 'package:taskbell_app/logic/providers/category_provider.dart';
import 'package:taskbell_app/presentation/screens/category_screen.dart';

class _FakeCategoryStore implements CategoryStore {
  _FakeCategoryStore({
    List<CategoryModel>? categories,
    Map<String, int>? taskCounts,
  })  : categories = [...?categories],
        taskCounts = taskCounts ?? {};

  final List<CategoryModel> categories;
  final Map<String, int> taskCounts;
  int _nextId = 100;

  @override
  Future<List<CategoryModel>> getAllCategories() async => List.of(categories);

  @override
  Future<int> createCategory(String name) async {
    final id = _nextId++;
    categories.add(CategoryModel(id: id, name: name));
    return id;
  }

  @override
  Future<int> updateCategory(int id, String name) async {
    final index = categories.indexWhere((category) => category.id == id);
    if (index < 0) return 0;
    categories[index] = CategoryModel(id: id, name: name);
    return 1;
  }

  @override
  Future<int> deleteCategory(int id) async {
    final before = categories.length;
    categories.removeWhere((category) => category.id == id);
    return before - categories.length;
  }

  @override
  Future<int> countTasksForCategory(String name) async {
    return taskCounts[name] ?? 0;
  }
}

Widget _app(CategoryStore store) {
  return ProviderScope(
    overrides: [categoryRepositoryProvider.overrideWithValue(store)],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CategoryScreen(),
    ),
  );
}

void main() {
  group('Category screen', () {
    testWidgets('lists categories from the store', (tester) async {
      final store = _FakeCategoryStore(
        categories: const [
          CategoryModel(id: 1, name: 'Kuliah'),
          CategoryModel(id: 2, name: 'Pribadi'),
        ],
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      expect(find.text('Kuliah'), findsOneWidget);
      expect(find.text('Pribadi'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
    });

    testWidgets('adds a new category', (tester) async {
      final store = _FakeCategoryStore();

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Tambah kategori'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Riset');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Riset'), findsOneWidget);
      expect(store.categories.single.name, 'Riset');
    });

    testWidgets('blocks deleting a category still used by tasks',
        (tester) async {
      final store = _FakeCategoryStore(
        categories: const [CategoryModel(id: 1, name: 'Kuliah')],
        taskCounts: {'Kuliah': 2},
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Hapus').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('masih dipakai 2 tugas'), findsOneWidget);
      expect(store.categories, hasLength(1));
    });

    testWidgets('deletes an unused category after confirmation',
        (tester) async {
      final store = _FakeCategoryStore(
        categories: const [CategoryModel(id: 1, name: 'Arsip')],
      );

      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Hapus').first);
      await tester.pumpAndSettle();

      expect(find.text('Hapus Kategori?'), findsOneWidget);

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(store.categories, isEmpty);
    });
  });
}
