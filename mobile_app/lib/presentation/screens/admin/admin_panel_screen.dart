import 'package:flutter/material.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Администрирование'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Блок: Управление контентом
          Text(
            'Управление контентом',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.category,
            title: 'Темы',
            subtitle: 'Управление темами уроков',
            color: Colors.blue,
            onTap: () {
              Navigator.pushNamed(context, '/admin/themes');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.book,
            title: 'Книги',
            subtitle: 'Управление книгами',
            color: Colors.orange,
            onTap: () {
              Navigator.pushNamed(context, '/admin/books');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.person_outline,
            title: 'Авторы',
            subtitle: 'Управление авторами книг',
            color: Colors.brown,
            onTap: () {
              Navigator.pushNamed(context, '/admin/authors');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.school,
            title: 'Преподаватели',
            subtitle: 'Управление преподавателями',
            color: Colors.purple,
            onTap: () {
              Navigator.pushNamed(context, '/admin/teachers');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.collections_bookmark,
            title: 'Серии',
            subtitle: 'Управление сериями уроков',
            color: Colors.teal,
            onTap: () {
              Navigator.pushNamed(context, '/admin/series');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.headset,
            title: 'Уроки',
            subtitle: 'Управление аудио уроками',
            color: Colors.purple,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В разработке')),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.school,
            title: 'Тесты',
            subtitle: 'Управление тестами',
            color: Colors.red,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В разработке')),
              );
            },
          ),

          // Блок: Общая информация
          const SizedBox(height: 32),
          Text(
            'Общая информация',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.people,
            title: 'Управление пользователями',
            subtitle: 'Роли, блокировка, удаление',
            color: Colors.indigo,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В разработке')),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.mail_outline,
            title: 'Обращения',
            subtitle: 'Сообщения от пользователей',
            color: Colors.amber,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В разработке')),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.bar_chart,
            title: 'Статистика',
            subtitle: 'Общая статистика по контенту',
            color: Colors.cyan,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В разработке')),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.help_outline,
            title: 'Справка',
            subtitle: 'Инструкция для администраторов',
            color: Colors.blueGrey,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В разработке')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
