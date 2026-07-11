import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/money.dart';
import '../l10n/translations.dart';
import '../services/persistence_service.dart';

class ExpensesScreen extends StatefulWidget {
  final String language;
  const ExpensesScreen({super.key, required this.language});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  static const _prefKey = 'expenses';
  static const _categoryKeys = ['grocery', 'school', 'bills', 'transport', 'other'];

  Map<String, int> _expenses = {for (final k in _categoryKeys) k: 0};
  late PersistenceService _persistence;

  final _categoryMeta = [
    {'key': 'grocery', 'icon': Icons.shopping_basket, 'color': Colors.green},
    {'key': 'school', 'icon': Icons.school, 'color': Colors.blue},
    {'key': 'bills', 'icon': Icons.receipt, 'color': Colors.orange},
    {'key': 'transport', 'icon': Icons.directions_car, 'color': Colors.purple},
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
      final decoded = json.decode(raw) as Map<String, dynamic>;
      setState(() => _expenses = decoded.map((k, v) => MapEntry(k, (v as num).toInt())));
    }
  }

  Future<void> _saveExpenses(Set<String> affectedIds) async {
    final encoded = json.encode(_expenses);
    final ok = await _persistence.write(_prefKey, encoded, affectedIds: affectedIds);
    if (!ok && mounted) {
      setState(() {});
      _showSaveFailedSnackbar();
    }
  }

  void _showSaveFailedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('expenses', 'save_failed', widget.language)),
        action: SnackBarAction(
          label: t('expenses', 'retry', widget.language),
          onPressed: () async {
            final ok = await _persistence.retryPending();
            if (mounted) setState(() {});
            if (!ok && mounted) _showSaveFailedSnackbar();
          },
        ),
      ),
    );
  }

  int get _total => _expenses.values.fold(0, (s, v) => s + v);

  void _showAddDialog(String category) {
    final controller = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t('expenses', category, widget.language)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              hintText: t('expenses', 'enter_amount', widget.language),
              prefixText: '${t('expenses', 'rupees', widget.language)} ',
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
            style: const TextStyle(fontSize: 20),
            onChanged: (_) => setDialogState(() => errorText = null),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('expenses', 'cancel', widget.language)),
            ),
            ElevatedButton(
              onPressed: () {
                final err = validateRupeeInput(controller.text);
                if (err != null) {
                  setDialogState(() => errorText = t('expenses', err, widget.language));
                  return;
                }
                setState(() => _expenses[category] = rupeesToPaisa(controller.text));
                Navigator.pop(ctx);
                _saveExpenses({category});
              },
              child: Text(t('expenses', 'save', widget.language)),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('expenses', 'clear_all', widget.language)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('expenses', 'cancel', widget.language)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _expenses = {for (final k in _categoryKeys) k: 0});
              Navigator.pop(ctx);
              _saveExpenses(_categoryKeys.toSet());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('expenses', 'clear_all', widget.language), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('expenses', 'title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categoryMeta.length,
                itemBuilder: (_, i) {
                  final cat = _categoryMeta[i];
                  return _buildCategoryRow(cat['key'] as String, cat['icon'] as IconData, cat['color'] as Color);
                },
              ),
            ),
            _buildTotalBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String key, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: color.withAlpha(50), radius: 28, child: Icon(icon, color: color, size: 28)),
        title: Row(
          children: [
            Text(t('expenses', key, widget.language), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_persistence.isUnsaved(key))
              const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.warning_amber, color: Colors.amber, size: 16)),
          ],
        ),
        subtitle: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('${t('expenses', 'rupees', widget.language)} ${paisaToDisplay(_expenses[key]!)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ),
        trailing: ElevatedButton(
          onPressed: () => _showAddDialog(key),
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
          child: Text(t('expenses', 'add', widget.language)),
        ),
      ),
    );
  }

  Widget _buildTotalBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green.shade50, border: Border(top: BorderSide(color: Colors.green.shade200, width: 2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t('expenses', 'total', widget.language), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('${t('expenses', 'rupees', widget.language)} ${paisaToDisplay(_total)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ),
        ],
      ),
    );
  }
}
