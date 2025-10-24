import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/teacher.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';
import '../../providers/teachers_provider.dart';

class TeachersManagementScreen extends ConsumerStatefulWidget {
  const TeachersManagementScreen({super.key});

  @override
  ConsumerState<TeachersManagementScreen> createState() =>
      _TeachersManagementScreenState();
}

class _TeachersManagementScreenState
    extends ConsumerState<TeachersManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final teachersState = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление преподавателями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTeacherDialog(context),
          ),
        ],
      ),
      body: teachersState.isLoading && teachersState.teachers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : teachersState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: ${teachersState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(teachersProvider.notifier).refresh(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : teachersState.teachers.isEmpty
                  ? const Center(child: Text('Нет преподавателей'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: teachersState.teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = teachersState.teachers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              teacher.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (teacher.biography != null) ...[
                                  const SizedBox(height: 4),
                                  Text(teacher.biography!),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Активен: ${teacher.isActive ? "Да" : "Нет"}',
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
                                      _showTeacherDialog(context, teacher: teacher),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmDelete(context, teacher),
                                ),
                              ],
                            ),
                            isThreeLine: teacher.biography != null,
                          ),
                        );
                      },
                    ),
    );
  }

  Future<void> _showTeacherDialog(BuildContext context,
      {TeacherModel? teacher}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TeacherFormDialog(teacher: teacher),
    );

    // Refresh list if teacher was created or updated
    if (result == true) {
      await ref.read(teachersProvider.notifier).refresh();
    }
  }

  void _confirmDelete(BuildContext context, TeacherModel teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить преподавателя?'),
        content: Text('Вы уверены, что хотите удалить "${teacher.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTeacher(teacher.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTeacher(int teacherId) async {
    try {
      final apiClient = ApiClient(DioProvider.getDio());
      await apiClient.deleteTeacher(teacherId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Преподаватель удалён')),
        );
        await ref.read(teachersProvider.notifier).refresh();
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

/// Teacher form dialog
class TeacherFormDialog extends ConsumerStatefulWidget {
  final TeacherModel? teacher;

  const TeacherFormDialog({super.key, this.teacher});

  @override
  ConsumerState<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends ConsumerState<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _biographyController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher?.name ?? '');
    _biographyController =
        TextEditingController(text: widget.teacher?.biography ?? '');
    _isActive = widget.teacher?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher == null ? 'Новый преподаватель' : 'Редактировать преподавателя'),
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
                    labelText: 'Имя преподавателя',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите имя преподавателя';
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
              : Text(widget.teacher == null ? 'Создать' : 'Сохранить'),
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

      final teacherData = {
        'name': _nameController.text,
        'biography': _biographyController.text.isEmpty
            ? null
            : _biographyController.text,
        'is_active': _isActive,
      };

      if (widget.teacher != null) {
        // Update existing teacher
        await apiClient.updateTeacher(widget.teacher!.id, teacherData);
      } else {
        // Create new teacher
        await apiClient.createTeacher(teacherData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.teacher != null ? 'Преподаватель обновлён' : 'Преподаватель создан'),
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
