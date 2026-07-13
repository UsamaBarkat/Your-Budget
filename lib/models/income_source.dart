class IncomeSource {
  final String id;
  final String type;
  final int amount; // paisa
  final DateTime? date;

  const IncomeSource({
    required this.id,
    required this.type,
    required this.amount,
    this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    if (date != null) 'date': date!.toIso8601String(),
  };

  factory IncomeSource.fromJson(Map<String, dynamic> json) => IncomeSource(
    id: json['id'] as String,
    type: json['type'] as String,
    amount: (json['amount'] as num).toInt(),
    date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
  );
}
