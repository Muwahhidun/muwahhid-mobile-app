import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/series.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/teachers_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/themes_provider.dart';

class SeriesManagementScreen extends ConsumerStatefulWidget {
  const SeriesManagementScreen({super.key});

  @override
  ConsumerState<SeriesManagementScreen> createState() =>
      _SeriesManagementScreenState();
}

class _SeriesManagementScreenState
    extends ConsumerState<SeriesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление сериями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSeriesDialog(context),
          ),
        ],
      ),
      body: seriesState.isLoading && seriesState.seriesList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : seriesState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: ${seriesState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(seriesProvider.notifier).refresh(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : seriesState.seriesList.isEmpty
                  ? const Center(child: Text('Нет серий'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: seriesState.seriesList.length,
                      itemBuilder: (context, index) {
                        final series = seriesState.seriesList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              series.displayName ?? '${series.year} - ${series.name}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (series.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(series.description!),
                                ],
                                const SizedBox(height: 4),
                                if (series.teacher != null)
                                  Text('Преподаватель: ${series.teacher!.name}'),
                                if (series.book != null)
                                  Text('Книга: ${series.book!.name}'),
                                if (series.theme != null)
                                  Text('Тема: ${series.theme!.name}'),
                                Text(
                                  'Завершена: ${series.isCompleted ? "Да" : "Нет"} | Активна: ${series.isActive ? "Да" : "Нет"}',
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
                                      _showSeriesDialog(context, series: series),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmDelete(context, series),
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

  Future<void> _showSeriesDialog(BuildContext context,
      {SeriesModel? series}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SeriesFormDialog(series: series),
    );

    // Refresh list if series was created or updated
    if (result == true) {
      await ref.read(seriesProvider.notifier).refresh();
    }
  }

  void _confirmDelete(BuildContext context, SeriesModel series) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить серию?'),
        content: Text('Вы уверены, что хотите удалить "${series.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSeries(series.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSeries(int seriesId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteSeries(seriesId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Серия удалена')),
        );
        await ref.read(seriesProvider.notifier).refresh();
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

/// Series form dialog
class SeriesFormDialog extends ConsumerStatefulWidget {
  final SeriesModel? series;

  const SeriesFormDialog({super.key, this.series});

  @override
  ConsumerState<SeriesFormDialog> createState() => _SeriesFormDialogState();
}

class _SeriesFormDialogState extends ConsumerState<SeriesFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _orderController;
  int? _selectedTeacherId;
  int? _selectedBookId;
  int? _selectedThemeId;
  late bool _isCompleted;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.series?.name ?? '');
    _yearController = TextEditingController(text: widget.series?.year.toString() ?? '');
    _descriptionController =
        TextEditingController(text: widget.series?.description ?? '');
    _orderController = TextEditingController(text: widget.series?.order.toString() ?? '0');
    _selectedTeacherId = widget.series?.teacherId;
    _selectedBookId = widget.series?.bookId;
    _selectedThemeId = widget.series?.themeId;
    _isCompleted = widget.series?.isCompleted ?? false;
    _isActive = widget.series?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teachersState = ref.watch(teachersProvider);
    final booksState = ref.watch(booksProvider);
    final themesState = ref.watch(themesProvider);

    return AlertDialog(
      title: Text(widget.series == null ? 'Новая серия' : 'Редактировать серию'),
      content: SizedBox(
        width: 600,
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
                    labelText: 'Название серии *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название серии';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Year field
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'Год *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите год';
                    }
                    final year = int.tryParse(value);
                    if (year == null) {
                      return 'Введите корректный год';
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

                // Teacher dropdown
                DropdownButtonFormField<int>(
                  value: _selectedTeacherId,
                  decoration: const InputDecoration(
                    labelText: 'Преподаватель *',
                    border: OutlineInputBorder(),
                  ),
                  items: teachersState.teachers.map((teacher) {
                    return DropdownMenuItem<int>(
                      value: teacher.id,
                      child: Text(teacher.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTeacherId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Выберите преподавателя';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Book dropdown
                DropdownButtonFormField<int>(
                  value: _selectedBookId,
                  decoration: const InputDecoration(
                    labelText: 'Книга (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Не выбрано'),
                    ),
                    ...booksState.books.map((book) {
                      return DropdownMenuItem<int>(
                        value: book.id,
                        child: Text(book.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBookId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Theme dropdown
                DropdownButtonFormField<int>(
                  value: _selectedThemeId,
                  decoration: const InputDecoration(
                    labelText: 'Тема (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Не выбрано'),
                    ),
                    ...themesState.themes.map((theme) {
                      return DropdownMenuItem<int>(
                        value: theme.id,
                        child: Text(theme.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedThemeId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Order field
                TextFormField(
                  controller: _orderController,
                  decoration: const InputDecoration(
                    labelText: 'Порядок',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final order = int.tryParse(value);
                      if (order == null) {
                        return 'Введите корректное число';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Is completed switch
                SwitchListTile(
                  title: const Text('Серия завершена'),
                  value: _isCompleted,
                  onChanged: (value) {
                    setState(() {
                      _isCompleted = value;
                    });
                  },
                ),

                // Is active switch
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
              : Text(widget.series == null ? 'Создать' : 'Сохранить'),
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

      final seriesData = {
        'name': _nameController.text,
        'year': int.parse(_yearController.text),
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'teacher_id': _selectedTeacherId!,
        'book_id': _selectedBookId,
        'theme_id': _selectedThemeId,
        'order': int.parse(_orderController.text),
        'is_completed': _isCompleted,
        'is_active': _isActive,
      };

      if (widget.series != null) {
        // Update existing series
        await apiClient.updateSeries(widget.series!.id, seriesData);
      } else {
        // Create new series
        await apiClient.createSeries(seriesData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.series != null ? 'Серия обновлена' : 'Серия создана'),
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
