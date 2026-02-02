import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const HomeBudgetApp());
    expect(find.text('Home Budget'), findsOneWidget);
  });
}
