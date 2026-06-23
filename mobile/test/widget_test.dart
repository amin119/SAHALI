import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahali/app.dart';
import 'package:sahali/features/report/viewmodels/report_form_provider.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => ReportFormProvider())],
        child: const SahaliApp(),
      ),
    );
    expect(find.byType(SahaliApp), findsOneWidget);
  });
}
