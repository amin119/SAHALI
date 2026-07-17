import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sahali/app.dart';
import 'package:sahali/core/providers/language_provider.dart';
import 'package:sahali/core/providers/theme_provider.dart';
import 'package:sahali/core/services/sync_service.dart';
import 'package:sahali/features/auth/providers/auth_provider.dart';
import 'package:sahali/features/notifications/providers/notification_settings_provider.dart';
import 'package:sahali/features/notifications/providers/notifications_provider.dart';
import 'package:sahali/features/report/providers/reports_provider.dart';
import 'package:sahali/features/report/viewmodels/report_form_provider.dart';

// Mirrors the real provider tree in main.dart — SahaliApp reads from several
// of these (AuthProvider in particular), so a partial tree throws a
// ProviderNotFoundException before the widget even renders.
void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ReportFormProvider()),
          ChangeNotifierProvider(create: (_) => ReportsProvider()),
          ChangeNotifierProvider(create: (_) => NotificationsProvider()),
          ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
          ChangeNotifierProvider.value(value: SyncService.instance),
        ],
        child: const SahaliApp(),
      ),
    );
    expect(find.byType(SahaliApp), findsOneWidget);

    // The initial route is a splash screen with its own animation + a
    // Future.delayed before navigating onward — pump past that so its timer
    // fires before the test tears down (flutter_test asserts none are left
    // pending at teardown).
    await tester.pump(const Duration(milliseconds: 2300));
  });
}
