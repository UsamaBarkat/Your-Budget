import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// Translations
Map<String, Map<String, String>> dailyTranslations = {
  'en': {
    'title': 'Daily Expenses',
    'today': 'Today',
    'add_expense': 'Add Expense',
    'total_today': 'Total Today',
    'chai_snacks': 'Chai / Snacks',
    'transport': 'Transport',
    'food': 'Food',
    'shopping': 'Shopping',
    'mobile': 'Mobile Recharge',
    'other': 'Other',
    'enter_amount': 'Enter amount',
    'save': 'Save',
    'cancel': 'Cancel',
    'rupees': 'Rs.',
    'no_expenses': 'No expenses today',
    'delete': 'Delete',
    'this_week': 'This Week',
    'this_month': 'This Month',
  },
  'ur': {
    'title': 'روزانہ اخراجات',
    'today': 'آج',
    'add_expense': 'خرچہ شامل کریں',
    'total_today': 'آج کا کل',
    'chai_snacks': 'چائے / ناشتہ',
    'transport': 'ٹرانسپورٹ',
    'food': 'کھانا',
    'shopping': 'خریداری',
    'mobile': 'موبائل ریچارج',
    'other': 'دیگر',
    'enter_amount': 'رقم درج کریں',
    'save': 'محفوظ کریں',
    'cancel': 'منسوخ',
    'rupees': 'روپے',
    'no_expenses': 'آج کوئی خرچہ نہیں',
    'delete': 'حذف کریں',
    'this_week': 'اس ہفتے',
    'this_month': 'اس مہینے',
  },
  'sd': {
    'title': 'روزاني خرچا',
    'today': 'اڄ',
    'add_expense': 'خرچو شامل ڪريو',
    'total_today': 'اڄ جو ڪل',
    'chai_snacks': 'چانهه / ناشتو',
    'transport': 'ٽرانسپورٽ',
    'food': 'کاڌو',
    'shopping': 'خريداري',
    'mobile': 'موبائيل ريچارج',
    'other': 'ٻيو',
    'enter_amount': 'رقم لکو',
    'save': 'محفوظ ڪريو',
    'cancel': 'رد ڪريو',
    'rupees': 'رپيا',
    'no_expenses': 'اڄ ڪو خرچو ناهي',
    'delete': 'ختم ڪريو',
    'this_week': 'هن هفتي',
    'this_month': 'هن مهيني',
  },
};

String getDailyText(String key, String lang) {
  return dailyTranslations[lang]?[key] ?? dailyTranslations['en']![key]!;
}

class DailyExpense {
  final String id;
  final String category;
  final double amount;
  final DateTime date;

  DailyExpense({
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
    id: json['id'],
    category: json['category'],
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
  );
}

class DailyExpensesScreen extends StatefulWidget {
  final String language;

  const DailyExpensesScreen({super.key, required this.language});

  @override
  State<DailyExpensesScreen> createState() => _DailyExpensesScreenState();
}

class _DailyExpensesScreenState extends State<DailyExpensesScreen> {
  List<DailyExpense> _expenses = [];

  final List<Map<String, dynamic>> categories = [
    {'key': 'chai_snacks', 'icon': Icons.local_cafe, 'color': Colors.brown},
    {'key': 'transport', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'key': 'food', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'key': 'shopping', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'key': 'mobile', 'icon': Icons.phone_android, 'color': Colors.green},
    {'key': 'other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString('daily_expenses');
    if (expensesJson != null) {
      final List<dynamic> decoded = json.decode(expensesJson);
      setState(() {
        _expenses = decoded.map((e) => DailyExpense.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_expenses.map((e) => e.toJson()).toList());
    await prefs.setString('daily_expenses', encoded);
  }

  List<DailyExpense> get _todayExpenses {
    final today = DateTime.now();
    return _expenses.where((e) =>
      e.date.year == today.year &&
      e.date.month == today.month &&
      e.date.day == today.day
    ).toList();
  }

  double get _todayTotal => _todayExpenses.fold(0, (sum, e) => sum + e.amount);

  double get _weekTotal {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _expenses.where((e) => e.date.isAfter(weekStart.subtract(const Duration(days: 1)))).fold(0, (sum, e) => sum + e.amount);
  }

  double get _monthTotal {
    final now = DateTime.now();
    return _expenses.where((e) => e.date.year == now.year && e.date.month == now.month).fold(0, (sum, e) => sum + e.amount);
  }

  void _addExpense(String category, double amount) {
    final expense = DailyExpense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: category,
      amount: amount,
      date: DateTime.now(),
    );
    setState(() {
      _expenses.add(expense);
    });
    _saveExpenses();
  }

  void _deleteExpense(String id) {
    setState(() {
      _expenses.removeWhere((e) => e.id == id);
    });
    _saveExpenses();
  }

  void _showAddDialog(String category) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getDailyText(category, widget.language)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: getDailyText('enter_amount', widget.language),
            prefixText: '${getDailyText('rupees', widget.language)} ',
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getDailyText('cancel', widget.language)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                _addExpense(category, amount);
              }
              Navigator.pop(context);
            },
            child: Text(getDailyText('save', widget.language)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getDailyText('title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildSummaryCard(
                    getDailyText('today', widget.language),
                    _todayTotal,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    getDailyText('this_week', widget.language),
                    _weekTotal,
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    getDailyText('this_month', widget.language),
                    _monthTotal,
                    Colors.green,
                  ),
                ],
              ),
            ),

            // Quick Add Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getDailyText('add_expense', widget.language),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((cat) {
                      return _buildCategoryButton(
                        cat['key'] as String,
                        cat['icon'] as IconData,
                        cat['color'] as Color,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Today's Expenses List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    getDailyText('today', widget.language),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${getDailyText('rupees', widget.language)} ${_todayTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _todayExpenses.isEmpty
                  ? Center(
                      child: Text(
                        getDailyText('no_expenses', widget.language),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _todayExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = _todayExpenses[index];
                        final cat = categories.firstWhere(
                          (c) => c['key'] == expense.category,
                          orElse: () => categories.last,
                        );
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (cat['color'] as Color).withAlpha(50),
                              child: Icon(
                                cat['icon'] as IconData,
                                color: cat['color'] as Color,
                              ),
                            ),
                            title: Text(getDailyText(expense.category, widget.language)),
                            subtitle: Text(DateFormat('hh:mm a').format(expense.date)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${getDailyText('rupees', widget.language)} ${expense.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteExpense(expense.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${getDailyText('rupees', widget.language)} ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String key, IconData icon, Color color) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 52) / 3,
      child: ElevatedButton(
        onPressed: () => _showAddDialog(key),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withAlpha(30),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 6),
            Text(
              getDailyText(key, widget.language),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
