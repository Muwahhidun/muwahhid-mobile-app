import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book_author.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../providers/book_authors_provider.dart';

class BookAuthorsManagementScreen extends ConsumerStatefulWidget {
  const BookAuthorsManagementScreen({super.key});

  @override
  ConsumerState<BookAuthorsManagementScreen> createState() =>
      _BookAuthorsManagementScreenState();
}

class _BookAuthorsManagementScreenState
    extends ConsumerState<BookAuthorsManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final authorsState = ref.watch(bookAuthorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление авторами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAuthorDialog(context),
          ),
        ],
      ),
      body: authorsState.isLoading && authorsState.authors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : authorsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: ${authorsState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(bookAuthorsProvider.notifier).refresh(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : authorsState.authors.isEmpty
                  ? const Center(child: Text('Нет авторов'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: authorsState.authors.length,
                      itemBuilder: (context, index) {
                        final author = authorsState.authors[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              author.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (author.biography != null) ...[
                                  const SizedBox(height: 4),
                                  Text(author.biography!),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  '${author.birthYear != null ? "${author.birthYear}" : "?"} - ${author.deathYear != null ? "${author.deathYear}" : "?"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Активен: ${author.isActive ? "Да" : "Нет"}',
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
                                  icon:
                                      const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () =>
                                      _showAuthorDialog(context, author: author),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmDelete(context, author),
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

  Future<void> _showAuthorDialog(BuildContext context,
      {BookAuthorModel? author}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AuthorFormDialog(author: author),
    );

    // Refresh list if author was created or updated
    if (result == true) {
      await ref.read(bookAuthorsProvider.notifier).refresh();
    }
  }

  void _confirmDelete(BuildContext context, BookAuthorModel author) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автора?'),
        content: Text('Вы уверены, что хотите удалить "${author.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAuthor(author.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAuthor(int authorId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteBookAuthor(authorId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Автор удалён')),
        );
        await ref.read(bookAuthorsProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}

/// Author form dialog
class AuthorFormDialog extends ConsumerStatefulWidget {
  final BookAuthorModel? author;

  const AuthorFormDialog({super.key, this.author});

  @override
  ConsumerState<AuthorFormDialog> createState() => _AuthorFormDialogState();
}

class _AuthorFormDialogState extends ConsumerState<AuthorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _biographyController;
  late final TextEditingController _birthYearController;
  late final TextEditingController _deathYearController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.author?.name ?? '');
    _biographyController =
        TextEditingController(text: widget.author?.biography ?? '');
    _birthYearController = TextEditingController(
        text: widget.author?.birthYear?.toString() ?? '');
    _deathYearController = TextEditingController(
        text: widget.author?.deathYear?.toString() ?? '');
    _isActive = widget.author?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _biographyController.dispose();
    _birthYearController.dispose();
    _deathYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.author == null ? 'Новый автор' : 'Редактировать автора'),
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
                    labelText: 'Имя автора',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите имя автора';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Biography field
                TextFormField(
                  controller: _biographyController,
                  decoration: const InputDecoration(
                    labelText: 'Биография (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Birth year field
                TextFormField(
                  controller: _birthYearController,
                  decoration: const InputDecoration(
                    labelText: 'Год рождения (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final year = int.tryParse(value);
                      if (year == null || year < 0 || year > 2100) {
                        return 'Введите корректный год';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Death year field
                TextFormField(
                  controller: _deathYearController,
                  decoration: const InputDecoration(
                    labelText: 'Год смерти (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final year = int.tryParse(value);
                      if (year == null || year < 0 || year > 2100) {
                        return 'Введите корректный год';
                      }
                      // Check death year is after birth year
                      final birthYear = int.tryParse(_birthYearController.text);
                      if (birthYear != null && year < birthYear) {
                        return 'Год смерти не может быть раньше года рождения';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Active switch
                SwitchListTile(
                  title: const Text('Активен'),
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
              : Text(widget.author == null ? 'Создать' : 'Сохранить'),
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

      final authorData = {
        'name': _nameController.text,
        'biography': _biographyController.text.isEmpty
            ? null
            : _biographyController.text,
        'birth_year': _birthYearController.text.isEmpty
            ? null
            : int.parse(_birthYearController.text),
        'death_year': _deathYearController.text.isEmpty
            ? null
            : int.parse(_deathYearController.text),
        'is_active': _isActive,
      };

      if (widget.author != null) {
        // Update existing author
        await apiClient.updateBookAuthor(widget.author!.id, authorData);
      } else {
        // Create new author
        await apiClient.createBookAuthor(authorData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.author != null ? 'Автор обновлён' : 'Автор создан'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
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
