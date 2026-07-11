import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deviceLocale = PlatformDispatcher.instance.locale.languageCode;
  final langService = await LanguageService.create();
  final initialLang = await langService.load(deviceLocale);
  runApp(HomeBudgetApp(initialLanguage: initialLang, langService: langService));
}

class HomeBudgetApp extends StatefulWidget {
  final String initialLanguage;
  final LanguageService langService;

  const HomeBudgetApp({
    super.key,
    required this.initialLanguage,
    required this.langService,
  });

  @override
  State<HomeBudgetApp> createState() => _HomeBudgetAppState();
}

class _HomeBudgetAppState extends State<HomeBudgetApp> {
  late String _language;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
  }

  void changeLanguage(String lang) async {
    setState(() {
      _language = lang;
    });
    await widget.langService.save(lang);
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
