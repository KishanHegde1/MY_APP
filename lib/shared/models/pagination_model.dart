final class PaginationModel {
  const PaginationModel({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, Object?> json) {
    return PaginationModel(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

final class PaginatedList<T> {
  const PaginatedList({required this.items, required this.pagination});
  final List<T> items;
  final PaginationModel pagination;
}
