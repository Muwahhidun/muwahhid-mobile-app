import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/series.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Series state
class SeriesState {
  final List<SeriesModel> seriesList;
  final bool isLoading;
  final String? error;

  SeriesState({
    this.seriesList = const [],
    this.isLoading = false,
    this.error,
  });

  SeriesState copyWith({
    List<SeriesModel>? seriesList,
    bool? isLoading,
    String? error,
  }) {
    return SeriesState(
      seriesList: seriesList ?? this.seriesList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
  Future<void> loadSeries() async {
    try {
      print('🔄 SeriesProvider: Starting to load series...');
      state = state.copyWith(isLoading: true, error: null);

      print('📡 SeriesProvider: Calling API getSeries()...');
      final series = await _apiClient.getSeries();

      print('✅ SeriesProvider: Got ${series.length} series from API');
      print('🔍 SeriesProvider: Series data: ${series.map((s) => 'id=${s.id}, isActive=${s.isActive}, isCompleted=${s.isCompleted}').join('; ')}');

      state = state.copyWith(
        seriesList: series,
        isLoading: false,
      );
      print('✅ SeriesProvider: State updated successfully');
    } catch (e, stackTrace) {
      print('❌ SeriesProvider: ERROR CAUGHT!');
      print('❌ Error: $e');
      print('❌ StackTrace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
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
