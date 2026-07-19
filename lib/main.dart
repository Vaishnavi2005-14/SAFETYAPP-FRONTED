import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/fake_call_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const SafeHerApp());
}

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0B26),
      primaryColor: const Color(0xFFFF4081),
    );

    return MaterialApp(
      title: 'Shtree Kavach',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151233),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4081),
          brightness: Brightness.dark,
          primary: const Color(0xFFFF4081),
          secondary: const Color(0xFF7C4DFF),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/contacts': (context) => const ContactsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/fake_call': (context) => const FakeCallScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}

