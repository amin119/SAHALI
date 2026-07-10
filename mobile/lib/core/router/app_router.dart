import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/language_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/phone_otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/email_verify_screen.dart';
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
import '../../features/notifications/screens/notification_settings_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/help_support_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/agent/screens/agent_missions_screen.dart';
import '../../features/agent/screens/agent_mission_detail_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/agent_shell.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const language = '/language';
  static const login = '/login';
  static const register = '/register';
  static const phoneOtp = '/auth/phone-otp';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const emailVerify = '/auth/verify-email';
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
  static const notificationSettings = '/notifications/settings';
  static const emergency = '/emergency';
  static const profile = '/profile';
  static const helpSupport = '/profile/help';
  static const privacyPolicy = '/profile/privacy';

  // ── Field-agent shell ──────────────────────────────────────────────
  static const agentMissions = '/agent/missions';
  static const agentMissionDetail = '/agent/missions/:id';
  static const agentNotifications = '/agent/notifications';
  static const agentProfile = '/agent/profile';
}

int _shellIndex(GoRouterState state) {
  final p = state.uri.path;
  if (p.startsWith(AppRoutes.myReports)) return 1;
  if (p.startsWith(AppRoutes.emergency)) return 2;
  if (p.startsWith(AppRoutes.profile)) return 3;
  return 0;
}

int _agentShellIndex(GoRouterState state) {
  final p = state.uri.path;
  if (p.startsWith(AppRoutes.agentNotifications)) return 1;
  if (p.startsWith(AppRoutes.agentProfile)) return 2;
  return 0; // agentMissions and its detail sub-route
}

// Routes only a citizen should reach — the report wizard, its detail screen,
// "my reports", home, and emergency. Anything under /report/ is covered by
// the prefix check, which is why the new agent detail route deliberately
// lives under /agent/missions/ instead.
bool _isCitizenOnlyRoute(String path) =>
    path == AppRoutes.home ||
    path.startsWith(AppRoutes.myReports) ||
    path.startsWith('/report/') ||
    path == AppRoutes.emergency;

bool _isAgentOnlyRoute(String path) => path.startsWith('/agent/');

GoRouter buildRouter(AuthProvider auth) => GoRouter(
  refreshListenable: auth,
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    final path = state.uri.path;
    final isAgent = auth.user?.isFieldAgent ?? false;

    if (path == AppRoutes.login && auth.isLoggedIn) {
      return isAgent ? AppRoutes.agentMissions : AppRoutes.home;
    }
    if (!auth.isLoggedIn) return null;

    if (isAgent) {
      if (_isCitizenOnlyRoute(path)) return AppRoutes.agentMissions;
      // Shared screens reached via an old citizen-path reference (e.g. a
      // notification bell icon still calling context.go(AppRoutes.profile))
      // land on the agent-shelled alias instead, so the bottom nav stays
      // correct rather than falling back to the citizen shell.
      if (path == AppRoutes.profile) return AppRoutes.agentProfile;
      if (path == AppRoutes.notifications) return AppRoutes.agentNotifications;
    } else if (_isAgentOnlyRoute(path)) {
      return AppRoutes.home;
    }
    return null;
  },
  routes: [
    // ── Auth / wizard flows — no persistent nav ───────────────────────
    GoRoute(path: AppRoutes.splash,       builder: (_, s) => const SplashScreen()),
    GoRoute(path: AppRoutes.onboarding,   builder: (_, s) => const OnboardingScreen()),
    GoRoute(path: AppRoutes.language,     builder: (_, s) => const LanguageScreen()),
    GoRoute(path: AppRoutes.login,        builder: (_, s) => const LoginScreen()),
    GoRoute(path: AppRoutes.register,     builder: (_, s) => const RegisterScreen()),
    GoRoute(path: AppRoutes.phoneOtp,     builder: (_, s) => const PhoneOtpScreen()),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, s) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (_, s) => ResetPasswordScreen(
        identifier: s.extra as String? ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.emailVerify,
      builder: (_, s) => EmailVerifyScreen(
        email: s.extra as String? ?? '',
      ),
    ),
    GoRoute(path: AppRoutes.reportCategory,    builder: (_, s) => const CategoryScreen()),
    GoRoute(path: AppRoutes.reportPhoto,       builder: (_, s) => const PhotoScreen()),
    GoRoute(path: AppRoutes.reportLocation,    builder: (_, s) => const LocationScreen()),
    GoRoute(path: AppRoutes.reportDescription, builder: (_, s) => const DescriptionScreen()),
    GoRoute(path: AppRoutes.reportReview,      builder: (_, s) => const ReviewScreen()),
    GoRoute(path: AppRoutes.reportConfirmation, builder: (_, s) => const ConfirmationScreen()),
    GoRoute(path: AppRoutes.notifications, builder: (_, s) => const NotificationsScreen()),
    GoRoute(path: AppRoutes.notificationSettings, builder: (_, s) => const NotificationSettingsScreen()),
    GoRoute(path: AppRoutes.helpSupport, builder: (_, s) => const HelpSupportScreen()),
    GoRoute(path: AppRoutes.privacyPolicy, builder: (_, s) => const PrivacyPolicyScreen()),
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

    // ── Field-agent shell — persistent floating nav, distinct tab set ──
    ShellRoute(
      builder: (context, state, child) => AgentShell(
        currentIndex: _agentShellIndex(state),
        child: child,
      ),
      routes: [
        GoRoute(path: AppRoutes.agentMissions, builder: (_, s) => const AgentMissionsScreen()),
        GoRoute(
          path: AppRoutes.agentMissionDetail,
          builder: (_, state) =>
              AgentMissionDetailScreen(reportId: state.pathParameters['id']!),
        ),
        GoRoute(path: AppRoutes.agentNotifications, builder: (_, s) => const NotificationsScreen()),
        GoRoute(path: AppRoutes.agentProfile,       builder: (_, s) => const ProfileScreen()),
      ],
    ),
  ],
);
