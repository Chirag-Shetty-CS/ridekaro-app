import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/otp_page.dart';
import 'pages/create_account_page.dart';
import 'pages/home_page.dart';
import 'pages/driver_home_page.dart';
import 'pages/account_page.dart';
import 'providers/language_provider.dart';
import 'l10n/app_localizations.dart';

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
    return ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            // Localization configuration
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('mr'), // Marathi
            ],
            locale: languageProvider.locale,
            // Use your app's dark theme
            theme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: const Color(0xFFFFD700),
              scaffoldBackgroundColor: const Color(0xFF2E2E2E),
              // ... (rest of your theme data)
            ),
            // Set the initial route to the AuthWrapper
            initialRoute: '/',
            // Define all the app's routes
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginPage(),
              '/otp': (context) => const OtpPage(),
              '/create-account': (context) => const CreateAccountPage(),
              '/rider_home': (context) => const HomeScreen(),
              '/driver_home': (context) => const DriverHomeScreen(),
              '/account': (context) => const AccountPage(),
            },
          );
        },
      ),
    );
  }
}

// --- This is the powerful AuthWrapper that handles all startup logic ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Fetches the user's type from Firestore using a direct lookup by UID
  Future<String> _getUserType(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    // Default to 'rider' if the document or field doesn't exist for safety
    return userDoc.data()?['userType'] ?? 'rider';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // While checking the authentication state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // If the user is logged in, proceed to check their userType
        if (authSnapshot.hasData && authSnapshot.data != null) {
          return FutureBuilder<String>(
            future: _getUserType(authSnapshot.data!),
            builder: (context, userTypeSnapshot) {
              // While fetching the userType from Firestore
              if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen();
              }
              // If we have the userType, navigate to the correct screen
              if (userTypeSnapshot.hasData) {
                if (userTypeSnapshot.data?.toLowerCase() == 'driver') {
                  return const DriverHomeScreen();
                } else {
                  return const HomeScreen();
                }
              }
              // If there was an error or no data, default to the rider screen
              return const HomeScreen();
            },
          );
        }

        // If the user is not logged in, show the LoginPage
        return const LoginPage();
      },
    );
  }
}

// A simple, reusable loading screen widget
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2E2E2E),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
        ),
      ),
    );
  }
}
