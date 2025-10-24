import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/theme.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Themes state
class ThemesState {
  final List<AppThemeModel> themes;
  final bool isLoading;
  final String? error;

  ThemesState({
    this.themes = const [],
    this.isLoading = false,
    this.error,
  });

  ThemesState copyWith({
    List<AppThemeModel>? themes,
    bool? isLoading,
    String? error,
  }) {
    return ThemesState(
      themes: themes ?? this.themes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Themes notifier
class ThemesNotifier extends StateNotifier<ThemesState> {
  final ApiClient _apiClient;

  ThemesNotifier(this._apiClient) : super(ThemesState()) {
    loadThemes();
  }

  /// Load all themes
  Future<void> loadThemes() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final themes = await _apiClient.getThemes();
      state = state.copyWith(
        themes: themes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh themes
  Future<void> refresh() async {
    await loadThemes();
  }
}

/// Themes provider
final themesProvider = StateNotifierProvider<ThemesNotifier, ThemesState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return ThemesNotifier(apiClient);
});
