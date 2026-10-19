/// Composition root: the one place that decides which adapter is live.
///
/// The demo's mock repository providers are re-exported unchanged so existing
/// screens keep working. Each feature milestone replaces its mock binding here.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/flags/feature_flags.dart';
import '../core/logging/logger.dart';
import '../core/time/clock.dart';

export '../providers/app_providers.dart';

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final loggerProvider = Provider<Logger>((ref) => const DeveloperLogger());

final featureFlagsProvider =
    Provider<FeatureFlags>((ref) => const StaticFeatureFlags());
