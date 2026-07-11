import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/money.dart';
import '../l10n/translations.dart';
import '../services/persistence_service.dart';

class SavingsScreen extends StatefulWidget {
  final String language;
  const SavingsScreen({super.key, required this.language});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  int _goal = 0;
  int _saved = 0;
  late PersistenceService _persistence;

  @override
  void initState() {
    super.initState();
    _persistence = PersistenceService();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goal = int.tryParse(prefs.getString('savings_goal') ?? '') ?? 0;
      _saved = int.tryParse(prefs.getString('savings_saved') ?? '') ?? 0;
    });
  }

  Future<void> _saveGoal() async {
    final ok = await _persistence.write('savings_goal', _goal.toString(), affectedIds: {'savings_goal'});
    if (!ok && mounted) { setState(() {}); _showSaveFailedSnackbar(); }
  }

  Future<void> _saveSaved() async {
    final ok = await _persistence.write('savings_saved', _saved.toString(), affectedIds: {'savings_saved'});
    if (!ok && mounted) { setState(() {}); _showSaveFailedSnackbar(); }
  }

  void _showSaveFailedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('savings', 'save_failed', widget.language)),
        action: SnackBarAction(
          label: t('savings', 'retry', widget.language),
          onPressed: () async {
            final ok = await _persistence.retryPending();
            if (mounted) setState(() {});
            if (!ok && mounted) _showSaveFailedSnackbar();
          },
        ),
      ),
    );
  }

  int get _remaining => (_goal - _saved).clamp(0, _goal);
  double get _progress => _goal > 0 ? (_saved / _goal).clamp(0.0, 1.0) : 0.0;

  void _showAmountDialog({
    required String titleKey,
    int? initialPaisa,
    required void Function(int) onSave,
  }) {
    final controller = TextEditingController(text: initialPaisa != null && initialPaisa > 0 ? paisaToDisplay(initialPaisa) : '');
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t('savings', titleKey, widget.language)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              hintText: t('savings', 'enter_amount', widget.language),
              prefixText: '${t('savings', 'rupees', widget.language)} ',
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
            style: const TextStyle(fontSize: 24),
            onChanged: (_) => setDialogState(() => errorText = null),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('savings', 'cancel', widget.language))),
            ElevatedButton(
              onPressed: () {
                final err = validateRupeeInput(controller.text);
                if (err != null) { setDialogState(() => errorText = t('savings', err, widget.language)); return; }
                Navigator.pop(ctx);
                onSave(rupeesToPaisa(controller.text));
              },
              child: Text(t('savings', 'save', widget.language)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetGoalDialog() {
    _showAmountDialog(
      titleKey: 'set_goal',
      initialPaisa: _goal,
      onSave: (amount) async {
        setState(() { _goal = amount; _saved = 0; });
        await _saveGoal();
        await _saveSaved();
      },
    );
  }

  void _showAddSavingsDialog() {
    _showAmountDialog(
      titleKey: 'add_savings',
      onSave: (amount) async {
        setState(() => _saved += amount);
        await _saveSaved();
      },
    );
  }

  void _reset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('savings', 'reset', widget.language)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('savings', 'cancel', widget.language))),
          ElevatedButton(
            onPressed: () async {
              setState(() { _goal = 0; _saved = 0; });
              Navigator.pop(ctx);
              await _saveGoal();
              await _saveSaved();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('savings', 'reset', widget.language), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _goal > 0 && _saved >= _goal;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('savings', 'title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [if (_goal > 0) IconButton(icon: const Icon(Icons.refresh), onPressed: _reset)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: SizedBox(height: 70, child: ElevatedButton.icon(
                    onPressed: _showSetGoalDialog,
                    icon: const Icon(Icons.flag, size: 28),
                    label: Text(t('savings', 'set_goal', widget.language), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ))),
                  const SizedBox(width: 12),
                  Expanded(child: SizedBox(height: 70, child: ElevatedButton.icon(
                    onPressed: _showAddSavingsDialog,
                    icon: const Icon(Icons.add, size: 28),
                    label: Text(t('savings', 'add_savings', widget.language), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ))),
                ],
              ),
              const SizedBox(height: 30),
              if (_goal == 0)
                Column(children: [
                  Icon(Icons.savings, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(t('savings', 'no_goal', widget.language), style: TextStyle(fontSize: 18, color: Colors.grey.shade600), textAlign: TextAlign.center),
                ]),
              if (_goal > 0) ...[
                SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(value: _progress, strokeWidth: 15, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(isComplete ? Colors.green : Colors.blue)),
                      Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${(_progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isComplete ? Colors.green : Colors.blue)),
                          if (isComplete) Text(t('savings', 'complete', widget.language), style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildStatCard(t('savings', 'goal', widget.language), _goal, Colors.blue, Icons.flag, persistenceKey: 'savings_goal'),
                const SizedBox(height: 12),
                _buildStatCard(t('savings', 'saved', widget.language), _saved, Colors.green, Icons.savings, persistenceKey: 'savings_saved'),
                const SizedBox(height: 12),
                _buildStatCard(t('savings', 'remaining', widget.language), _remaining, Colors.orange, Icons.pending),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int paisa, Color color, IconData icon, {String? persistenceKey}) {
    final isUnsaved = persistenceKey != null && _persistence.isUnsaved(persistenceKey);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(80))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Row(children: [
            Text(label, style: const TextStyle(fontSize: 18)),
            if (isUnsaved) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.warning_amber, color: Colors.amber, size: 16)),
          ]),
          const Spacer(),
          Text('${t('savings', 'rupees', widget.language)} ${paisaToDisplay(paisa)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
