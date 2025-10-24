import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/book_author.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Book Authors state
class BookAuthorsState {
  final List<BookAuthorModel> authors;
  final bool isLoading;
  final String? error;

  BookAuthorsState({
    this.authors = const [],
    this.isLoading = false,
    this.error,
  });

  BookAuthorsState copyWith({
    List<BookAuthorModel>? authors,
    bool? isLoading,
    String? error,
  }) {
    return BookAuthorsState(
      authors: authors ?? this.authors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Book Authors notifier
class BookAuthorsNotifier extends StateNotifier<BookAuthorsState> {
  final ApiClient _apiClient;

  BookAuthorsNotifier(this._apiClient) : super(BookAuthorsState()) {
    loadAuthors();
  }

  /// Load all book authors
  Future<void> loadAuthors() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final authors = await _apiClient.getBookAuthors();
      state = state.copyWith(
        authors: authors,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh authors
  Future<void> refresh() async {
    await loadAuthors();
  }
}

/// Book Authors provider
final bookAuthorsProvider =
    StateNotifierProvider<BookAuthorsNotifier, BookAuthorsState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return BookAuthorsNotifier(apiClient);
});
