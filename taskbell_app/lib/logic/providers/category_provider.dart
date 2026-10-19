import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskbell_app/data/models/category_model.dart';
import 'package:taskbell_app/data/repositories/category_repository.dart';
import 'package:taskbell_app/logic/providers/auth_provider.dart';

final categoryRepositoryProvider = Provider<CategoryStore?>((ref) {
  final userId = ref.watch(authUserIdProvider);

  if (userId == null || userId.isEmpty) {
    return null;
  }

  final dbAsync = ref.watch(databaseProvider(userId));

  return dbAsync.maybeWhen(
    data: (db) => CategoryRepository(db),
    orElse: () => null,
  );
});

final categoryListProvider = StateNotifierProvider<CategoryListNotifier,
    AsyncValue<List<CategoryModel>>>((ref) {
  return CategoryListNotifier(ref.watch(categoryRepositoryProvider));
});

class CategoryListNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryStore? _repository;

  CategoryListNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    final repository = _repository;

    if (repository == null) {
      state = const AsyncValue.data([]);
      return;
    }

    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      state = AsyncValue.data(await repository.getAllCategories());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> add(String name) async {
    final repository = _repository;
    if (repository == null) return;

    await repository.createCategory(name);
    await refresh();
  }

  Future<void> rename(int id, String name) async {
    final repository = _repository;
    if (repository == null) return;

    await repository.updateCategory(id, name);
    await refresh();
  }

  Future<void> remove(int id) async {
    final repository = _repository;
    if (repository == null) return;

    await repository.deleteCategory(id);
    await refresh();
  }

  Future<int> taskCount(String name) async {
    return await _repository?.countTasksForCategory(name) ?? 0;
  }
}
