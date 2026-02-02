import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Translations for expenses screen
Map<String, Map<String, String>> expenseTranslations = {
  'en': {
    'title': 'Monthly Expenses',
    'grocery': 'Grocery',
    'school': 'School / Tuition',
    'bills': 'Bills',
    'transport': 'Transport',
    'other': 'Other',
    'total': 'Total',
    'add': 'Add',
    'enter_amount': 'Enter amount',
    'save': 'Save',
    'cancel': 'Cancel',
    'clear_all': 'Clear All',
    'rupees': 'Rs.',
  },
  'ur': {
    'title': 'ماہانہ اخراجات',
    'grocery': 'گروسری',
    'school': 'سکول / ٹیوشن',
    'bills': 'بلز',
    'transport': 'ٹرانسپورٹ',
    'other': 'دیگر',
    'total': 'کل',
    'add': 'شامل کریں',
    'enter_amount': 'رقم درج کریں',
    'save': 'محفوظ کریں',
    'cancel': 'منسوخ',
    'clear_all': 'سب صاف کریں',
    'rupees': 'روپے',
  },
  'sd': {
    'title': 'مهيني جا خرچا',
    'grocery': 'گروسري',
    'school': 'اسڪول / ٽيوشن',
    'bills': 'بل',
    'transport': 'ٽرانسپورٽ',
    'other': 'ٻيو',
    'total': 'ڪل',
    'add': 'شامل ڪريو',
    'enter_amount': 'رقم لکو',
    'save': 'محفوظ ڪريو',
    'cancel': 'رد ڪريو',
    'clear_all': 'سڀ صاف ڪريو',
    'rupees': 'رپيا',
  },
};

String getExpenseText(String key, String lang) {
  return expenseTranslations[lang]?[key] ?? expenseTranslations['en']![key]!;
}

class ExpensesScreen extends StatefulWidget {
  final String language;

  const ExpensesScreen({super.key, required this.language});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  Map<String, double> expenses = {
    'grocery': 0,
    'school': 0,
    'bills': 0,
    'transport': 0,
    'other': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString('expenses');
    if (expensesJson != null) {
      setState(() {
        final decoded = json.decode(expensesJson) as Map<String, dynamic>;
        expenses = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      });
    }
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', json.encode(expenses));
  }

  double get total => expenses.values.fold(0, (sum, value) => sum + value);

  void _showAddDialog(String category) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getExpenseText(category, widget.language)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: getExpenseText('enter_amount', widget.language),
            prefixText: '${getExpenseText('rupees', widget.language)} ',
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getExpenseText('cancel', widget.language)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              setState(() {
                expenses[category] = amount;
              });
              _saveExpenses();
              Navigator.pop(context);
            },
            child: Text(getExpenseText('save', widget.language)),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getExpenseText('clear_all', widget.language)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getExpenseText('cancel', widget.language)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                expenses = {
                  'grocery': 0,
                  'school': 0,
                  'bills': 0,
                  'transport': 0,
                  'other': 0,
                };
              });
              _saveExpenses();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              getExpenseText('clear_all', widget.language),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'key': 'grocery', 'icon': Icons.shopping_basket, 'color': Colors.green},
      {'key': 'school', 'icon': Icons.school, 'color': Colors.blue},
      {'key': 'bills', 'icon': Icons.receipt, 'color': Colors.orange},
      {'key': 'transport', 'icon': Icons.directions_car, 'color': Colors.purple},
      {'key': 'other', 'icon': Icons.more_horiz, 'color': Colors.grey},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(getExpenseText('title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final key = cat['key'] as String;
                  final icon = cat['icon'] as IconData;
                  final color = cat['color'] as Color;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        radius: 28,
                        child: Icon(icon, color: color, size: 28),
                      ),
                      title: Text(
                        getExpenseText(key, widget.language),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${getExpenseText('rupees', widget.language)} ${expenses[key]!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _showAddDialog(key),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(getExpenseText('add', widget.language)),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Total Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(
                  top: BorderSide(color: Colors.green.shade200, width: 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getExpenseText('total', widget.language),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${getExpenseText('rupees', widget.language)} ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
