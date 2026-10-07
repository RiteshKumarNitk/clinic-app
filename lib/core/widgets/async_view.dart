import 'package:flutter/material.dart';

import '../errors/api_exception.dart';
import 'state_views.dart';

/// Loads a future and renders loading / error / data, with retry and
/// pull-to-refresh hooks. Keeps every screen's state handling identical.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    required this.errorMessage,
    this.loading,
  });

  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;

  /// What the patient reads when loading fails, e.g. "We couldn't load clinics."
  final String errorMessage;
  final Widget? loading;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future = widget.load();

  Future<void> _reload() async {
    final next = widget.load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return widget.loading ?? const CityCareLoading();
        }
        if (snap.hasError) {
          return CityCareErrorState(
            message: friendlyMessage(
              snap.error!,
              fallback: widget.errorMessage,
            ),
            onRetry: _reload,
          );
        }
        return widget.builder(context, snap.data as T, _reload);
      },
    );
  }
}
