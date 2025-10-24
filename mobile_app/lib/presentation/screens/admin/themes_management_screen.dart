import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../providers/themes_provider.dart';

class ThemesManagementScreen extends ConsumerStatefulWidget {
  const ThemesManagementScreen({super.key});

  @override
  ConsumerState<ThemesManagementScreen> createState() =>
      _ThemesManagementScreenState();
}

class _ThemesManagementScreenState
    extends ConsumerState<ThemesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final themesState = ref.watch(themesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление темами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showThemeDialog(context),
          ),
        ],
      ),
      body: themesState.isLoading && themesState.themes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : themesState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: ${themesState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(themesProvider.notifier).refresh(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : themesState.themes.isEmpty
                  ? const Center(child: Text('Нет тем'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: themesState.themes.length,
                      itemBuilder: (context, index) {
                        final theme = themesState.themes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              theme.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (theme.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(theme.description!),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Активна: ${theme.isActive ? "Да" : "Нет"}',
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
                                  onPressed: () => _showThemeDialog(context, theme: theme),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(context, theme),
                                ),
                              ],
                            ),
                            isThreeLine: theme.description != null,
                          ),
                        );
                      },
                    ),
    );
  }

  Future<void> _showThemeDialog(BuildContext context, {AppThemeModel? theme}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ThemeFormDialog(theme: theme),
    );

    // Refresh list if theme was created or updated
    if (result == true) {
      await ref.read(themesProvider.notifier).refresh();
    }
  }

  void _confirmDelete(BuildContext context, AppThemeModel theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тему?'),
        content: Text('Вы уверены, что хотите удалить тему "${theme.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTheme(theme.id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTheme(int themeId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteTheme(themeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тема удалена')),
        );
        await ref.read(themesProvider.notifier).refresh();
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

class ThemeFormDialog extends StatefulWidget {
  final AppThemeModel? theme;

  const ThemeFormDialog({super.key, this.theme});

  @override
  State<ThemeFormDialog> createState() => _ThemeFormDialogState();
}

class _ThemeFormDialogState extends State<ThemeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.theme?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.theme?.description ?? '');
    _isActive = widget.theme?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.theme != null;

    return AlertDialog(
      title: Text(isEdit ? 'Редактировать тему' : 'Создать тему'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Сохранить' : 'Создать'),
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

      final themeData = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'is_active': _isActive,
        'sort_order': 0,
      };

      if (widget.theme != null) {
        // Update existing theme
        await apiClient.updateTheme(widget.theme!.id, themeData);
      } else {
        // Create new theme
        await apiClient.createTheme(themeData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.theme != null ? 'Тема обновлена' : 'Тема создана',
            ),
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
