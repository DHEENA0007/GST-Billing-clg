import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/api_service.dart';
import 'core/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/invoices/invoices_screen.dart';
import 'screens/invoices/create_invoice_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/vendors/vendors_screen.dart';
import 'screens/payments/payments_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/ai/ai_insights_screen.dart';
import 'screens/notes/credit_debit_notes_screen.dart';
import 'screens/audit/audit_screen.dart';
import 'screens/roles/roles_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/landing/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService().init();
  final authProvider = AuthProvider();
  await authProvider.loadSavedSession();
  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const GstBillingApp(),
    ),
  );
}

class GstBillingApp extends StatelessWidget {
  const GstBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final router = GoRouter(
      initialLocation: auth.isLoggedIn ? '/dashboard' : '/',
      redirect: (context, state) {
        final isLoggedIn = auth.isLoggedIn;
        final loc = state.matchedLocation;
        final isPublic = loc == '/' || loc == '/login' || loc == '/register';

        if (!isLoggedIn && !isPublic) return '/login';
        if (isLoggedIn && (loc == '/login' || loc == '/register')) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) => const InvoicesScreen(),
        ),
        GoRoute(
          path: '/invoices/create',
          builder: (context, state) => const CreateInvoiceScreen(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomersScreen(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/vendors',
          builder: (context, state) => const VendorsScreen(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PaymentsScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/ai-insights',
          builder: (context, state) => const AiInsightsScreen(),
        ),
        GoRoute(
          path: '/credit-debit-notes',
          builder: (context, state) => const CreditDebitNotesScreen(),
        ),
        GoRoute(
          path: '/audit',
          builder: (context, state) => const AuditScreen(),
        ),
        GoRoute(
          path: '/roles',
          builder: (context, state) => const RolesScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found: ${state.matchedLocation}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'GST Billing System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3949AB),
          brightness: Brightness.light,
          primary: const Color(0xFF3949AB),
          secondary: const Color(0xFF1565C0),
          surface: const Color(0xFFF5F5F5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3949AB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3949AB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF3949AB),
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xFF3949AB).withOpacity(0.2),
          labelStyle: const TextStyle(fontSize: 13),
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: Color(0xFF3949AB),
          labelColor: Color(0xFF3949AB),
          unselectedLabelColor: Colors.grey,
        ),
      ),
      routerConfig: router,
    );
  }
}
