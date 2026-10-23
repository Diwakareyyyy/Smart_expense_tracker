import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_ai_expense_tracker/main.dart';
import 'package:smart_ai_expense_tracker/providers/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const ExpenseTrackerApp(),
      ),
    );
    expect(find.byType(ExpenseTrackerApp), findsOneWidget);
  });
}
