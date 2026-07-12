import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/money.dart';
import '../core/report_utils.dart';
import '../l10n/translations.dart';
import '../models/daily_expense.dart';

class ReportsScreen extends StatefulWidget {
  final String language;
  final bool isActive;
  const ReportsScreen({super.key, required this.language, required this.isActive});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<int, int> _bucket = {};
  int _entryCount = 0;
  int _totalPaisa = 0;
  // savings_goal / savings_saved are stored as String(int paisa) by Spec 1
  // PersistenceService (_goal.toString()). Confirmed in SavingsScreen: _goal is
  // int paisa set via rupeesToPaisa(). Loaded with int.tryParse — safe to display
  // via paisaToDisplay().
  int _goalPaisa = 0;
  int _savedPaisa = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    Map<int, int> bucket = {};
    int count = 0;
    int total = 0;
    final raw = prefs.getString('daily_expenses');
    if (raw != null) {
      final list = (json.decode(raw) as List)
          .map((e) => DailyExpense.fromJson(e as Map<String, dynamic>))
          .toList();
      bucket = bucketExpensesByDay(list, now);
      for (final e in list) {
        if (e.date.year == now.year && e.date.month == now.month) {
          count++;
          total += e.amount;
        }
      }
    }

    // String(int paisa) format — see comment on _goalPaisa above.
    final goalPaisa = int.tryParse(prefs.getString('savings_goal') ?? '') ?? 0;
    final savedPaisa = int.tryParse(prefs.getString('savings_saved') ?? '') ?? 0;

    if (!mounted) return;
    setState(() {
      _bucket = bucket;
      _entryCount = count;
      _totalPaisa = total;
      _goalPaisa = goalPaisa;
      _savedPaisa = savedPaisa;
      _loaded = true;
    });
  }

  List<FlSpot> get _spots {
    final today = DateTime.now().day;
    return List.generate(today, (i) {
      final day = i + 1;
      return FlSpot(day.toDouble(), (_bucket[day] ?? 0) / 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t('reports', 'title', lang)),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t('reports', 'title', lang)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('reports', 'this_month', lang),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _bucket.isEmpty ? _buildEmptyState(lang) : _buildChart(context),
              const SizedBox(height: 16),
              _buildSummary(lang),
              if (_goalPaisa > 0) ...[
                const SizedBox(height: 16),
                _buildSavings(lang),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            t('reports', 'no_expenses', lang),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final today = DateTime.now().day;
    final xInterval = (today / 6).ceilToDouble().clamp(1.0, 5.0);
    return SizedBox(
      height: 200,
      child: LineChart(LineChartData(
        minX: 1,
        maxX: today.toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: false,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            interval: xInterval,
            reservedSize: 28,
            getTitlesWidget: (val, _) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(val.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (val, _) => Text(
              val.toInt().toString(),
              style: const TextStyle(fontSize: 10),
            ),
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
      )),
    );
  }

  Widget _buildSummary(String lang) {
    final rupees = t('reports', 'rupees', lang);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('reports', 'total_spent', lang),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text('$rupees ${paisaToDisplay(_totalPaisa)}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
        ]),
        Text('$_entryCount ${t('reports', 'entries', lang)}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
      ]),
    );
  }

  Widget _buildSavings(String lang) {
    final progress = (_savedPaisa / _goalPaisa).clamp(0.0, 1.0);
    final rupees = t('reports', 'rupees', lang);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t('reports', 'savings_goal', lang),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: progress, minHeight: 8),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${t('reports', 'saved', lang)}: $rupees ${paisaToDisplay(_savedPaisa)}',
            style: const TextStyle(fontSize: 13)),
        Text('${t('reports', 'of', lang)} $rupees ${paisaToDisplay(_goalPaisa)}',
            style: const TextStyle(fontSize: 13)),
      ]),
    ]);
  }
}
