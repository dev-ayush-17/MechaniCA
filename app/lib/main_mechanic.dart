import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'composition/providers.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/adapters/firebase_auth_service.dart';
import 'features/auth/domain/account_api.dart';
import 'features/mechanic_onboarding/presentation/mechanic_session_ticker.dart';
import 'l10n/app_localizations.dart';
import 'navigation/mechanic_route_names.dart';
import 'navigation/mechanic_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await initFirebaseIfConfigured(config, isMechanic: true);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0D),
    ),
  );
  runApp(
    ProviderScope(
      overrides: [
        accountIntentProvider.overrideWithValue(AccountIntent.mechanic),
        postOtpRouteProvider.overrideWithValue(MechanicRouteNames.splash),
        trackingRoleProvider.overrideWithValue('mechanic'),
      ],
      child: const MechUppMechanicApp(),
    ),
  );
}

class MechUppMechanicApp extends ConsumerWidget {
  const MechUppMechanicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mechanicSessionTickerProvider);
    return MaterialApp.router(
      title: 'MechUpp Mechanic',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      routerConfig: mechanicRouter,
    );
  }
}
