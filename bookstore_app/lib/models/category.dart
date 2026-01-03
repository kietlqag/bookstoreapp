class Category {
  const Category({
    required this.id,
    required this.name,
    this.slug,
    this.description,
  });

  final int id;
  final String name;
  final String? slug;
  final String? description;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
