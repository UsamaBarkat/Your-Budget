class BillReminder {
  final String id;
  final String billType;
  final DateTime dueDate;
  final int? amount; // paisa, optional
  bool isPaid;

  BillReminder({
    required this.id,
    required this.billType,
    required this.dueDate,
    this.amount,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'billType': billType,
    'dueDate': dueDate.toIso8601String(),
    'amount': amount,
    'isPaid': isPaid,
  };

  factory BillReminder.fromJson(Map<String, dynamic> json) => BillReminder(
    id: json['id'] as String,
    billType: json['billType'] as String,
    dueDate: DateTime.parse(json['dueDate'] as String),
    amount: json['amount'] != null ? (json['amount'] as num).toInt() : null,
    isPaid: json['isPaid'] as bool? ?? false,
  );
}
