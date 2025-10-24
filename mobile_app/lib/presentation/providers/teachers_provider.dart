import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/teacher.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Teachers state
class TeachersState {
  final List<TeacherModel> teachers;
  final bool isLoading;
  final String? error;

  TeachersState({
    this.teachers = const [],
    this.isLoading = false,
    this.error,
  });

  TeachersState copyWith({
    List<TeacherModel>? teachers,
    bool? isLoading,
    String? error,
  }) {
    return TeachersState(
      teachers: teachers ?? this.teachers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Teachers notifier
class TeachersNotifier extends StateNotifier<TeachersState> {
  final ApiClient _apiClient;

  TeachersNotifier(this._apiClient) : super(TeachersState()) {
    loadTeachers();
  }

  /// Load all teachers
  Future<void> loadTeachers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final teachers = await _apiClient.getTeachers();
      state = state.copyWith(
        teachers: teachers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh teachers
  Future<void> refresh() async {
    await loadTeachers();
  }
}

/// Teachers provider
final teachersProvider =
    StateNotifierProvider<TeachersNotifier, TeachersState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return TeachersNotifier(apiClient);
});
