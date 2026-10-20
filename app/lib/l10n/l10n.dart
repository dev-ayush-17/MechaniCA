import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Falls back to English when the widget is pumped without delegates.
AppLocalizations l10nOf(BuildContext context) =>
    AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('en'));
