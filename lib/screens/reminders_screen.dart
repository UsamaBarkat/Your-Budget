import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Translations
Map<String, Map<String, String>> reminderTranslations = {
  'en': {
    'title': 'Bill Reminders',
    'add_reminder': 'Add Reminder',
    'electricity': 'Electricity Bill',
    'gas': 'Gas Bill',
    'water': 'Water Bill',
    'internet': 'Internet / WiFi',
    'mobile': 'Mobile Bill',
    'school': 'School Fee',
    'rent': 'Rent',
    'other': 'Other',
    'due_date': 'Due Date',
    'amount': 'Amount (Optional)',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'rupees': 'Rs.',
    'no_reminders': 'No reminders set',
    'due_today': 'Due Today!',
    'due_soon': 'Due Soon',
    'days_left': 'days left',
    'overdue': 'Overdue!',
    'paid': 'Mark as Paid',
    'select_date': 'Select Date',
    'select_bill': 'Select Bill Type',
  },
  'ur': {
    'title': 'بل کی یاد دہانی',
    'add_reminder': 'یاد دہانی شامل کریں',
    'electricity': 'بجلی کا بل',
    'gas': 'گیس کا بل',
    'water': 'پانی کا بل',
    'internet': 'انٹرنیٹ / وائی فائی',
    'mobile': 'موبائل بل',
    'school': 'سکول فیس',
    'rent': 'کرایہ',
    'other': 'دیگر',
    'due_date': 'آخری تاریخ',
    'amount': 'رقم (اختیاری)',
    'save': 'محفوظ کریں',
    'cancel': 'منسوخ',
    'delete': 'حذف کریں',
    'rupees': 'روپے',
    'no_reminders': 'کوئی یاد دہانی نہیں',
    'due_today': 'آج دینا ہے!',
    'due_soon': 'جلد دینا ہے',
    'days_left': 'دن باقی',
    'overdue': 'وقت گزر گیا!',
    'paid': 'ادا شدہ',
    'select_date': 'تاریخ منتخب کریں',
    'select_bill': 'بل کی قسم منتخب کریں',
  },
  'sd': {
    'title': 'بل جي ياددهاني',
    'add_reminder': 'ياددهاني شامل ڪريو',
    'electricity': 'بجلي جو بل',
    'gas': 'گئس جو بل',
    'water': 'پاڻي جو بل',
    'internet': 'انٽرنيٽ / وائي فائي',
    'mobile': 'موبائيل بل',
    'school': 'اسڪول فيس',
    'rent': 'ڪرايو',
    'other': 'ٻيو',
    'due_date': 'آخري تاريخ',
    'amount': 'رقم (اختياري)',
    'save': 'محفوظ ڪريو',
    'cancel': 'رد ڪريو',
    'delete': 'ختم ڪريو',
    'rupees': 'رپيا',
    'no_reminders': 'ڪا ياددهاني ناهي',
    'due_today': 'اڄ ڏيڻو آهي!',
    'due_soon': 'جلد ڏيڻو آهي',
    'days_left': 'ڏينهن باقي',
    'overdue': 'وقت گذري ويو!',
    'paid': 'ادا ڪيل',
    'select_date': 'تاريخ چونڊيو',
    'select_bill': 'بل جو قسم چونڊيو',
  },
};

String getReminderText(String key, String lang) {
  return reminderTranslations[lang]?[key] ?? reminderTranslations['en']![key]!;
}

class BillReminder {
  final String id;
  final String billType;
  final DateTime dueDate;
  final double? amount;
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
    id: json['id'],
    billType: json['billType'],
    dueDate: DateTime.parse(json['dueDate']),
    amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
    isPaid: json['isPaid'] ?? false,
  );
}

class RemindersScreen extends StatefulWidget {
  final String language;

  const RemindersScreen({super.key, required this.language});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<BillReminder> _reminders = [];

