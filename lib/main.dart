import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import 'core/core.dart';
import 'core/config/paymob_config.dart';
import 'core/di/injection_container.dart';
import 'core/routing/app_router.dart';
import 'core/services/theme_service.dart';
import 'features/payment/data/services/paymob_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DEVELOPMENT ONLY: Allow self-signed certificates
  // Remove this in production!
  if (kDebugMode) {
    HttpOverrides.global = _DevHttpOverrides();
  }

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Supabase with error handling
  try {
    await SupabaseServiceImpl.instance.initialize();
  } catch (e) {
    debugPrint('⚠️ [Main] Failed to initialize Supabase: $e');
    // Continue app initialization even if Supabase fails
    // User will see error when trying to use features that need Supabase
  }

  // Initialize Dependencies
  await initDependencies();

  // Initialize Paymob (only if configured)
  if (PaymobConfig.isConfigured) {
    await PaymobService.initialize(
      apiKey: PaymobConfig.apiKey,
      integrationId: PaymobConfig.integrationId,
      iFrameId: PaymobConfig.iFrameId,
      walletIntegrationId: PaymobConfig.walletIntegrationId,
    );
    debugPrint('✅ [Main] Paymob initialized successfully');
  }

  // Initialize Theme Service
  await ThemeService.instance.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const MyApp(),
    ),
  );
}

// DEVELOPMENT ONLY: Allow self-signed certificates
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDarkMode,
      builder: (context, isDark, _) {
        return ToastificationWrapper(
          child: MaterialApp.router(
            title: 'app_name'.tr(),
            debugShowCheckedModeBanner: false,
            // Disable stretch/glow overscroll indicator globally.
            // This avoids _StretchController assertions seen on some Android ROMs (e.g. MIUI).
            scrollBehavior:
                const MaterialScrollBehavior().copyWith(overscroll: false),
            // Localization
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            // Router
            routerConfig: AppRouter.router,
            // Builder for RTL support
            builder: (context, child) {
              return Directionality(
                textDirection: context.locale.languageCode == 'ar'
                    ? ui.TextDirection.rtl
                    : ui.TextDirection.ltr,
                child: child ?? const SizedBox(),
              );
            },
          ),
        );
      },
    );
  }
}
