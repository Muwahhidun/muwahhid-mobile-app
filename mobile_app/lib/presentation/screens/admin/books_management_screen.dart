import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/book_authors_provider.dart';

class BooksManagementScreen extends ConsumerStatefulWidget {
  const BooksManagementScreen({super.key});

  @override
  ConsumerState<BooksManagementScreen> createState() =>
      _BooksManagementScreenState();
}

class _BooksManagementScreenState extends ConsumerState<BooksManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final booksState = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление книгами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showBookDialog(context),
          ),
        ],
      ),
      body: booksState.isLoading && booksState.books.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : booksState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${booksState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(booksProvider.notifier).refresh(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : booksState.books.isEmpty
          ? const Center(child: Text('Нет книг'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: booksState.books.length,
              itemBuilder: (context, index) {
                final book = booksState.books[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      book.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (book.description != null) ...[
                          const SizedBox(height: 4),
                          Text(book.description!),
                        ],
                        if (book.theme != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Тема: ${book.theme!.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (book.author != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Автор: ${book.author!.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Активна: ${(book.isActive ?? false) ? "Да" : "Нет"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showBookDialog(context, book: book),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, book),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showBookDialog(BuildContext context, {BookModel? book}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookFormDialog(book: book),
    );

    // Refresh list if book was created or updated
    if (result == true) {
      await ref.read(booksProvider.notifier).refresh();
    }
  }

  void _confirmDelete(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text('Вы уверены, что хотите удалить "${book.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBook(book.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook(int bookId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteBook(bookId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Книга удалена')));
        await ref.read(booksProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}

/// Book form dialog
class BookFormDialog extends ConsumerStatefulWidget {
  final BookModel? book;

  const BookFormDialog({super.key, this.book});

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  int? _selectedThemeId;
  int? _selectedAuthorId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.book?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.book?.description ?? '',
    );
    _isActive = widget.book?.isActive ?? true;
    _selectedThemeId = widget.book?.themeId;
    _selectedAuthorId = widget.book?.authorId;

    // Load themes and authors only if not already loaded
    Future.microtask(() {
      final themesState = ref.read(themesProvider);
      final authorsState = ref.read(bookAuthorsProvider);

      if (themesState.themes.isEmpty && !themesState.isLoading) {
        ref.read(themesProvider.notifier).loadThemes();
      }
      if (authorsState.authors.isEmpty && !authorsState.isLoading) {
        ref.read(bookAuthorsProvider.notifier).loadAuthors();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themesState = ref.watch(themesProvider);
    final authorsState = ref.watch(bookAuthorsProvider);

    return AlertDialog(
      title: Text(widget.book == null ? 'Новая книга' : 'Редактировать книгу'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Theme dropdown
                DropdownButtonFormField<int>(
                  value: themesState.isLoading
                      ? null
                      : (themesState.themes.any((t) => t.id == _selectedThemeId)
                            ? _selectedThemeId
                            : null),
                  decoration: const InputDecoration(
                    labelText: 'Тема',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Без темы'),
                    ),
                    ...themesState.themes.map((theme) {
                      return DropdownMenuItem<int>(
                        value: theme.id,
                        child: Text(theme.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedThemeId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Author dropdown
                DropdownButtonFormField<int>(
                  value: authorsState.isLoading
                      ? null
                      : (authorsState.authors.any(
                              (a) => a.id == _selectedAuthorId,
                            )
                            ? _selectedAuthorId
                            : null),
                  decoration: const InputDecoration(
                    labelText: 'Автор',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Без автора'),
                    ),
                    ...authorsState.authors.map((author) {
                      return DropdownMenuItem<int>(
                        value: author.id,
                        child: Text(author.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAuthorId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Active switch
                SwitchListTile(
                  title: const Text('Активна'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.book == null ? 'Создать' : 'Сохранить'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());

      final bookData = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'theme_id': _selectedThemeId,
        'author_id': _selectedAuthorId,
        'is_active': _isActive,
        'sort_order': 0,
      };

      if (widget.book != null) {
        // Update existing book
        await apiClient.updateBook(widget.book!.id, bookData);
      } else {
        // Create new book
        await apiClient.createBook(bookData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.book != null ? 'Книга обновлена' : 'Книга создана',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
