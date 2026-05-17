import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mevcut mobil sayfaları import ediyoruz. İçlerindeki iş mantığı (.NET, Gemini) aynen korunacak.
import '../../features/home/presentation/home_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/summary/presentation/summary_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

class DashboardScreenWeb extends StatefulWidget {
  const DashboardScreenWeb({Key? key}) : super(key: key);

  @override
  State<DashboardScreenWeb> createState() => _DashboardScreenWebState();
}

class _DashboardScreenWebState extends State<DashboardScreenWeb> {
  int _currentIndex = 0;
  bool _isMenuExpanded = true;
  bool _isDarkMode = true;

  List<Widget> _getWebScreens() {
    return [
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
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB);
    final cardColor = _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final sidebarColor = _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final textColor = _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final primaryColor = _isDarkMode ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: sidebarColor,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Finansal Akıllı Asistan', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.menu, color: textColor),
          onPressed: () {
            setState(() {
              _isMenuExpanded = !_isMenuExpanded;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/'); // Login'e yönlendirmek için
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Çıkış yapılamadı: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sol Menü: NavigationRail (Sürekli Açık)
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                )
              ],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _isMenuExpanded ? 250 : 70,
              child: NavigationRail(
                backgroundColor: sidebarColor,
                unselectedIconTheme: const IconThemeData(color: Colors.grey),
                selectedIconTheme: IconThemeData(color: primaryColor),
                unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                selectedLabelTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
              extended: _isMenuExpanded,
              minExtendedWidth: 250,
              minWidth: 70,
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: Text('Ana Sayfa', style: TextStyle(fontSize: 16, color: textColor)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.chat_outlined),
                selectedIcon: const Icon(Icons.chat),
                label: Text('Asistan', style: TextStyle(fontSize: 16, color: textColor)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: Text('Raporlar', style: TextStyle(fontSize: 16, color: textColor)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: Text('Profil', style: TextStyle(fontSize: 16, color: textColor)),
              ),
            ],
          ),
          ), // This closes AnimatedContainer
          ), // This closes the newly added Container
          VerticalDivider(thickness: 1, width: 1, color: _isDarkMode ? Colors.white12 : Colors.black12),
          // Sağ İçerik Alanı
          Expanded(
            child: Container(
              color: bgColor,
              child: _buildRightContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightContent() {
    return _getWebScreens()[_currentIndex];
  }
}
