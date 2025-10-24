import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/admin/admin_panel_screen.dart';
import 'presentation/screens/admin/themes_management_screen.dart';
import 'presentation/screens/admin/books_management_screen.dart';
import 'presentation/screens/admin/book_authors_management_screen.dart';
import 'presentation/screens/admin/teachers_management_screen.dart';
import 'presentation/screens/admin/series_management_screen.dart';
import 'presentation/screens/themes/themes_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Islamic Audio Lessons',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: authState.isAuthenticated ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/admin': (context) => const AdminPanelScreen(),
        '/admin/themes': (context) => const ThemesManagementScreen(),
        '/admin/books': (context) => const BooksManagementScreen(),
        '/admin/authors': (context) => const BookAuthorsManagementScreen(),
        '/admin/teachers': (context) => const TeachersManagementScreen(),
        '/admin/series': (context) => const SeriesManagementScreen(),
        '/themes': (context) => const ThemesScreen(),
      },
    );
  }
}
