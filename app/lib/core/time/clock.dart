/// Source of time so tests can control it (docs/prd/08-port-catalog.md).
abstract interface class Clock {
  /// Current instant in UTC.
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration delta) => _now = _now.add(delta);
}
