import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme/app_theme.dart';
import 'models/category.dart';
import 'models/transaction.dart';
import 'models/recurring_transaction.dart';
import 'models/budget.dart';
import 'services/data_service.dart';
import 'services/security_service.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('Error initializing Mobile Ads: $e');
  }

  await Hive.initFlutter();

  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(TransactionScopeAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(RecurrenceFrequencyAdapter());
  Hive.registerAdapter(RecurringTransactionAdapter());
  Hive.registerAdapter(BudgetAdapter());

  await DataService().initialize();

  runApp(const ByeLuiApp());
}

class ByeLuiApp extends StatelessWidget {
  const ByeLuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ByeLui',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryCoral,
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AppLockGate(),
    );
  }
}

/// Gates app entry behind the PIN/biometric lock, if one has been set up.
/// Currently only checks at cold start — for lock-on-resume too, wrap this
/// in a WidgetsBindingObserver that re-locks on AppLifecycleState.paused.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool? _needsUnlock;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final hasPin = await SecurityService().hasPin();
    if (mounted) setState(() => _needsUnlock = hasPin);
  }

  @override
  Widget build(BuildContext context) {
    if (_needsUnlock == null) {
      return const Scaffold(backgroundColor: AppTheme.primaryCharcoal, body: SizedBox());
    }
    if (_needsUnlock == true) {
      return LockScreen(onUnlocked: () => setState(() => _needsUnlock = false));
    }
    return const HomeScreen();
  }
}
