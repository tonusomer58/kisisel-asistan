import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/database_service.dart';
import '../home/home_screen_web.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../summary/summary_screen_web.dart';
import '../profile/profile_screen_web.dart';
import '../auth/login_screen_web.dart';

class DashboardScreenWeb extends StatefulWidget {
  const DashboardScreenWeb({Key? key}) : super(key: key);

  @override
  State<DashboardScreenWeb> createState() => _DashboardScreenWebState();
}

class _DashboardScreenWebState extends State<DashboardScreenWeb>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isSidebarExpanded = true;
  bool _isDarkMode = true;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _updateUrl(_currentIndex);
  }

  void _updateUrl(int index) {
    String path;
    switch (index) {
      case 0:
        path = '/dashboard';
        break;
      case 1:
        path = '/chat';
        break;
      case 2:
        path = '/reports';
        break;
      case 3:
        path = '/profile';
        break;
      default:
        path = '/dashboard';
    }
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(path),
    );
  }

  static const double _expandedWidth = 260.0;
  static const double _collapsedWidth = 72.0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Ana Sayfa'),
    _NavItem(icon: Icons.smart_toy_rounded, label: 'AI Asistan'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Raporlar'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  List<Widget> _getScreens() {
    return [
      HomeScreenWeb(isDarkMode: _isDarkMode),
      ChatScreen(isDarkMode: _isDarkMode),
      SummaryScreenWeb(isDarkMode: _isDarkMode),
      ProfileScreenWeb(
        isDarkMode: _isDarkMode,
        onThemeChanged: (val) {
          setState(() => _isDarkMode = val);
        },
      ),
    ];
  }

  Future<void> _handleLogout() async {
    final bgColor = _isDarkMode ? AppTheme.cardColor : Colors.white;
    final textColor = _isDarkMode ? AppTheme.textMain : const Color(0xFF111827);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Çıkış Yap', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
            style: TextStyle(color: textColor.withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: TextStyle(color: textColor.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreenWeb()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 900;

    final bgColor = _isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9);
    final sidebarBg = _isDarkMode ? const Color(0xFF0D1526) : const Color(0xFFFFFFFF);
    final primaryColor = _isDarkMode ? AppTheme.neonGreen : const Color(0xFF3B82F6);
    final dividerColor = _isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: isSmallScreen
          ? Drawer(
              width: _expandedWidth,
              backgroundColor: sidebarBg,
              child: _buildSidebar(
                isExpanded: true,
                sidebarBg: sidebarBg,
                primaryColor: primaryColor,
                dividerColor: dividerColor,
                isSmallScreen: true,
              ),
            )
          : null,
      body: Row(
        children: [
          // ─── PREMIUM SIDEBAR (Masaüstü Sabit) ───
          if (!isSmallScreen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              width: _isSidebarExpanded ? _expandedWidth : _collapsedWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: sidebarBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: _buildSidebar(
                  isExpanded: _isSidebarExpanded,
                  sidebarBg: sidebarBg,
                  primaryColor: primaryColor,
                  dividerColor: dividerColor,
                  isSmallScreen: false,
                ),
              ),
            ),

          // ─── ANA İÇERİK ALANI ───
          Expanded(
            child: Stack(
              children: [
                _getScreens()[_currentIndex],
                if (isSmallScreen)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Builder(
                      builder: (context) => InkWell(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sidebarBg.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(_isDarkMode ? 0.25 : 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: dividerColor),
                          ),
                          child: Icon(
                            Icons.menu_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({
    required bool isExpanded,
    required Color sidebarBg,
    required Color primaryColor,
    required Color dividerColor,
    required bool isSmallScreen,
  }) {
    return Column(
      children: [
        // ─── LOGO BÖLÜMÜ ───
        Container(
          height: 72,
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 20 : 0,
          ),
          child: isExpanded
              ? Row(
                  children: [
                    _buildLogoIcon(primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FinAI',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Akıllı Finans Asistanı',
                            style: TextStyle(
                              color: (_isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B)),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSmallScreen)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: _isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                )
              : Center(child: _buildLogoIcon(primaryColor)),
        ),
        Divider(height: 1, color: dividerColor),
        const SizedBox(height: 12),

        // ─── NAVİGASYON ÖĞELERİ ───
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            itemCount: _navItems.length,
            itemBuilder: (listViewContext, index) {
              return _buildNavItem(listViewContext, index, primaryColor, isExpanded, isSmallScreen);
            },
          ),
        ),

        // ─── KULLANICI PROFİL BÖLÜMÜ ───
        Divider(height: 1, color: dividerColor),
        _buildUserSection(primaryColor, isExpanded),

        // ─── SIDEBAR TOGGLE BUTONU ───
        if (!isSmallScreen)
          _buildCollapseButton(dividerColor, primaryColor),
      ],
    );
  }

  Widget _buildLogoIcon(Color primaryColor) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, AppTheme.electricBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildNavItem(BuildContext navContext, int index, Color primaryColor, bool isExpanded, bool isSmallScreen) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];
    final textColor = _isDarkMode ? AppTheme.textMain : const Color(0xFF111827);
    final mutedColor = _isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() => _currentIndex = index);
            _updateUrl(index);
            if (isSmallScreen) {
              Navigator.pop(navContext);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withOpacity(_isDarkMode ? 0.15 : 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: primaryColor.withOpacity(0.25), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 4,
                  height: isSelected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
                SizedBox(width: isExpanded ? 12 : 0),
                Expanded(
                  child: Row(
                    mainAxisAlignment: isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isSelected ? primaryColor : mutedColor,
                      ),
                      if (isExpanded) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? primaryColor : textColor,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(Color primaryColor, bool isExpanded) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _dbService.getUserProfile(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final fullName = userData?['fullName'] ?? 'Kullanıcı';
        final email = FirebaseAuth.instance.currentUser?.email ?? '';
        final avatarSeed = userData?['avatarSeed'] ?? 0;
        final textColor = _isDarkMode ? AppTheme.textMain : const Color(0xFF111827);
        final mutedColor = _isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B);

        return Padding(
          padding: const EdgeInsets.all(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://api.dicebear.com/7.x/bottts/png?seed=$avatarSeed',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        backgroundColor: AppTheme.electricBlue,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Çıkış Butonu
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    tooltip: 'Çıkış Yap',
                    onPressed: _handleLogout,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapseButton(Color dividerColor, Color primaryColor) {
    final textColor = _isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: _isSidebarExpanded
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          if (_isSidebarExpanded)
            Text(
              'Menüyü Daralt',
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedRotation(
                turns: _isSidebarExpanded ? 0 : 0.5,
                duration: const Duration(milliseconds: 280),
                child: Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  size: 18,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
