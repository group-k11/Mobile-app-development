import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/sales_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';

bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    _firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    _firebaseInitialized = false;
  }
  await Hive.initFlutter();

  // Initialize Hive boxes for caching and offline sync
  final productProvider = ProductProvider();
  await productProvider.initializeCache();
  final salesProvider = SalesProvider();
  await salesProvider.initializeSync();

  runApp(ShelfSenseApp(
    firebaseReady: _firebaseInitialized,
    productProvider: productProvider,
    salesProvider: salesProvider,
  ));
}


class ShelfSenseApp extends StatelessWidget {
  final bool firebaseReady;
  final ProductProvider productProvider;
  final SalesProvider salesProvider;

  const ShelfSenseApp({
    super.key,
    this.firebaseReady = false,
    required this.productProvider,
    required this.salesProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: productProvider),
        ChangeNotifierProvider.value(value: salesProvider),
      ],
      child: MaterialApp(
        title: kAppName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        // Start at the auth wrapper which decides login vs home
        home: AuthWrapper(firebaseReady: firebaseReady),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => HomeShell(firebaseReady: firebaseReady),
        },
      ),
    );
  }
}

/// Checks auth state and shows Login or Home accordingly.
class AuthWrapper extends StatefulWidget {
  final bool firebaseReady;
  const AuthWrapper({super.key, this.firebaseReady = false});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_rounded, size: 64, color: AppColors.primary),
              SizedBox(height: 16),
              Text(kAppName,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              SizedBox(height: 16),
              CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isLoggedIn) {
      return HomeShell(firebaseReady: widget.firebaseReady);
    }
    return const LoginScreen();
  }
}

/// Main app shell with bottom navigation and role-based tabs.
class HomeShell extends StatefulWidget {
  final bool firebaseReady;
  const HomeShell({super.key, this.firebaseReady = false});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    // Redirect to login if not authenticated
    if (!authProvider.isLoggedIn) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    if (!mounted) return;
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    productProvider.listenToProducts();

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    salesProvider.listenToSales();

    // Sync offline sales when connectivity returns
    Connectivity().onConnectivityChanged.listen((results) {
      // results is a List<ConnectivityResult>
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        salesProvider.syncOfflineSales();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.isOwner;

    // Build screens based on role
    final List<Widget> screens = [
      const DashboardScreen(),
      const ProductsScreen(),
      const ScanScreen(),
      const SalesHistoryScreen(),
      if (isOwner) const AnalyticsScreen(),
      const SettingsScreen(),
    ];

    // Build nav items based on role
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        activeIcon: Icon(Icons.inventory_2),
        label: 'Products',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.qr_code_scanner_outlined),
        activeIcon: Icon(Icons.qr_code_scanner),
        label: 'Scan',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'Sales',
      ),
      if (isOwner)
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    // Ensure index is in bounds
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: navItems,
        ),
      ),
    );
  }
}
