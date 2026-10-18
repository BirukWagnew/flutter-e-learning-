import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:elearning_app/data/models/course_model.dart';
import 'package:elearning_app/data/models/chapter_model.dart';
import 'package:elearning_app/data/models/lesson_model.dart';
import 'package:elearning_app/data/models/download_item.dart';
import 'package:elearning_app/data/models/user_model.dart';
import 'package:elearning_app/data/repositories/auth_repository.dart';
import 'package:elearning_app/data/repositories/course_repository.dart';
import 'package:elearning_app/data/services/app_path_service.dart';
import 'package:elearning_app/data/services/download_service.dart';
import 'package:elearning_app/data/services/storage_service.dart';
import 'package:elearning_app/ui/features/auth/login_screen.dart';
import 'package:elearning_app/ui/viewmodels/auth_viewmodel.dart';
import 'package:elearning_app/ui/viewmodels/course_viewmodel.dart';
import 'package:elearning_app/ui/viewmodels/download_viewmodel.dart';
import 'package:elearning_app/ui/viewmodels/theme_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Data Models Tests', () {
    test('CourseModel correctly parses chapters and calculates lesson counts', () {
      final jsonMap = {
        'id': 'c1',
        'title': 'Test Course',
        'description': 'Description',
        'instructor': 'Instructor Name',
        'instructorTitle': 'Lead Dev',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'accentColor': '#6366F1',
        'category': 'Mobile Development',
        'level': 'Intermediate',
        'rating': 4.9,
        'totalDuration': '20m',
        'chapters': [
          {
            'id': 'ch1',
            'title': 'Chapter 1',
            'description': 'Desc 1',
            'order': 1,
            'lessons': [
              {
                'id': 'l1',
                'title': 'Lesson 1',
                'duration': '05:00',
                'videoUrl': 'https://example.com/v1.mp4',
                'description': 'L1 desc',
                'order': 1,
              },
              {
                'id': 'l2',
                'title': 'Lesson 2',
                'duration': '06:00',
                'videoUrl': 'https://example.com/v2.mp4',
                'description': 'L2 desc',
                'order': 2,
              },
            ],
          },
          {
            'id': 'ch2',
            'title': 'Chapter 2',
            'description': 'Desc 2',
            'order': 2,
            'lessons': [
              {
                'id': 'l3',
                'title': 'Lesson 3',
                'duration': '07:00',
                'videoUrl': 'https://example.com/v3.mp4',
                'description': 'L3 desc',
                'order': 1,
              },
              {
                'id': 'l4',
                'title': 'Lesson 4',
                'duration': '08:00',
                'videoUrl': 'https://example.com/v4.mp4',
                'description': 'L4 desc',
                'order': 2,
              },
            ],
          },
        ],
      };

      final course = CourseModel.fromJson(jsonMap);

      expect(course.id, equals('c1'));
      expect(course.title, equals('Test Course'));
      expect(course.chapters.length, equals(2));
      expect(course.totalLessonsCount, equals(4));
      expect(course.allLessons.length, equals(4));
    });

    test('DownloadItem formatted size and progress calculations', () {
      final item = DownloadItem(
        lessonId: 'l1',
        courseId: 'c1',
        courseTitle: 'Flutter Mastery',
        lessonTitle: 'Intro to Flutter',
        duration: '05:12',
        videoUrl: 'https://example.com/v.mp4',
        localFilePath: '/data/user/0/downloads/l1.mp4',
        totalBytes: 15 * 1024 * 1024, // 15 MB
        downloadedBytes: 7 * 1024 * 1024,
        progress: 0.50,
        status: DownloadStatus.downloading,
        downloadedAt: DateTime.now(),
      );

      expect(item.formattedSize, equals('15.0 MB'));
      expect(item.formattedProgress, equals('50%'));
      expect(item.status, equals(DownloadStatus.downloading));
    });

    test('UserModel serialization and deserialization', () {
      final user = UserModel(
        id: 'u1',
        name: 'Biruk Teklu',
        email: 'student@abyssinia.com',
        role: 'Pro Learner',
        joinedDate: DateTime(2026, 1, 1),
      );

      final json = user.toJson();
      final fromJson = UserModel.fromJson(json);

      expect(fromJson.id, equals('u1'));
      expect(fromJson.name, equals('Biruk Teklu'));
      expect(fromJson.email, equals('student@abyssinia.com'));
      expect(fromJson.role, equals('Pro Learner'));
    });

    test('AppPathService resolves valid persistent directories', () async {
      final base = await AppPathService.getBaseDirectory();
      expect(base, isNotEmpty);
      final videoDir = await AppPathService.getVideosDirectory();
      expect(videoDir, contains('elearning_videos'));
    });

    test('DownloadViewModel tracks active, completed, and course downloads', () async {
      final storage = await StorageService.init();
      final downloadService = DownloadService();
      final vm = DownloadViewModel(storageService: storage, downloadService: downloadService);

      final lesson = LessonModel(
        id: 'test_l1',
        title: 'Test Lesson',
        duration: '04:00',
        videoUrl: 'https://example.com/video.mp4',
        description: 'Test Description',
        order: 1,
      );

      final course = CourseModel(
        id: 'test_c1',
        title: 'Test Course',
        description: 'Desc',
        instructor: 'Biruk',
        instructorTitle: 'Dev',
        thumbnailUrl: '',
        accentColor: '#6366F1',
        category: 'Mobile',
        level: 'All Levels',
        rating: 4.8,
        totalDuration: '04:00',
        chapters: [
          ChapterModel(id: 'ch1', title: 'Ch1', description: '', order: 1, lessons: [lesson]),
        ],
      );

      // Start download
      vm.startDownload(lesson: lesson, course: course);

      expect(vm.isDownloading('test_l1'), isTrue);
      expect(vm.activeDownloads.any((d) => d.lessonId == 'test_l1'), isTrue);
      expect(vm.isCourseDownloading(course), isTrue);

      // Cancel download
      vm.cancelDownload('test_l1');
      expect(vm.isDownloading('test_l1'), isFalse);
      expect(vm.isFailed('test_l1'), isTrue);

      // Delete download
      await vm.deleteDownload('test_l1');
      expect(vm.isFailed('test_l1'), isFalse);
    });
  });

  group('Widget UI Smoke Tests', () {
    testWidgets('LoginScreen displays Abyssinia branding and inputs', (WidgetTester tester) async {
      late StorageService storageService;
      await tester.runAsync(() async {
        storageService = await StorageService.init();
      });
      final authRepo = AuthRepository(storageService);
      final courseRepo = CourseRepository(storageService);
      final downloadService = DownloadService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
            ChangeNotifierProvider(create: (_) => CourseViewModel(courseRepo)),
            ChangeNotifierProvider(
              create: (_) => DownloadViewModel(
                storageService: storageService,
                downloadService: downloadService,
              ),
            ),
            ChangeNotifierProvider(create: (_) => ThemeViewModel(storageService)),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Abyssinia E-Learning'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Fast Demo Login (1-Tap)'), findsOneWidget);
    });
  });
}
