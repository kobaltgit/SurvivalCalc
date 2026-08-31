import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_calc/main.dart';

void main() {
  testWidgets('SurvivalCalcApp smoke test and navigation tabs render',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SurvivalCalcApp(),
      ),
    );

    // Initial frame
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify main navigation bar items
    expect(find.text('Параметры'), findsWidgets);
    expect(find.text('Дашборд'), findsWidgets);
    expect(find.text('Раскладка'), findsWidgets);
    expect(find.text('Снаряжение'), findsWidgets);
  });
}
