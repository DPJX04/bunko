/// The one return type for every repository and service call.
///
/// Repositories and services return a [Result] instead of throwing, so the
/// caller has to handle failure. Because the class is sealed, a `switch`
/// over it must cover both [Ok] and [Err] or the code does not compile.
sealed class Result<T> {
  const Result();
}

/// A call that worked, holding its [data].
final class Ok<T> extends Result<T> {
  const Ok(this.data);

  final T data;
}

/// A call that failed, holding one readable sentence for the user.
final class Err<T> extends Result<T> {
  const Err(this.message);

  final String message;
}
