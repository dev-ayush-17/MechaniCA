import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'composition/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/account_api.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'l10n/app_localizations.dart';
import 'navigation/mechanic_route_names.dart';
import 'navigation/mechanic_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        postOtpRouteProvider.overrideWithValue(MechanicRouteNames.home),
      ],
      child: const MechUppMechanicApp(),
    ),
  );
}

class MechUppMechanicApp extends StatelessWidget {
  const MechUppMechanicApp({super.key});

  @override
  Widget build(BuildContext context) {
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
