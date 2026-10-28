import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme/app_theme.dart';
import 'models/category.dart';
import 'models/transaction.dart';
import 'models/recurring_transaction.dart';
import 'models/budget.dart';
import 'models/payment_card.dart';
import 'services/data_service.dart';
import 'services/security_service.dart';
import 'services/biometric_service.dart';
import 'services/theme_controller.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'i18n/language_controller.dart';
import 'i18n/s.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();

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
  Hive.registerAdapter(PaymentCardAdapter());

  await DataService().initialize();
  ThemeController().load();
  LanguageController().load();
  runApp(const ByeLuiApp());
}

class ByeLuiApp extends StatefulWidget {
  const ByeLuiApp({super.key});

  @override
  State<ByeLuiApp> createState() => _ByeLuiAppState();
}

class _ByeLuiAppState extends State<ByeLuiApp> with WidgetsBindingObserver {
  final _theme = ThemeController();
  final _lang = LanguageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _theme.addListener(_rebuildAll);
    _lang.addListener(_rebuildAll);
  }

  @override
  void dispose() {
    _theme.removeListener(_rebuildAll);
    _lang.removeListener(_rebuildAll);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _theme.onPlatformBrightnessChanged();

  @override
  void didChangeLocales(List<Locale>? locales) => _lang.onSystemLocaleChanged();

  void _rebuildAll() {
    setState(() {});
    void markDirty(Element el) {
      el.markNeedsBuild();
      el.visitChildren(markDirty);
    }
    (context as Element).visitChildren(markDirty);
  }

  void _onThemeChanged() {
    setState(() {});
    void markDirty(Element el) {
      el.markNeedsBuild();
      el.visitChildren(markDirty);
    }

    (context as Element).visitChildren(markDirty);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = AppTheme.brightness;
    final dark = brightness == Brightness.dark;
    return MaterialApp(
      title: 'ByeLui',
      theme: AppTheme.themeData(brightness),
      themeAnimationDuration: Duration.zero,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      locale: S.locale,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppTheme.paper,
          systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
      home: const AppLockGate(),
    );
  }
}

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
    final biometricEnabled = await BiometricService.isBiometricEnabled();
    if (mounted) setState(() => _needsUnlock = hasPin || biometricEnabled);
  }

  @override
  Widget build(BuildContext context) {
    if (_needsUnlock == null) {
      return Scaffold(backgroundColor: AppTheme.paper, body: SizedBox());
    }
    if (_needsUnlock == true) {
      return LockScreen(onUnlocked: () => setState(() => _needsUnlock = false));
    }
    return const HomeScreen();
  }
}
