import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_reminder.dart';
import '../core/money.dart';
import '../l10n/translations.dart';
import '../services/persistence_service.dart';

class RemindersScreen extends StatefulWidget {
  final String language;
  const RemindersScreen({super.key, required this.language});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<BillReminder> _reminders = [];
  late PersistenceService _persistence;

  static const _prefKey = 'bill_reminders';

  final _billTypes = [
    {'key': 'electricity', 'icon': Icons.bolt, 'color': Colors.orange},
    {'key': 'gas', 'icon': Icons.local_fire_department, 'color': Colors.blue},
    {'key': 'water', 'icon': Icons.water_drop, 'color': Colors.cyan},
    {'key': 'internet', 'icon': Icons.wifi, 'color': Colors.purple},
    {'key': 'mobile', 'icon': Icons.phone_android, 'color': Colors.green},
    {'key': 'school', 'icon': Icons.school, 'color': Colors.indigo},
    {'key': 'rent', 'icon': Icons.home, 'color': Colors.brown},
    {'key': 'other', 'icon': Icons.receipt, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _persistence = PersistenceService();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = (json.decode(raw) as List).map((e) => BillReminder.fromJson(e as Map<String, dynamic>)).toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      setState(() => _reminders = list);
    }
  }

  Future<void> _saveReminders(String affectedId) async {
    final encoded = json.encode(_reminders.map((r) => r.toJson()).toList());
    final ok = await _persistence.write(_prefKey, encoded, affectedIds: {affectedId});
    if (!ok && mounted) {
      setState(() {});
      _showSaveFailedSnackbar();
    }
  }

