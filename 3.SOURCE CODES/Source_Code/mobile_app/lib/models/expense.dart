class Expense {
  final int id;
  final double amount;
  final String? category;
  final String? description;
  final String? predictedCategory;
  final bool? aiAccepted;
  final String? createdAt;

  Expense({
    required this.id,
    required this.amount,
    this.category,
    this.description,
    this.predictedCategory,
    this.aiAccepted,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      predictedCategory: json['predictedCategory']?.toString(),
      aiAccepted: json['aiAccepted'] as bool?,
      createdAt: json['createdAt']?.toString(),
    );
  }
}
