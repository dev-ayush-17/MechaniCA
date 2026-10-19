/// Expected failures are values, not exceptions (docs/prd/22-coding-standards.md).
sealed class Result<T> {
  const Result();

  /// Returns [onOk] for success or [onErr] for failure.
  R when<R>({
    required R Function(T value) onOk,
    required R Function(AppFailure failure) onErr,
  }) {
    final self = this;
    return switch (self) {
      Ok<T>() => onOk(self.value),
      Err<T>() => onErr(self.failure),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}

/// Shared failure types from docs/prd/08-port-catalog.md.
sealed class AppFailure {
  const AppFailure(this.message);

  /// Safe to show to a user.
  final String message;
}

final class NotFound extends AppFailure {
  const NotFound([super.message = 'We could not find that.']);
}

final class PermissionDenied extends AppFailure {
  const PermissionDenied([super.message = 'You do not have access to that.']);
}

final class InvalidInput extends AppFailure {
  const InvalidInput(super.message, {this.fields = const {}});

  /// Field name to message.
  final Map<String, String> fields;
}

final class Conflict extends AppFailure {
  const Conflict(super.message, {required this.code});

  /// Stable API error code, for example `invalid_transition`.
  final String code;
}

final class Unavailable extends AppFailure {
  const Unavailable([super.message = 'Service is unavailable. Try again.']);
}

final class Unauthenticated extends AppFailure {
  const Unauthenticated([super.message = 'Sign in again.']);
}
