import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../errors/api_exception.dart';
import '../network/paged.dart';
import 'state_views.dart';

/// Infinite-scrolling list over a server-paginated endpoint. Loads the next
/// page as the patient nears the end — works the same for 1 or 10,000 rows.
class PagedList<T> extends StatefulWidget {
  const PagedList({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    required this.empty,
    required this.errorMessage,
    this.header,
  });

  final Future<Paged<T>> Function(int page) fetch;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget empty;
  final String errorMessage;
  final Widget? header;

  @override
  State<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends State<PagedList<T>> {
  final _items = <T>[];
  final _scroll = ScrollController();
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _loadMore();
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await widget.fetch(_page + 1);
      if (!mounted) return;
      setState(() {
        _page = next.page;
        _items.addAll(next.items);
        _hasMore = next.hasMore && next.items.isNotEmpty;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      if (_error != null) {
        return ErrorView(
          message: friendlyMessage(_error!, fallback: widget.errorMessage),
          onRetry: _refresh,
        );
      }
      if (_loading || _hasMore) return const SkeletonList();
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.header != null) widget.header!,
            SizedBox(height: 420, child: widget.empty),
          ],
        ),
      );
    }

    final header = widget.header;
    final offset = header == null ? 0 : 1;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ClinicSpacing.gutter,
          ClinicSpacing.sm,
          ClinicSpacing.gutter,
          ClinicSpacing.xxl,
        ),
        itemCount: _items.length + offset + 1,
        separatorBuilder: (_, i) =>
            SizedBox(height: i < offset ? 0 : ClinicSpacing.md),
        itemBuilder: (context, i) {
          if (header != null && i == 0) return header;
          final index = i - offset;
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index]);
          }
          return _footer();
        },
      ),
    );
  }

  Widget _footer() {
    if (_error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadMore,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Couldn\'t load more. Try again'),
        ),
      );
    }
    if (_hasMore) {
      return const Padding(
        padding: EdgeInsets.all(ClinicSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }
    return const SizedBox(height: ClinicSpacing.lg);
  }
}
