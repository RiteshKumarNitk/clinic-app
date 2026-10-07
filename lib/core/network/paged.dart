import '../utils/json.dart';

/// One page of a server-side paginated collection.
class Paged<T> {
  const Paged({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;

  static Paged<T> fromJson<T>(Json json, T Function(Json) parse) => Paged(
    items: objList(json, 'data').map(parse).toList(growable: false),
    total: intOrNull(json, 'total') ?? 0,
    page: intOrNull(json, 'page') ?? 1,
    pageSize: intOrNull(json, 'pageSize') ?? 20,
  );
}
