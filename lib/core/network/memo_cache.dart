/// Tiny in-memory cache for repository reads.
///
/// * Repeat reads within [ttl] return the cached value with no network call.
/// * Concurrent reads of the same key share one in-flight request.
/// * Failures are never cached.
class MemoCache<T> {
  MemoCache({required this.ttl, this.maxEntries = 100});

  final Duration ttl;
  final int maxEntries;

  final _values = <String, (DateTime, T)>{};
  final _inFlight = <String, Future<T>>{};

  Future<T> get(String key, Future<T> Function() load, {bool refresh = false}) {
    if (!refresh) {
      final hit = _values[key];
      if (hit != null && DateTime.now().difference(hit.$1) < ttl) {
        return Future.value(hit.$2);
      }
      final pending = _inFlight[key];
      if (pending != null) return pending;
    }
    final future = load().then((value) {
      if (_values.length >= maxEntries) _values.remove(_values.keys.first);
      _values[key] = (DateTime.now(), value);
      return value;
    });
    _inFlight[key] = future;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  void clear() {
    _values.clear();
    _inFlight.clear();
  }
}
