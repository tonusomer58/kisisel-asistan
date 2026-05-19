import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../dashboard/dashboard_screen_web.dart';

class RegisterScreenWeb extends StatefulWidget {
  const RegisterScreenWeb({Key? key}) : super(key: key);

  @override
  State<RegisterScreenWeb> createState() => _RegisterScreenWebState();
}

class _RegisterScreenWebState extends State<RegisterScreenWeb> {
  int _selectedRoleIndex = 0; // 0 for Bireysel, 1 for KOBİ

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _taxNoController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isHovering = false; // Hover state for main button

  void _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final businessName = _businessNameController.text.trim();
    final role = _selectedRoleIndex == 0 ? 'bireysel' : 'sme';

    if (email.isEmpty || password.isEmpty || name.isEmpty || surname.isEmpty || (_selectedRoleIndex == 1 && businessName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen zorunlu alanları doldurun.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        role: role,
        fullName: '$name $surname',
        businessName: _selectedRoleIndex == 1 ? businessName : null,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreenWeb()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt başarısız: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKobi = _selectedRoleIndex == 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 900;

          Widget buildForm() {
            return Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 48, vertical: isSmallScreen ? 32 : 64),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isSmallScreen) ...[
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.rocket_launch_outlined, size: 50, color: AppTheme.neonGreen),
                              const SizedBox(height: 12),
                              Text(
                                'Kişisel Asistan',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        'Hesap Oluştur',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Bireysel / KOBİ Seçimi
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildRoleButton('Bireysel', 0)),
                            Expanded(child: _buildRoleButton('Esnaf / KOBİ', 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // KOBİ ise ekstra alanlar
                      if (isKobi) ...[
                        _buildTextField(_businessNameController, 'İşletme Adı', Icons.store_outlined),
                        const SizedBox(height: 16),
                        _buildTextField(_taxNoController, 'Vergi No (Opsiyonel)', Icons.numbers_outlined),
                        const SizedBox(height: 16),
                      ],

                      // Ad Soyad (Yan Yana)
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_nameController, 'Ad', Icons.person_outline)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_surnameController, 'Soyad', Icons.person_outline)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(_emailController, 'E-posta', Icons.email_outlined),
                      const SizedBox(height: 16),

                      _buildTextField(_passwordController, 'Şifre', Icons.lock_outline, isPassword: true),
                      const SizedBox(height: 32),

                      // Hover Efektli Kayıt Butonu
                      MouseRegion(
                        onEnter: (_) => setState(() => _isHovering = true),
                        onExit: (_) => setState(() => _isHovering = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isHovering
                                ? [
                                    BoxShadow(
                                      color: AppTheme.neonGreen.withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    )
                                  ]
                                : [],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isHovering ? AppTheme.neonGreen.withOpacity(0.9) : AppTheme.neonGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Kayıt Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (isSmallScreen) {
            return Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textMain, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 48.0),
                  child: buildForm(),
                ),
              ],
            );
          }

          return Row(
            children: [
              // Sol Taraf: Görsel / Karşılama
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.cardColor, AppTheme.background],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(64.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.rocket_launch_outlined, size: 80, color: AppTheme.neonGreen),
                          const SizedBox(height: 32),
                          Text(
                            'Aramıza Katıl,\nFark Yarat!',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'İster bireysel harcamalarını yönet, ister küçük işletmenin tüm finansal kontrolünü eline al. Saniyeler içinde hesabını oluştur ve yapay zeka ile tanış.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 20,
                                  color: AppTheme.textMuted,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Sağ Taraf: Kayıt Formu
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    // Geri Butonu
                    Positioned(
                      top: 32,
                      left: 32,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.textMain, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    buildForm(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleButton(String title, int index) {
    final isSelected = _selectedRoleIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
      ),
    );
  }
}
