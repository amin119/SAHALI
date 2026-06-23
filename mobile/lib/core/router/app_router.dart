import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/language_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/report/screens/category_screen.dart';
import '../../features/report/screens/photo_screen.dart';
import '../../features/report/screens/location_screen.dart';
import '../../features/report/screens/description_screen.dart';
import '../../features/report/screens/review_screen.dart';
import '../../features/report/screens/confirmation_screen.dart';
import '../../features/my_reports/screens/my_reports_screen.dart';
import '../../features/my_reports/screens/report_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../shared/widgets/main_shell.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const language = '/language';
  static const login = '/login';
  static const home = '/home';
  static const reportCategory = '/report/category';
  static const reportPhoto = '/report/photo';
  static const reportLocation = '/report/location';
  static const reportDescription = '/report/description';
  static const reportReview = '/report/review';
  static const reportConfirmation = '/report/confirmation';
  static const myReports = '/my-reports';
  static const reportDetail = '/report/:id';
  static const notifications = '/notifications';
  static const emergency = '/emergency';
  static const profile = '/profile';
}

int _shellIndex(GoRouterState state) {
  final p = state.uri.path;
  if (p.startsWith(AppRoutes.myReports)) return 1;
  if (p.startsWith(AppRoutes.emergency)) return 2;
  if (p.startsWith(AppRoutes.profile)) return 3;
  return 0;
}

GoRouter buildRouter(AuthProvider auth) => GoRouter(
  refreshListenable: auth,
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    final path = state.uri.path;
    // Already logged in and explicitly navigating to login → send to home
    if (path == AppRoutes.login && auth.isLoggedIn) return AppRoutes.home;
    // Everything else is accessible — auth is optional until submission
    return null;
  },
  routes: [
    // ── Auth / wizard flows — no persistent nav ───────────────────────
    GoRoute(path: AppRoutes.splash,       builder: (_, s) => const SplashScreen()),
    GoRoute(path: AppRoutes.onboarding,   builder: (_, s) => const OnboardingScreen()),
    GoRoute(path: AppRoutes.language,     builder: (_, s) => const LanguageScreen()),
    GoRoute(path: AppRoutes.login,        builder: (_, s) => const LoginScreen()),
    GoRoute(path: AppRoutes.reportCategory,    builder: (_, s) => const CategoryScreen()),
    GoRoute(path: AppRoutes.reportPhoto,       builder: (_, s) => const PhotoScreen()),
    GoRoute(path: AppRoutes.reportLocation,    builder: (_, s) => const LocationScreen()),
    GoRoute(path: AppRoutes.reportDescription, builder: (_, s) => const DescriptionScreen()),
    GoRoute(path: AppRoutes.reportReview,      builder: (_, s) => const ReviewScreen()),
    GoRoute(path: AppRoutes.reportConfirmation, builder: (_, s) => const ConfirmationScreen()),
    GoRoute(path: AppRoutes.notifications, builder: (_, s) => const NotificationsScreen()),
    GoRoute(
      path: AppRoutes.reportDetail,
      builder: (_, state) =>
          ReportDetailScreen(reportId: state.pathParameters['id']!),
    ),

    // ── Main app shell — persistent floating nav ──────────────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(
        currentIndex: _shellIndex(state),
        child: child,
      ),
      routes: [
        GoRoute(path: AppRoutes.home,      builder: (_, s) => const HomeScreen()),
        GoRoute(path: AppRoutes.myReports, builder: (_, s) => const MyReportsScreen()),
        GoRoute(path: AppRoutes.emergency, builder: (_, s) => const EmergencyScreen()),
        GoRoute(path: AppRoutes.profile,   builder: (_, s) => const ProfileScreen()),
      ],
    ),
  ],
);
