import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Translations for savings screen
Map<String, Map<String, String>> savingsTranslations = {
  'en': {
    'title': 'Savings Goal',
    'goal': 'Your Goal',
    'saved': 'Saved',
    'remaining': 'Remaining',
    'set_goal': 'Set Goal',
    'add_savings': 'Add Savings',
    'enter_amount': 'Enter amount',
    'save': 'Save',
    'cancel': 'Cancel',
    'reset': 'Reset',
    'rupees': 'Rs.',
    'complete': 'Goal Complete!',
    'no_goal': 'Set a savings goal to start!',
  },
  'ur': {
    'title': 'بچت کا ہدف',
    'goal': 'آپ کا ہدف',
    'saved': 'بچت',
    'remaining': 'باقی',
    'set_goal': 'ہدف مقرر کریں',
    'add_savings': 'بچت شامل کریں',
    'enter_amount': 'رقم درج کریں',
    'save': 'محفوظ کریں',
    'cancel': 'منسوخ',
    'reset': 'ری سیٹ',
    'rupees': 'روپے',
    'complete': 'ہدف مکمل!',
    'no_goal': 'شروع کرنے کے لیے ہدف مقرر کریں!',
  },
  'sd': {
    'title': 'بچت جو مقصد',
    'goal': 'توهان جو مقصد',
    'saved': 'بچت',
    'remaining': 'باقي',
    'set_goal': 'مقصد مقرر ڪريو',
    'add_savings': 'بچت شامل ڪريو',
    'enter_amount': 'رقم لکو',
    'save': 'محفوظ ڪريو',
    'cancel': 'رد ڪريو',
    'reset': 'ري سيٽ',
    'rupees': 'رپيا',
    'complete': 'مقصد مڪمل!',
    'no_goal': 'شروع ڪرڻ لاءِ مقصد مقرر ڪريو!',
  },
};

String getSavingsText(String key, String lang) {
  return savingsTranslations[lang]?[key] ?? savingsTranslations['en']![key]!;
}

class SavingsScreen extends StatefulWidget {
  final String language;

  const SavingsScreen({super.key, required this.language});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  double _goal = 0;
  double _saved = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goal = prefs.getDouble('savings_goal') ?? 0;
      _saved = prefs.getDouble('savings_saved') ?? 0;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('savings_goal', _goal);
    await prefs.setDouble('savings_saved', _saved);
  }

  double get _remaining => (_goal - _saved).clamp(0, double.infinity);
  double get _progress => _goal > 0 ? (_saved / _goal).clamp(0, 1) : 0;

  void _showSetGoalDialog() {
    final controller = TextEditingController(
      text: _goal > 0 ? _goal.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getSavingsText('set_goal', widget.language)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: getSavingsText('enter_amount', widget.language),
            prefixText: '${getSavingsText('rupees', widget.language)} ',
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getSavingsText('cancel', widget.language)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              setState(() {
                _goal = amount;
                _saved = 0; // Reset saved amount when setting new goal
              });
              _saveData();
              Navigator.pop(context);
            },
            child: Text(getSavingsText('save', widget.language)),
          ),
        ],
      ),
    );
  }

  void _showAddSavingsDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getSavingsText('add_savings', widget.language)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: getSavingsText('enter_amount', widget.language),
            prefixText: '${getSavingsText('rupees', widget.language)} ',
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 24),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getSavingsText('cancel', widget.language)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              setState(() {
                _saved += amount;
              });
              _saveData();
              Navigator.pop(context);
            },
            child: Text(getSavingsText('save', widget.language)),
          ),
        ],
      ),
    );
  }

  void _reset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getSavingsText('reset', widget.language)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getSavingsText('cancel', widget.language)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _goal = 0;
                _saved = 0;
              });
              _saveData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              getSavingsText('reset', widget.language),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _saved >= _goal && _goal > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(getSavingsText('title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (_goal > 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Two Big Buttons at TOP
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 70,
                      child: ElevatedButton.icon(
                        onPressed: _showSetGoalDialog,
                        icon: const Icon(Icons.flag, size: 28),
                        label: Text(
                          getSavingsText('set_goal', widget.language),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 70,
                      child: ElevatedButton.icon(
                        onPressed: _showAddSavingsDialog,
                        icon: const Icon(Icons.add, size: 28),
                        label: Text(
                          getSavingsText('add_savings', widget.language),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Show message if no goal set
              if (_goal == 0)
                Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.savings, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        getSavingsText('no_goal', widget.language),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Progress Circle (only show if goal is set)
              if (_goal > 0) ...[
                SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 15,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isComplete ? Colors.green : Colors.blue,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(_progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isComplete ? Colors.green : Colors.blue,
                              ),
                            ),
                            if (isComplete)
                              Text(
                                getSavingsText('complete', widget.language),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Stats Cards
                _buildStatCard(
                  getSavingsText('goal', widget.language),
                  _goal,
                  Colors.blue,
                  Icons.flag,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  getSavingsText('saved', widget.language),
                  _saved,
                  Colors.green,
                  Icons.savings,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  getSavingsText('remaining', widget.language),
                  _remaining,
                  Colors.orange,
                  Icons.pending,
                ),
              ],

              const SizedBox(height: 20),
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
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(fontSize: 18),
          ),
          const Spacer(),
          Text(
            '${getSavingsText('rupees', widget.language)} ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
