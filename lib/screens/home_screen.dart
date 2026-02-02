import 'package:flutter/material.dart';
import 'daily_expenses_screen.dart';
import 'expenses_screen.dart';
import 'savings_screen.dart';
import 'reminders_screen.dart';

// Simple translations
Map<String, Map<String, String>> translations = {
  'en': {
    'app_title': 'Home Budget',
    'daily_expenses': 'Daily Expenses',
    'monthly_budget': 'Monthly Budget',
    'savings_goal': 'Savings Goal',
    'bill_reminders': 'Bill Reminders',
    'language': 'Language',
  },
  'ur': {
    'app_title': 'گھر کا بجٹ',
    'daily_expenses': 'روزانہ اخراجات',
    'monthly_budget': 'ماہانہ بجٹ',
    'savings_goal': 'بچت کا ہدف',
    'bill_reminders': 'بل کی یاد دہانی',
    'language': 'زبان',
  },
  'sd': {
    'app_title': 'گھر جو بجيٽ',
    'daily_expenses': 'روزاني خرچا',
    'monthly_budget': 'مهيني جو بجيٽ',
    'savings_goal': 'بچت جو مقصد',
    'bill_reminders': 'بل جي ياددهاني',
    'language': 'ٻولي',
  },
};

String getText(String key, String lang) {
  return translations[lang]?[key] ?? translations['en']![key]!;
}

class HomeScreen extends StatelessWidget {
  final String language;
  final Function(String) onLanguageChange;

  const HomeScreen({
    super.key,
    required this.language,
    required this.onLanguageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getText('app_title', language),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Daily Expenses Button
              _buildBigButton(
                context,
                icon: Icons.today,
                label: getText('daily_expenses', language),
                color: Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyExpensesScreen(language: language),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Monthly Budget Button
              _buildBigButton(
                context,
                icon: Icons.shopping_cart,
                label: getText('monthly_budget', language),
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpensesScreen(language: language),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Savings Goal Button
              _buildBigButton(
                context,
                icon: Icons.savings,
                label: getText('savings_goal', language),
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavingsScreen(language: language),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Bill Reminders Button
              _buildBigButton(
                context,
                icon: Icons.notifications,
                label: getText('bill_reminders', language),
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RemindersScreen(language: language),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Language Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      getText('language', language),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLanguageButton('EN', 'en'),
                        _buildLanguageButton('اردو', 'ur'),
                        _buildLanguageButton('سنڌي', 'sd'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 90,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String label, String langCode) {
    final isSelected = language == langCode;
    return ElevatedButton(
      onPressed: () => onLanguageChange(langCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
