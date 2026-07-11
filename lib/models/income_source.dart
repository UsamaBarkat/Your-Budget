class IncomeSource {
  final String id;
  final String type;
  final int amount; // paisa

  const IncomeSource({
    required this.id,
    required this.type,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
  };

  factory IncomeSource.fromJson(Map<String, dynamic> json) => IncomeSource(
    id: json['id'] as String,
    type: json['type'] as String,
    amount: (json['amount'] as num).toInt(),
  );
}
