import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_expense.dart';
import '../core/money.dart';
import '../core/date_utils.dart';
import '../l10n/translations.dart';
import '../services/persistence_service.dart';

class DailyExpensesScreen extends StatefulWidget {
  final String language;
  const DailyExpensesScreen({super.key, required this.language});

  @override
  State<DailyExpensesScreen> createState() => _DailyExpensesScreenState();
}

class _DailyExpensesScreenState extends State<DailyExpensesScreen> {
  List<DailyExpense> _expenses = [];
  late PersistenceService _persistence;

  static const _prefKey = 'daily_expenses';

  final _categories = [
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
    _persistence = PersistenceService();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = (json.decode(raw) as List).map((e) => DailyExpense.fromJson(e as Map<String, dynamic>)).toList();
      setState(() => _expenses = list);
    }
  }

  Future<void> _saveExpenses(String affectedId) async {
    final encoded = json.encode(_expenses.map((e) => e.toJson()).toList());
    final ok = await _persistence.write(_prefKey, encoded, affectedIds: {affectedId});
    if (!ok && mounted) {
      setState(() {});
      _showSaveFailedSnackbar();
    }
  }

  void _showSaveFailedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('daily', 'save_failed', widget.language)),
        action: SnackBarAction(
          label: t('daily', 'retry', widget.language),
          onPressed: () async {
            final ok = await _persistence.retryPending();
            if (mounted) setState(() {});
            if (!ok && mounted) _showSaveFailedSnackbar();
          },
        ),
      ),
    );
  }

  List<DailyExpense> get _todayExpenses {
    final now = DateTime.now();
    return _expenses.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
  }

  List<DailyExpense> get _monthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int get _todayTotal => _todayExpenses.fold(0, (s, e) => s + e.amount);
  int get _weekTotal => _expenses.where((e) => isSameWeek(e.date, DateTime.now())).fold(0, (s, e) => s + e.amount);
  int get _monthTotal {
    final now = DateTime.now();
    return _expenses.where((e) => e.date.year == now.year && e.date.month == now.month).fold(0, (s, e) => s + e.amount);
  }

  void _addExpense(String category, int amount) async {
    final expense = DailyExpense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: category,
      amount: amount,
      date: DateTime.now(),
    );
    setState(() => _expenses.add(expense));
    await _saveExpenses(expense.id);
  }

  void _deleteExpense(String id) async {
    setState(() => _expenses.removeWhere((e) => e.id == id));
    final encoded = json.encode(_expenses.map((e) => e.toJson()).toList());
    final ok = await _persistence.write(_prefKey, encoded);
    if (!ok && mounted) _showSaveFailedSnackbar();
  }

  void _showDeleteDialog(DailyExpense expense) {
    final lang = widget.language;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t('daily', 'delete_confirm', lang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('shared', 'cancel', lang))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteExpense(expense.id);
            },
            child: Text(t('shared', 'delete', lang)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(String category) {
    final controller = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t('daily', category, widget.language)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              hintText: t('daily', 'enter_amount', widget.language),
              prefixText: '${t('daily', 'rupees', widget.language)} ',
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
            style: const TextStyle(fontSize: 24),
            onChanged: (_) => setDialogState(() => errorText = null),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('daily', 'cancel', widget.language))),
            ElevatedButton(
              onPressed: () {
                final err = validateRupeeInput(controller.text);
                if (err != null) {
                  setDialogState(() => errorText = t('daily', err, widget.language));
                  return;
                }
                _addExpense(category, rupeesToPaisa(controller.text));
                Navigator.pop(ctx);
              },
              child: Text(t('daily', 'save', widget.language)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('daily', 'title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildSummaryCard(t('daily', 'today', widget.language), _todayTotal, Colors.blue),
                  const SizedBox(width: 8),
                  _buildSummaryCard(t('daily', 'this_week', widget.language), _weekTotal, Colors.orange),
                  const SizedBox(width: 8),
                  _buildSummaryCard(t('daily', 'this_month', widget.language), _monthTotal, Colors.green),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('daily', 'add_expense', widget.language), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((cat) => _buildCategoryButton(cat['key'] as String, cat['icon'] as IconData, cat['color'] as Color)).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(child: _buildExpenseList()),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    final items = _monthExpenses;
    if (items.isEmpty) {
      return Center(child: Text(t('daily', 'no_expenses', widget.language), style: TextStyle(fontSize: 16, color: Colors.grey.shade600)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildExpenseItem(items[i]),
    );
  }

  Widget _buildExpenseItem(DailyExpense expense) {
    final cat = _categories.firstWhere((c) => c['key'] == expense.category, orElse: () => _categories.last);
    final color = cat['color'] as Color;
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withAlpha(50),
            child: Icon(cat['icon'] as IconData, color: color)),
        title: Text(t('daily', expense.category, widget.language)),
        subtitle: Text(DateFormat('dd/MM · hh:mm a').format(expense.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_persistence.isUnsaved(expense.id))
              const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.warning_amber, color: Colors.amber, size: 16)),
            Text('${t('daily', 'rupees', widget.language)} ${paisaToDisplay(expense.amount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _showDeleteDialog(expense),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, int paisa, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(color: color.withAlpha(40), borderRadius: BorderRadius.circular(14), border: Border.all(color: color, width: 1.5)),
        child: Column(
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3), textAlign: TextAlign.center, maxLines: 1)),
            const SizedBox(height: 6),
            FittedBox(fit: BoxFit.scaleDown, child: Text('${t('daily', 'rupees', widget.language)} ${paisaToDisplay(paisa)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color), maxLines: 1)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 6),
            Text(t('daily', key, widget.language), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
