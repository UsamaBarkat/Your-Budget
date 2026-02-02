import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HomeBudgetApp());
}

class HomeBudgetApp extends StatefulWidget {
  const HomeBudgetApp({super.key});

  @override
  State<HomeBudgetApp> createState() => _HomeBudgetAppState();
}

class _HomeBudgetAppState extends State<HomeBudgetApp> {
  // Current language: 'en' = English, 'ur' = Urdu, 'sd' = Sindhi
  String _language = 'en';

  void changeLanguage(String lang) {
    setState(() {
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Budget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: HomeScreen(
        language: _language,
        onLanguageChange: changeLanguage,
      ),
    );
  }
}
