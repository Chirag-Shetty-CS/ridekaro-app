import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/otp_page.dart';
import 'pages/create_account_page.dart';
import 'pages/home_page.dart'; // **1. Import the new home page**

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RideKaroApp());
}

class RideKaroApp extends StatelessWidget {
  const RideKaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFD700),
        scaffoldBackgroundColor: const Color(0xFF2E2E2E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFFAFAFA)),
          bodyMedium: TextStyle(color: Color(0xFFFAFAFA)),
          headlineSmall: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFAFA).withOpacity(0.1),
          labelStyle: const TextStyle(color: Color(0xFFFAFAFA)),
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFFFD700),
              width: 2,
            ),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/otp': (context) => const OTPPage(),
        '/create-account': (context) => const CreateAccountPage(),
        '/home': (context) => HomeScreen(), // **FIXED: Removed const**
      },
    );
  }
}