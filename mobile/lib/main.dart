import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/network/api_client.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/report/viewmodels/report_form_provider.dart';
import 'features/report/providers/reports_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/notifications/providers/notification_settings_provider.dart';
import 'core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackendConfig.load();
  SyncService.instance.init(); // start offline queue flush timer
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
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
}
