class ExpenseCreateRequest {
  final double amount;
  final String category;
  final String description;

  ExpenseCreateRequest({
    required this.amount,
    required this.category,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "category": category,
        "description": description,
      };
}
