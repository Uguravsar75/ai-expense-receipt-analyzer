class CategoryStatModel {
  final String category;
  final double total;
  final double percentage;

  CategoryStatModel({
    required this.category,
    required this.total,
    required this.percentage,
  });

  factory CategoryStatModel.fromJson(Map<String, dynamic> json) {
    return CategoryStatModel(
      category: json['category'] as String,
      total: (json['sum'] ?? json['total'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}
