import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/summary/presentation/summary_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

// Web Imports
import 'views_web/auth/login_screen_web.dart';

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
      // kIsWeb kontrolü ile uygulamanın web'de mi yoksa mobilde mi açıldığını anlıyoruz.
      // Web'de açılırsa tamamen ayrı kurguladığımız LoginScreenWeb()'e,
      // Mobilde açılırsa mevcut LoginScreen()'e yönlendiriyoruz.
      home: kIsWeb ? const LoginScreenWeb() : const LoginScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const SummaryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Web Dashboard Layout
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Özet'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat),
                      label: Text('Asistan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart),
                      label: Text('Reports'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person),
                      label: Text('Profil'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          );
        }

        // Mobile App Layout
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Asistan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Özet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}
