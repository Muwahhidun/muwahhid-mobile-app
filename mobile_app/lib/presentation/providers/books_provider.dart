import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/book.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// Books state
class BooksState {
  final List<BookModel> books;
  final bool isLoading;
  final String? error;

  BooksState({
    this.books = const [],
    this.isLoading = false,
    this.error,
  });

  BooksState copyWith({
    List<BookModel>? books,
    bool? isLoading,
    String? error,
  }) {
    return BooksState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Books notifier
class BooksNotifier extends StateNotifier<BooksState> {
  final ApiClient _apiClient;

  BooksNotifier(this._apiClient) : super(BooksState()) {
    loadBooks();
  }

  /// Load all books
  Future<void> loadBooks() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final books = await _apiClient.getBooks();
      state = state.copyWith(
        books: books,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh books
  Future<void> refresh() async {
    await loadBooks();
  }
}

/// Books provider
final booksProvider = StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return BooksNotifier(apiClient);
});
