import 'package:flutter/material.dart';
import '../l10n/translations.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'zakat_screen.dart';

class SectionShell extends StatefulWidget {
  final String language;
  final Function(String) onLanguageChange;
  const SectionShell({super.key, required this.language, required this.onLanguageChange});

  @override
  State<SectionShell> createState() => _SectionShellState();
}

class _SectionShellState extends State<SectionShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(language: lang, onLanguageChange: widget.onLanguageChange),
          ReportsScreen(language: lang, isActive: _currentIndex == 1),
          ZakatScreen(language: lang),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: t('shell', 'home', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: t('shell', 'reports', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.volunteer_activism),
            label: t('shell', 'zakat', lang),
          ),
        ],
      ),
    );
  }
}