  void _showSaveFailedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('reminders', 'save_failed', widget.language)),
        action: SnackBarAction(
          label: t('reminders', 'retry', widget.language),
          onPressed: () async {
            final ok = await _persistence.retryPending();
            if (mounted) setState(() {});
            if (!ok && mounted) _showSaveFailedSnackbar();
          },
        ),
      ),
    );
  }

  int _daysUntilDue(DateTime dueDate) {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    return DateTime(dueDate.year, dueDate.month, dueDate.day).difference(d).inDays;
  }

  void _showAddReminderDialog() {
    String? selectedType;
    DateTime? selectedDate;
    final amountCtrl = TextEditingController();
    String? amountError;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t('reminders', 'add_reminder', widget.language)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('reminders', 'select_bill', widget.language), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _billTypes.map((type) {
                    final isSelected = selectedType == type['key'];
                    final color = type['color'] as Color;
                    return ChoiceChip(
                      label: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(type['icon'] as IconData, size: 18, color: isSelected ? Colors.white : color),
                        const SizedBox(width: 4),
                        Text(t('reminders', type['key'] as String, widget.language), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      ]),
                      selected: isSelected,
                      selectedColor: color,
                      onSelected: (v) => setDialogState(() => selectedType = v ? type['key'] as String : null),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(t('reminders', 'due_date', widget.language), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : t('reminders', 'select_date', widget.language)),
                ),
                const SizedBox(height: 20),
                Text(t('reminders', 'amount', widget.language), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '${t('reminders', 'rupees', widget.language)} ',
                    border: const OutlineInputBorder(),
                    errorText: amountError,
                  ),
                  onChanged: (_) => setDialogState(() => amountError = null),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('reminders', 'cancel', widget.language))),
            ElevatedButton(
              onPressed: selectedType != null && selectedDate != null
                  ? () {
                      int? amount;
                      if (amountCtrl.text.isNotEmpty) {
                        final err = validateRupeeInput(amountCtrl.text);
                        if (err != null) { setDialogState(() => amountError = t('reminders', err, widget.language)); return; }
                        amount = rupeesToPaisa(amountCtrl.text);
                      }
                      final reminder = BillReminder(id: DateTime.now().millisecondsSinceEpoch.toString(), billType: selectedType!, dueDate: selectedDate!, amount: amount);
                      setState(() {
                        _reminders.add(reminder);
                        _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                      });
                      Navigator.pop(ctx);
                      _saveReminders(reminder.id);
                    }
                  : null,
              child: Text(t('reminders', 'save', widget.language)),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePaid(BillReminder reminder) async {
    setState(() => reminder.isPaid = !reminder.isPaid);
    await _saveReminders(reminder.id);
  }

  void _deleteReminder(String id) async {
    setState(() => _reminders.removeWhere((r) => r.id == id));
    final encoded = json.encode(_reminders.map((r) => r.toJson()).toList());
    final ok = await _persistence.write(_prefKey, encoded);
    if (!ok && mounted) _showSaveFailedSnackbar();
  }

  @override
  Widget build(BuildContext context) {
    final unpaid = _reminders.where((r) => !r.isPaid).toList();
    final paid = _reminders.where((r) => r.isPaid).toList();
    return Scaffold(
      appBar: AppBar(title: Text(t('reminders', 'title', widget.language)), centerTitle: true, backgroundColor: Theme.of(context).colorScheme.primaryContainer),
      body: SafeArea(
        child: _reminders.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(t('reminders', 'no_reminders', widget.language), style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                ElevatedButton.icon(onPressed: _showAddReminderDialog, icon: const Icon(Icons.add), label: Text(t('reminders', 'add_reminder', widget.language))),
              ]))
            : ListView(padding: const EdgeInsets.all(16), children: [
                ...unpaid.map(_buildReminderCard),
                if (paid.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(t('reminders', 'paid', widget.language), style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  ...paid.map(_buildReminderCard),
                ],
              ]),
      ),
      floatingActionButton: _reminders.isNotEmpty ? FloatingActionButton(onPressed: _showAddReminderDialog, child: const Icon(Icons.add)) : null,
    );
  }

  Widget _buildReminderCard(BillReminder reminder) {
    final bt = _billTypes.firstWhere((bt) => bt['key'] == reminder.billType, orElse: () => _billTypes.last);
    final color = bt['color'] as Color;
    final daysLeft = _daysUntilDue(reminder.dueDate);
    Color statusColor;
    String statusText;
    if (reminder.isPaid) { statusColor = Colors.green; statusText = t('reminders', 'paid', widget.language); }
    else if (daysLeft < 0) { statusColor = Colors.red; statusText = t('reminders', 'overdue', widget.language); }
    else if (daysLeft == 0) { statusColor = Colors.red; statusText = t('reminders', 'due_today', widget.language); }
    else if (daysLeft <= 3) { statusColor = Colors.orange; statusText = t('reminders', 'due_soon', widget.language); }
    else { statusColor = Colors.green; statusText = '$daysLeft ${t('reminders', 'days_left', widget.language)}'; }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: reminder.isPaid ? Colors.grey.shade100 : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(backgroundColor: reminder.isPaid ? Colors.grey.shade300 : color.withAlpha(50), radius: 28, child: Icon(bt['icon'] as IconData, color: reminder.isPaid ? Colors.grey : color, size: 28)),
        title: Row(children: [
          Text(t('reminders', reminder.billType, widget.language), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: reminder.isPaid ? TextDecoration.lineThrough : null, color: reminder.isPaid ? Colors.grey : null)),
          if (_persistence.isUnsaved(reminder.id))
            const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.warning_amber, color: Colors.amber, size: 16)),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text('${reminder.dueDate.day}/${reminder.dueDate.month}/${reminder.dueDate.year}', style: TextStyle(color: reminder.isPaid ? Colors.grey : null)),
          if (reminder.amount != null)
            Text('${t('reminders', 'rupees', widget.language)} ${paisaToDisplay(reminder.amount!)}', style: TextStyle(fontWeight: FontWeight.bold, color: reminder.isPaid ? Colors.grey : color)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(4)),
            child: Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
          ),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(reminder.isPaid ? Icons.undo : Icons.check_circle_outline, color: reminder.isPaid ? Colors.grey : Colors.green), onPressed: () => _togglePaid(reminder)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteReminder(reminder.id)),
        ]),
      ),
    );
  }
}