  final List<Map<String, dynamic>> billTypes = [
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
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersJson = prefs.getString('bill_reminders');
    if (remindersJson != null) {
      final List<dynamic> decoded = json.decode(remindersJson);
      setState(() {
        _reminders = decoded.map((e) => BillReminder.fromJson(e)).toList();
        _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_reminders.map((e) => e.toJson()).toList());
    await prefs.setString('bill_reminders', encoded);
  }

  int _getDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  void _showAddReminderDialog() {
    String? selectedBillType;
    DateTime? selectedDate;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(getReminderText('add_reminder', widget.language)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill Type Selection
                Text(
                  getReminderText('select_bill', widget.language),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: billTypes.map((type) {
                    final isSelected = selectedBillType == type['key'];
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            size: 18,
                            color: isSelected ? Colors.white : type['color'] as Color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            getReminderText(type['key'] as String, widget.language),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: type['color'] as Color,
                      onSelected: (selected) {
                        setDialogState(() {
                          selectedBillType = selected ? type['key'] as String : null;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Due Date
                Text(
                  getReminderText('due_date', widget.language),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : getReminderText('select_date', widget.language),
                  ),
                ),

                const SizedBox(height: 20),

                // Amount (Optional)
                Text(
                  getReminderText('amount', widget.language),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '${getReminderText('rupees', widget.language)} ',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getReminderText('cancel', widget.language)),
            ),
            ElevatedButton(
              onPressed: selectedBillType != null && selectedDate != null
                  ? () {
                      final reminder = BillReminder(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        billType: selectedBillType!,
                        dueDate: selectedDate!,
                        amount: double.tryParse(amountController.text),
                      );
                      setState(() {
                        _reminders.add(reminder);
                        _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                      });
                      _saveReminders();
                      Navigator.pop(context);
                    }
                  : null,
              child: Text(getReminderText('save', widget.language)),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePaid(BillReminder reminder) {
    setState(() {
      reminder.isPaid = !reminder.isPaid;
    });
    _saveReminders();
  }

  void _deleteReminder(String id) {
    setState(() {
      _reminders.removeWhere((r) => r.id == id);
    });
    _saveReminders();
  }

  @override
  Widget build(BuildContext context) {
    final unpaidReminders = _reminders.where((r) => !r.isPaid).toList();
    final paidReminders = _reminders.where((r) => r.isPaid).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(getReminderText('title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: _reminders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      getReminderText('no_reminders', widget.language),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddReminderDialog,
                      icon: const Icon(Icons.add),
                      label: Text(getReminderText('add_reminder', widget.language)),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...unpaidReminders.map((reminder) => _buildReminderCard(reminder)),
                  if (paidReminders.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      getReminderText('paid', widget.language),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...paidReminders.map((reminder) => _buildReminderCard(reminder)),
                  ],
                ],
              ),
      ),
      floatingActionButton: _reminders.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddReminderDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildReminderCard(BillReminder reminder) {
    final billType = billTypes.firstWhere(
      (t) => t['key'] == reminder.billType,
      orElse: () => billTypes.last,
    );
    final color = billType['color'] as Color;
    final icon = billType['icon'] as IconData;
    final daysLeft = _getDaysUntilDue(reminder.dueDate);

    Color statusColor;
    String statusText;

    if (reminder.isPaid) {
      statusColor = Colors.green;
      statusText = getReminderText('paid', widget.language);
    } else if (daysLeft < 0) {
      statusColor = Colors.red;
      statusText = getReminderText('overdue', widget.language);
    } else if (daysLeft == 0) {
      statusColor = Colors.red;
      statusText = getReminderText('due_today', widget.language);
    } else if (daysLeft <= 3) {
      statusColor = Colors.orange;
      statusText = getReminderText('due_soon', widget.language);
    } else {
      statusColor = Colors.green;
      statusText = '$daysLeft ${getReminderText('days_left', widget.language)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: reminder.isPaid ? Colors.grey.shade100 : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: reminder.isPaid ? Colors.grey.shade300 : color.withAlpha(50),
          radius: 28,
          child: Icon(
            icon,
            color: reminder.isPaid ? Colors.grey : color,
            size: 28,
          ),
        ),
        title: Text(
          getReminderText(reminder.billType, widget.language),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration: reminder.isPaid ? TextDecoration.lineThrough : null,
            color: reminder.isPaid ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${reminder.dueDate.day}/${reminder.dueDate.month}/${reminder.dueDate.year}',
              style: TextStyle(
                color: reminder.isPaid ? Colors.grey : null,
              ),
            ),
            if (reminder.amount != null)
              Text(
                '${getReminderText('rupees', widget.language)} ${reminder.amount!.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: reminder.isPaid ? Colors.grey : color,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                reminder.isPaid ? Icons.undo : Icons.check_circle_outline,
                color: reminder.isPaid ? Colors.grey : Colors.green,
              ),
              onPressed: () => _togglePaid(reminder),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteReminder(reminder.id),
            ),
          ],
        ),
      ),
    );
  }
}
