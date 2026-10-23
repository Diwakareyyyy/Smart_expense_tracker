import 'package:go_router/go_router.dart';
import '../../screens/ocr/ocr_receipt_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login/login_screen.dart';
import '../../screens/auth/signup/signup_screen.dart';
import '../../screens/auth/forgot_password/forgot_password_screen.dart';
import '../../screens/dashboard/dashboard_screen1.dart';
import '../../screens/expense/expense_category_screen.dart';
import '../../screens/expense/expense_form_screen.dart';
import '../../screens/expense/add_category_screen.dart';
import '../../screens/income/add_income_screen.dart';
import '../../screens/transfer/add_transfer_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/qr/qr_scanner_screen.dart';
import '../../screens/ai/ai_assistant_screen.dart';
import '../../screens/budget/budget_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/SettingsScreen.dart';
import '../../services/auth_service.dart';
import '../../screens/settings/terms_screen.dart';
import '../../screens/settings/guide_screen.dart';
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isLoggedIn = await AuthService.instance.isLoggedIn();
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forgot-password' ||
        state.matchedLocation == '/';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn &&
        (state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup')) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) => const ExpenseCategoryScreen(),
    ),
    GoRoute(
      path: '/add-expense-form',
      builder: (context, state) {
        final category = state.extra as String? ?? "Food";
        return ExpenseFormScreen(category: category);
      },
    ),
    GoRoute(
      path: '/add-category',
      builder: (context, state) => const AddCategoryScreen(),
    ),
    GoRoute(
      path: '/add-income',
      builder: (context, state) => const AddIncomeScreen(),
    ),
    GoRoute(
      path: '/add-transfer',
      builder: (context, state) => const AddTransferScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/qr',
      builder: (context, state) => const QRScannerScreen(),
    ),
    GoRoute(
      path: '/ocr',
      builder: (context, state) => const OCRReceiptScreen(),
    ),
    GoRoute(
      path: '/ai',
      builder: (context, state) => const AIAssistantScreen(),
    ),
    GoRoute(
      path: '/budget',
      builder: (context, state) => const BudgetScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/guide',
      builder: (context, state) => const GuideScreen(),
    ),
  ],
);
