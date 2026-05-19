import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/summary/presentation/summary_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

// Web Imports
import 'views_web/auth/login_screen_web.dart';
import 'views_web/dashboard/dashboard_screen_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FinAIApp());
}

class FinAIApp extends StatelessWidget {
  const FinAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finansal Akıllı Asistan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.neonGreen),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return kIsWeb ? const DashboardScreenWeb() : const DashboardScreen();
          }
          return kIsWeb ? const LoginScreenWeb() : const LoginScreen();
        },
      ),
    );
  }
}

// Mobil için DashboardScreen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(isDarkMode: _isDarkMode),
      ChatScreen(isDarkMode: _isDarkMode),
      SummaryScreen(isDarkMode: _isDarkMode),
      ProfileScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: (val) {
          setState(() {
            _isDarkMode = val;
          });
        },
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: _isDarkMode ? AppTheme.background : const Color(0xFFFFFFFF),
        selectedItemColor: _isDarkMode ? AppTheme.neonGreen : const Color(0xFF3B82F6),
        unselectedItemColor: _isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_rounded),
            label: 'Asistan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Özet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
