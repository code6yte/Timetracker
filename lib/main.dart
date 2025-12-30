import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'screens/home_screen.dart';
import 'screens/email_verification_screen.dart';
import 'theme_controller.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    
    // Open boxes for local caching
    await Hive.openBox('settings');
    await Hive.openBox('projects');
    await Hive.openBox('tasks');
    await Hive.openBox('time_entries');

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Enable offline persistence explicitly
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (e) {
    debugPrint("Initialization error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController();

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Timely',
          themeMode: themeController.themeMode,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              contentTextStyle: TextStyle(color: Colors.black87),
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF121212),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              contentTextStyle: TextStyle(color: Colors.white70),
            ),
          ),
          home: StreamBuilder<bool>(
            stream: AuthService().sessionStateChanges,
            builder: (context, snapshot) {
              final isLoggedIn = snapshot.data ?? false;
              final auth = AuthService();

              if (!isLoggedIn && !auth.isGuest) {
                return const LoginPage();
              }

              if (auth.isGuest) {
                return const HomeScreen();
              }

              final user = auth.currentUser;
              if (user != null) {
                if (user.emailVerified) {
                  return const HomeScreen();
                } else {
                  return const EmailVerificationScreen();
                }
              }

              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}
