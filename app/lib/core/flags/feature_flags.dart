/// Named switches. Unknown flags are off (docs/prd/08-port-catalog.md).
abstract interface class FeatureFlags {
  bool isEnabled(String name, {String? userId});
}

/// Flags fixed at build or test time. A remote source can replace this later.
class StaticFeatureFlags implements FeatureFlags {
  const StaticFeatureFlags([this._flags = const {}]);

  final Map<String, bool> _flags;

  @override
  bool isEnabled(String name, {String? userId}) => _flags[name] ?? false;
}
