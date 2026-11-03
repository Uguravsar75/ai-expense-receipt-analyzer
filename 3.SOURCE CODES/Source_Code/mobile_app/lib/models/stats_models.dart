class SummaryModel {
  final double totalAmount;
  final double averageDaily;
  final String topCategory;

  SummaryModel({
    required this.totalAmount,
    required this.averageDaily,
    required this.topCategory,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      totalAmount: (json['totalAmount'] as num).toDouble(),
      averageDaily: (json['averageDaily'] as num).toDouble(),
      topCategory: json['topCategory'],
    );
  }
}

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
      category: json['category'],
      total: (json['total'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}
