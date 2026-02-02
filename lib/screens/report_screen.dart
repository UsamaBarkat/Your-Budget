import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

// Translations
Map<String, Map<String, String>> reportTranslations = {
  'en': {
    'title': 'Monthly Report',
    'total_spent': 'Total Spent',
    'category_breakdown': 'Category Breakdown',
    'rupees': 'Rs.',
    'grocery': 'Grocery',
    'school': 'School',
    'bills': 'Bills',
    'transport': 'Transport',
    'other': 'Other',
    'daily': 'Daily Expenses',
    'no_data': 'No expenses recorded this month',
    'this_month': 'This Month',
  },
  'ur': {
    'title': 'ماہانہ رپورٹ',
    'total_spent': 'کل خرچہ',
    'category_breakdown': 'زمرے کے حساب سے',
    'rupees': 'روپے',
    'grocery': 'گروسری',
    'school': 'سکول',
    'bills': 'بلز',
    'transport': 'ٹرانسپورٹ',
    'other': 'دیگر',
    'daily': 'روزانہ اخراجات',
    'no_data': 'اس مہینے کوئی خرچہ درج نہیں',
    'this_month': 'اس مہینے',
  },
  'sd': {
    'title': 'مهيني جي رپورٽ',
    'total_spent': 'ڪل خرچ',
    'category_breakdown': 'زمري جي حساب سان',
    'rupees': 'رپيا',
    'grocery': 'گروسري',
    'school': 'اسڪول',
    'bills': 'بل',
    'transport': 'ٽرانسپورٽ',
    'other': 'ٻيو',
    'daily': 'روزاني خرچا',
    'no_data': 'هن مهيني ڪو خرچو درج ناهي',
    'this_month': 'هن مهيني',
  },
};

String getReportText(String key, String lang) {
  return reportTranslations[lang]?[key] ?? reportTranslations['en']![key]!;
}

class ReportScreen extends StatefulWidget {
  final String language;

  const ReportScreen({super.key, required this.language});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Map<String, double> _categoryExpenses = {};
  double _dailyTotal = 0;
  bool _isLoading = true;

  final Map<String, Color> categoryColors = {
    'grocery': Colors.green,
    'school': Colors.blue,
    'bills': Colors.orange,
    'transport': Colors.purple,
    'other': Colors.grey,
    'daily': Colors.pink,
  };

  final Map<String, IconData> categoryIcons = {
    'grocery': Icons.shopping_basket,
    'school': Icons.school,
    'bills': Icons.receipt,
    'transport': Icons.directions_car,
    'other': Icons.more_horiz,
    'daily': Icons.today,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load monthly expenses
    Map<String, double> expenses = {
      'grocery': 0,
      'school': 0,
      'bills': 0,
      'transport': 0,
      'other': 0,
    };

    final String? expensesJson = prefs.getString('expenses');
    if (expensesJson != null) {
      final decoded = json.decode(expensesJson) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        if (expenses.containsKey(key)) {
          expenses[key] = (value as num).toDouble();
        }
      });
    }

    // Load daily expenses for this month
    double dailyTotal = 0;
    final String? dailyJson = prefs.getString('daily_expenses');
    if (dailyJson != null) {
      final List<dynamic> decoded = json.decode(dailyJson);
      final now = DateTime.now();
      for (var e in decoded) {
        final date = DateTime.parse(e['date']);
        if (date.year == now.year && date.month == now.month) {
          dailyTotal += (e['amount'] as num).toDouble();
        }
      }
    }

    setState(() {
      _categoryExpenses = expenses;
      _dailyTotal = dailyTotal;
      _isLoading = false;
    });
  }

  double get _totalSpent {
    double total = _categoryExpenses.values.fold(0, (sum, val) => sum + val);
    return total + _dailyTotal;
  }

  List<PieChartSectionData> _buildPieChartSections() {
    List<PieChartSectionData> sections = [];

    final allExpenses = {..._categoryExpenses};
    if (_dailyTotal > 0) {
      allExpenses['daily'] = _dailyTotal;
    }

    if (_totalSpent == 0) return sections;

    allExpenses.forEach((key, value) {
      if (value > 0) {
        final percentage = (value / _totalSpent) * 100;
        sections.add(
          PieChartSectionData(
            value: value,
            title: '${percentage.toStringAsFixed(0)}%',
            color: categoryColors[key] ?? Colors.grey,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    });

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(getReportText('title', widget.language)),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(getReportText('title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: _totalSpent == 0
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      getReportText('no_data', widget.language),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Total Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            getReportText('total_spent', widget.language),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${getReportText('rupees', widget.language)} ${_totalSpent.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getReportText('this_month', widget.language),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pie Chart
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category Breakdown
                    Text(
                      getReportText('category_breakdown', widget.language),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category List
                    ..._categoryExpenses.entries.where((e) => e.value > 0).map((entry) {
                      final percentage = (entry.value / _totalSpent) * 100;
                      return _buildCategoryItem(
                        entry.key,
                        entry.value,
                        percentage,
                      );
                    }),

                    // Daily expenses
                    if (_dailyTotal > 0)
                      _buildCategoryItem(
                        'daily',
                        _dailyTotal,
                        (_dailyTotal / _totalSpent) * 100,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryItem(String key, double amount, double percentage) {
    final color = categoryColors[key] ?? Colors.grey;
    final icon = categoryIcons[key] ?? Icons.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(50),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getReportText(key, widget.language),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: color.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${getReportText('rupees', widget.language)} ${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
