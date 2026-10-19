class CategoryModel {
  final int id;
  final String? syncId;
  final String name;

  const CategoryModel({
    required this.id,
    this.syncId,
    required this.name,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int,
      syncId: map['sync_id'] as String?,
      name: map['name'] as String,
    );
  }
}
