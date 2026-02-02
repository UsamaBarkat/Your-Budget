import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Translations
Map<String, Map<String, String>> incomeTranslations = {
  'en': {
    'title': 'Income & Balance',
    'monthly_income': 'Monthly Income',
    'total_expenses': 'Total Expenses',
    'balance': 'Balance',
    'set_income': 'Set Income',
    'enter_amount': 'Enter amount',
    'save': 'Save',
    'cancel': 'Cancel',
    'rupees': 'Rs.',
    'income_sources': 'Income Sources',
    'salary': 'Salary',
    'business': 'Business',
    'rent_income': 'Rent Income',
    'other': 'Other',
    'add_income': 'Add Income',
    'this_month': 'This Month',
    'saving': 'You are saving!',
    'overspending': 'You are overspending!',
    'delete': 'Delete',
  },
  'ur': {
    'title': 'آمدنی اور بیلنس',
    'monthly_income': 'ماہانہ آمدنی',
    'total_expenses': 'کل اخراجات',
    'balance': 'بیلنس',
    'set_income': 'آمدنی مقرر کریں',
    'enter_amount': 'رقم درج کریں',
    'save': 'محفوظ کریں',
    'cancel': 'منسوخ',
    'rupees': 'روپے',
    'income_sources': 'آمدنی کے ذرائع',
    'salary': 'تنخواہ',
    'business': 'کاروبار',
    'rent_income': 'کرایہ کی آمدنی',
    'other': 'دیگر',
    'add_income': 'آمدنی شامل کریں',
    'this_month': 'اس مہینے',
    'saving': 'آپ بچت کر رہے ہیں!',
    'overspending': 'آپ زیادہ خرچ کر رہے ہیں!',
    'delete': 'حذف کریں',
  },
  'sd': {
    'title': 'آمدني ۽ بيلنس',
    'monthly_income': 'مهيني جي آمدني',
    'total_expenses': 'ڪل خرچا',
    'balance': 'بيلنس',
    'set_income': 'آمدني مقرر ڪريو',
    'enter_amount': 'رقم لکو',
    'save': 'محفوظ ڪريو',
    'cancel': 'رد ڪريو',
    'rupees': 'رپيا',
    'income_sources': 'آمدني جا ذريعا',
    'salary': 'تنخواه',
    'business': 'ڪاروبار',
    'rent_income': 'ڪرائي جي آمدني',
    'other': 'ٻيو',
    'add_income': 'آمدني شامل ڪريو',
    'this_month': 'هن مهيني',
    'saving': 'توهان بچت ڪري رهيا آهيو!',
    'overspending': 'توهان وڌيڪ خرچ ڪري رهيا آهيو!',
    'delete': 'ختم ڪريو',
  },
};

String getIncomeText(String key, String lang) {
  return incomeTranslations[lang]?[key] ?? incomeTranslations['en']![key]!;
}

class IncomeSource {
  final String id;
  final String type;
  final double amount;

  IncomeSource({required this.id, required this.type, required this.amount});

  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'amount': amount};

  factory IncomeSource.fromJson(Map<String, dynamic> json) => IncomeSource(
    id: json['id'],
    type: json['type'],
    amount: (json['amount'] as num).toDouble(),
  );
}

class IncomeScreen extends StatefulWidget {
  final String language;

  const IncomeScreen({super.key, required this.language});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  List<IncomeSource> _incomeSources = [];
  double _monthlyExpenses = 0;

  final List<Map<String, dynamic>> incomeTypes = [
    {'key': 'salary', 'icon': Icons.work, 'color': Colors.blue},
    {'key': 'business', 'icon': Icons.store, 'color': Colors.green},
    {'key': 'rent_income', 'icon': Icons.home, 'color': Colors.orange},
    {'key': 'other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load income sources
    final String? incomeJson = prefs.getString('income_sources');
    if (incomeJson != null) {
      final List<dynamic> decoded = json.decode(incomeJson);
      setState(() {
        _incomeSources = decoded.map((e) => IncomeSource.fromJson(e)).toList();
      });
    }

    // Load monthly expenses
    final String? expensesJson = prefs.getString('expenses');
    if (expensesJson != null) {
      final decoded = json.decode(expensesJson) as Map<String, dynamic>;
      double total = 0;
      decoded.forEach((key, value) {
        total += (value as num).toDouble();
      });
      setState(() {
        _monthlyExpenses = total;
      });
    }

    // Also add daily expenses for this month
    final String? dailyJson = prefs.getString('daily_expenses');
    if (dailyJson != null) {
      final List<dynamic> decoded = json.decode(dailyJson);
      final now = DateTime.now();
      double dailyTotal = 0;
      for (var e in decoded) {
        final date = DateTime.parse(e['date']);
        if (date.year == now.year && date.month == now.month) {
          dailyTotal += (e['amount'] as num).toDouble();
        }
      }
      setState(() {
        _monthlyExpenses += dailyTotal;
      });
    }
  }

  Future<void> _saveIncome() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_incomeSources.map((e) => e.toJson()).toList());
    await prefs.setString('income_sources', encoded);
  }

  double get _totalIncome => _incomeSources.fold(0, (sum, e) => sum + e.amount);
  double get _balance => _totalIncome - _monthlyExpenses;

  void _showAddIncomeDialog(String type) {
    final controller = TextEditingController();
    final existingIncome = _incomeSources.where((e) => e.type == type).toList();
    if (existingIncome.isNotEmpty) {
      controller.text = existingIncome.first.amount.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getIncomeText(type, widget.language)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: getIncomeText('enter_amount', widget.language),
            prefixText: '${getIncomeText('rupees', widget.language)} ',
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getIncomeText('cancel', widget.language)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              setState(() {
                _incomeSources.removeWhere((e) => e.type == type);
                if (amount > 0) {
                  _incomeSources.add(IncomeSource(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: type,
                    amount: amount,
                  ));
                }
              });
              _saveIncome();
              Navigator.pop(context);
            },
            child: Text(getIncomeText('save', widget.language)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _balance >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(getIncomeText('title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPositive
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      getIncomeText('balance', widget.language),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${getIncomeText('rupees', widget.language)} ${_balance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPositive
                              ? getIncomeText('saving', widget.language)
                              : getIncomeText('overspending', widget.language),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Income vs Expenses
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      getIncomeText('monthly_income', widget.language),
                      _totalIncome,
                      Colors.green,
                      Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      getIncomeText('total_expenses', widget.language),
                      _monthlyExpenses,
                      Colors.red,
                      Icons.arrow_upward,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Income Sources Section
              Row(
                children: [
                  Text(
                    getIncomeText('income_sources', widget.language),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Income Type Cards
              ...incomeTypes.map((type) {
                final existing = _incomeSources.where((e) => e.type == type['key']).toList();
                final amount = existing.isNotEmpty ? existing.first.amount : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: (type['color'] as Color).withAlpha(50),
                      radius: 28,
                      child: Icon(
                        type['icon'] as IconData,
                        color: type['color'] as Color,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      getIncomeText(type['key'] as String, widget.language),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${getIncomeText('rupees', widget.language)} ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: type['color'] as Color,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _showAddIncomeDialog(type['key'] as String),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type['color'] as Color,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(amount > 0 ? getIncomeText('save', widget.language) : getIncomeText('add_income', widget.language)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${getIncomeText('rupees', widget.language)} ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
