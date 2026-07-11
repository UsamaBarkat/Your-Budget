class DailyExpense {
  final String id;
  final String category;
  final int amount; // paisa
  final DateTime date;

  const DailyExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory DailyExpense.fromJson(Map<String, dynamic> json) => DailyExpense(
    id: json['id'] as String,
    category: json['category'] as String,
    amount: (json['amount'] as num).toInt(),
    date: DateTime.parse(json['date'] as String),
  );
}
