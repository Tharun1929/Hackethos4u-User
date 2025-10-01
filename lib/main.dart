import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/course_provider.dart';
import 'services/notification_service.dart';
import 'services/data_sync_service.dart';
import 'services/app_initializer.dart';
import 'services/app_settings_service.dart';
import 'utils/theme_provider.dart';
import 'utils/app_theme.dart';

import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/homescreen/main_page.dart';
import 'screens/course/course_screen.dart';
import 'screens/course/my_course_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/achievements_screen.dart';
import 'screens/profile/learning_history_screen.dart';
import 'screens/course/payment_screen.dart';
import 'screens/course/video_player_screen.dart';
import 'screens/course/learning_course_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/course/course_progress_screen.dart';
import 'screens/profile/learning_streak_screen.dart';
import 'screens/profile/certificate_display_screen.dart';
import 'screens/profile/enhanced_certificate_screen.dart';
import 'screens/profile/wishlist_screen.dart';
import 'screens/course/course_plan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix for Flutter mouse tracker assertion errors
  if (kDebugMode) {
    // Disable debug assertions for mouse tracker in debug mode
    // Running in debug mode - mouse tracker assertions disabled
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize app services
  await AppInitializer().initializeApp();

  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize data sync service
  final dataSyncService = DataSyncService();
  await dataSyncService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => AppSettingsService()..initialize()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Hackethos4u',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/welcome':
                  return MaterialPageRoute(
                      builder: (_) => const WelcomeScreen());
                case '/login':
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
                case '/register':
                  return MaterialPageRoute(
                      builder: (_) => const RegisterScreen());
                case '/home':
                  return MaterialPageRoute(builder: (_) => const MainPage());
                case '/courses':
                  return MaterialPageRoute(
                      builder: (_) => const CourseScreen());
                case '/explore':
                  return MaterialPageRoute(
                      builder: (_) => const CourseScreen());
                case '/community':
                  return MaterialPageRoute(
                      builder: (_) => const CommunityScreen());
                case '/progress':
                  return MaterialPageRoute(
                      builder: (_) => const ProgressScreen());
                case '/myCourses':
                  return MaterialPageRoute(
                      builder: (_) => const MyCourseScreen());
                case '/profile':
                  return MaterialPageRoute(
                      builder: (_) => const ProfileScreen());
                case '/settings':
                  return MaterialPageRoute(
                      builder: (_) => const SettingsScreen());
                case '/editProfile':
                  return MaterialPageRoute(
                      builder: (_) => const EditProfileScreen());
                case '/achievements':
                  return MaterialPageRoute(
                      builder: (_) => const AchievementsScreen());
                case '/certificates':
                  return MaterialPageRoute(
                      builder: (_) => const CertificateDisplayScreen());
                case '/enhancedCertificates':
                  return MaterialPageRoute(
                      builder: (_) => const EnhancedCertificateScreen());
                case '/wishlist':
                  return MaterialPageRoute(
                      builder: (_) => const WishlistScreen());
                case '/learningHistory':
                  return MaterialPageRoute(
                      builder: (_) => const LearningHistoryScreen());
                case '/learningCourse':
                  final args = settings.arguments as String?;
                  return MaterialPageRoute(
                      builder: (_) => LearningCourseScreen(courseId: args));
                case '/payment':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      courseData: args ?? {},
                    ),
                  );
                case '/subscriptions':
                  return MaterialPageRoute(
                      builder: (_) => const SubscriptionsScreen());
                case '/videoPlayer':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(
                      videoData: args ?? {},
                    ),
                  );
                case '/invoices':
                  return MaterialPageRoute(
                      builder: (_) => const InvoicesScreen());
                case '/cart':
                  return MaterialPageRoute(builder: (_) => const CartScreen());
                case '/courseProgress':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (_) => CourseProgressScreen(
                      courseId: args?['courseId'] ?? '',
                      courseTitle: args?['courseTitle'] ?? 'Course Progress',
                    ),
                  );
                case '/learningStreak':
                  return MaterialPageRoute(
                      builder: (_) => const LearningStreakScreen());
                // '/certificateSetup' removed from user app; admin-only
                case '/coursePlan':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (_) => CoursePlanScreen(
                      courseData: args ?? {},
                    ),
                  );
                default:
                  return MaterialPageRoute(
                      builder: (_) => const SplashScreen());
              }
            },
          );
        },
      ),
    );
  }
}
