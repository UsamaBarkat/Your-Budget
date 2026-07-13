import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/money.dart';
import '../core/report_utils.dart';
import '../l10n/translations.dart';
import '../models/income_source.dart';
import '../services/persistence_service.dart';
import 'income_add_dialog.dart';

class IncomeScreen extends StatefulWidget {
  final String language;
  const IncomeScreen({super.key, required this.language});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  List<IncomeSource> _allSources = [];
  bool _loaded = false;
  late PersistenceService _persistence;

  static const _prefKey = 'income_sources';

  @override
  void initState() {
    super.initState();
    _persistence = PersistenceService();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (!mounted) return;
    setState(() {
      if (raw != null) {
        _allSources = (json.decode(raw) as List)
            .map((e) => IncomeSource.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _loaded = true;
    });
  }

  List<IncomeSource> get _thisMonthSources {
    final now = DateTime.now();
    return _allSources
        .where((s) =>
            s.date != null &&
            s.date!.year == now.year &&
            s.date!.month == now.month)
        .toList()
      ..sort((a, b) => b.date!.compareTo(a.date!));
  }

  Future<void> _persistList(List<IncomeSource> list) async {
    final ok = await _persistence.write(
      _prefKey,
      json.encode(list.map((e) => e.toJson()).toList()),
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _allSources = list);
    } else {
      _showSaveFailedSnackBar(list);
    }
  }

  void _showSaveFailedSnackBar(List<IncomeSource> pendingList) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t('income', 'save_failed', widget.language)),
      action: SnackBarAction(
        label: t('shared', 'retry', widget.language),
        onPressed: () => _persistList(pendingList),
      ),
    ));
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => IncomeAddDialog(
        language: widget.language,
        onSave: (source) {
          Navigator.pop(ctx);
          _persistList([..._allSources, source]);
        },
      ),
    );
  }

  void _showDeleteDialog(IncomeSource source) {
    final lang = widget.language;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t('income', 'delete_confirm', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('shared', 'cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _persistList(
                  _allSources.where((s) => s.id != source.id).toList());
            },
            child: Text(t('shared', 'delete', lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final monthSources = _thisMonthSources;
    final monthTotal = sumIncomeForMonth(_allSources, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(t('income', 'title', lang)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildSummaryCard(lang, monthTotal, monthSources.length),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: Text(t('income', 'add_income', lang)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: monthSources.isEmpty
                        ? _buildEmptyState(lang)
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: monthSources.length,
                            itemBuilder: (_, i) =>
                                _buildTile(monthSources[i], lang),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String lang, int totalPaisa, int count) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('income', 'this_month', lang),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            '${t('shared', 'rupees', lang)} ${paisaToDisplay(totalPaisa)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 4),
          // 'entries' reused from reports scope — same concept, same translations.
          Text('$count ${t('reports', 'entries', lang)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          t('income', 'no_income', lang),
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildTile(IncomeSource source, String lang) {
    final date = source.date!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(source.type,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${date.day}/${date.month}/${date.year}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${t('shared', 'rupees', lang)} ${paisaToDisplay(source.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(source),
            ),
          ],
        ),
      ),
    );
  }
}
