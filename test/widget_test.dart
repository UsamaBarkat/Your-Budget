import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/main.dart';
import 'package:home_budget_app/services/language_service.dart';

void main() {
  testWidgets('App loads and shows home screen title', (WidgetTester tester) async {
    final langService = LanguageService(
      read: () async => null,
      write: (lang) async => true,
    );
    await tester.pumpWidget(HomeBudgetApp(
      initialLanguage: 'en',
      langService: langService,
    ));
    expect(find.text('Home Budget'), findsOneWidget);
  });
}
