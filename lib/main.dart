import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/course_repository.dart';
import 'data/services/download_service.dart';
import 'data/services/storage_service.dart';
import 'ui/features/auth/login_screen.dart';
import 'ui/features/main/main_navigation_screen.dart';
import 'ui/viewmodels/auth_viewmodel.dart';
import 'ui/viewmodels/course_viewmodel.dart';
import 'ui/viewmodels/download_viewmodel.dart';
import 'ui/viewmodels/theme_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage
  final storageService = await StorageService.init();
  final downloadService = DownloadService();

  // Initialize repositories
  final authRepository = AuthRepository(storageService);
  final courseRepository = CourseRepository(storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseViewModel(courseRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => DownloadViewModel(
            storageService: storageService,
            downloadService: downloadService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeViewModel(storageService),
        ),
      ],
      child: const AbyssiniaELearningApp(),
    ),
  );
}

class AbyssiniaELearningApp extends StatelessWidget {
  const AbyssiniaELearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return MaterialApp(
      title: 'Abyssinia E-Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeVm.themeMode,
      home: authVm.isAuthenticated
          ? const MainNavigationScreen()
          : const LoginScreen(),
    );
  }
}
