import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/series.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Series state
class SeriesState {
  final List<SeriesModel> seriesList;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final int? teacherFilter;
  final int? bookFilter;
  final int? themeFilter;
  final int? yearFilter;
  final bool? completedFilter;

  SeriesState({
    this.seriesList = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.teacherFilter,
    this.bookFilter,
    this.themeFilter,
    this.yearFilter,
    this.completedFilter,
  });

  SeriesState copyWith({
    List<SeriesModel>? seriesList,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? teacherFilter,
    int? bookFilter,
    int? themeFilter,
    int? yearFilter,
    bool? completedFilter,
    bool clearFilters = false,
  }) {
    return SeriesState(
      seriesList: seriesList ?? this.seriesList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
      teacherFilter: clearFilters ? null : (teacherFilter ?? this.teacherFilter),
      bookFilter: clearFilters ? null : (bookFilter ?? this.bookFilter),
      themeFilter: clearFilters ? null : (themeFilter ?? this.themeFilter),
      yearFilter: clearFilters ? null : (yearFilter ?? this.yearFilter),
      completedFilter: clearFilters ? null : (completedFilter ?? this.completedFilter),
    );
  }
}

/// Series notifier
class SeriesNotifier extends StateNotifier<SeriesState> {
  final ApiClient _apiClient;

  SeriesNotifier(this._apiClient) : super(SeriesState()) {
    loadSeries();
  }

  /// Load all series
  Future<void> loadSeries({
    String? search,
    int? teacherId,
    int? bookId,
    int? themeId,
    int? year,
    bool? isCompleted,
    bool clearFilters = false,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        searchQuery: search,
        teacherFilter: teacherId,
        bookFilter: bookId,
        themeFilter: themeId,
        yearFilter: year,
        completedFilter: isCompleted,
        clearFilters: clearFilters,
      );

      final series = await _apiClient.getSeries(
        search: state.searchQuery,
        teacherId: state.teacherFilter,
        bookId: state.bookFilter,
        themeId: state.themeFilter,
        year: state.yearFilter,
        isCompleted: state.completedFilter,
      );

      state = state.copyWith(
        seriesList: series,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search series
  Future<void> search(String query) async {
    await loadSeries(search: query.isEmpty ? null : query);
  }

  /// Filter by teacher
  Future<void> filterByTeacher(int? teacherId) async {
    await loadSeries(teacherId: teacherId);
  }

  /// Filter by book
  Future<void> filterByBook(int? bookId) async {
    await loadSeries(bookId: bookId);
  }

  /// Filter by theme
  Future<void> filterByTheme(int? themeId) async {
    await loadSeries(themeId: themeId);
  }

  /// Filter by year
  Future<void> filterByYear(int? year) async {
    await loadSeries(year: year);
  }

  /// Filter by completion status
  Future<void> filterByCompleted(bool? isCompleted) async {
    await loadSeries(isCompleted: isCompleted);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await loadSeries(clearFilters: true);
  }

  /// Refresh series
  Future<void> refresh() async {
    await loadSeries();
  }
}

/// Series provider
final seriesProvider =
    StateNotifierProvider<SeriesNotifier, SeriesState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return SeriesNotifier(apiClient);
});
