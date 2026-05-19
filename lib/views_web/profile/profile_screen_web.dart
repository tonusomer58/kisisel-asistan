import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../../core/utils/format_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';

class ProfileScreenWeb extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  const ProfileScreenWeb({Key? key, this.isDarkMode = true, this.onThemeChanged}) : super(key: key);

  @override
  State<ProfileScreenWeb> createState() => _ProfileScreenWebState();
}

class _ProfileScreenWebState extends State<ProfileScreenWeb> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showAddGoalSheet() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();

    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    final borderColor = widget.isDarkMode ? Colors.white30 : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Yeni Ürün/Hedef Ekle',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                  labelText: 'Hedef Adı (Örn: Monitör)',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                  labelText: 'Hedef Tutar (₺)',
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final targetRaw = targetController.text.replaceAll('.', '').replaceAll(',', '');
                  final target = double.tryParse(targetRaw) ?? 0;
                  if (name.isNotEmpty && target > 0) {
                    await _dbService.addGoal(FormatUtils.capitalizeWords(name), target);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Hedef başarıyla eklendi'),
                          backgroundColor: primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAddFundsDialog(String goalId) {
    final amountController = TextEditingController();
    
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    final borderColor = widget.isDarkMode ? Colors.white30 : Colors.black87;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text('Para Ekle', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: amountController,
            style: TextStyle(color: textColor),
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
              labelText: 'Eklenecek Tutar (₺)',
              labelStyle: const TextStyle(color: AppTheme.textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final amountRaw = amountController.text.replaceAll('.', '').replaceAll(',', '');
                final amount = double.tryParse(amountRaw) ?? 0;
                if (amount > 0) {
                  await _dbService.addFundsToGoal(goalId, amount);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileSheet(String currentName, int currentSeed) {
    final nameController = TextEditingController(text: currentName);
    int selectedSeed = currentSeed;

    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    final borderColor = widget.isDarkMode ? Colors.white30 : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Profili Düzenle', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                      labelText: 'Ad Soyad',
                      labelStyle: const TextStyle(color: AppTheme.textMuted),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Avatar Seç', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final isSelected = index == selectedSeed;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedSeed = index;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: primaryColor, width: 3) : null,
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: ClipOval(
                                child: Image.network(
                                  'https://api.dicebear.com/7.x/bottts/png?seed=$index',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final newName = FormatUtils.capitalizeWords(nameController.text.trim());
                      if (newName.isNotEmpty) {
                        await _dbService.updateProfile(newName, selectedSeed);
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() {}); // refresh FutureBuilder
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Profil güncellendi'),
                              backgroundColor: primaryColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsPanel() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Bilinmiyor';

    final bgColor = widget.isDarkMode ? AppTheme.background : const Color(0xFFF4F7FB);
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF111827);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF3B82F6);
    final inputBgColor = widget.isDarkMode ? AppTheme.background : const Color(0xFFEBF0F6);
    final inputBorderColor = widget.isDarkMode ? Colors.white24 : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gelişmiş Ayarlar',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 22,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        
        // 0. Tema Ayarları
        Card(
          color: cardColor,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.brightness_6, color: textColor),
                    const SizedBox(width: 16),
                    Text('Aydınlık Mod', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  ],
                ),
                Switch(
                  value: !widget.isDarkMode,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    if (widget.onThemeChanged != null) {
                      widget.onThemeChanged!(!val);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 1. Hesap Bilgileri
        Card(
          color: cardColor,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hesap Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: email),
                  readOnly: true,
                  style: TextStyle(color: widget.isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B)),
                  decoration: InputDecoration(
                    labelText: 'E-posta Adresi',
                    prefixIcon: Icon(Icons.email_outlined, color: widget.isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B)),
                    filled: true,
                    fillColor: inputBgColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Güvenlik
        Card(
          color: cardColor,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Güvenlik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    prefixIcon: Icon(Icons.lock_outline, color: widget.isDarkMode ? AppTheme.textMuted : const Color(0xFF64748B)),
                    filled: true,
                    fillColor: inputBgColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final newPass = _newPasswordController.text.trim();
                    if (newPass.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }
                    try {
                      await user?.updatePassword(newPass);
                      if (context.mounted) {
                        _newPasswordController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Şifre başarıyla güncellendi'), backgroundColor: AppTheme.neonGreen),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: Tekrar giriş yapmanız gerekebilir. ($e)'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  child: const Text('Şifreyi Güncelle', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2.5. Oturumu Kapat
        Card(
          color: cardColor,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text('Oturumu Kapat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            subtitle: const Text('Güvenli bir şekilde çıkış yapın.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            trailing: Icon(Icons.chevron_right_rounded, color: textColor),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: cardColor,
                  title: Text('Oturumu Kapat', style: TextStyle(color: textColor)),
                  content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textMuted)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // 3. Tehlikeli Bölge
        Card(
          elevation: 4,
          color: Colors.redAccent.withOpacity(0.1),
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tehlikeli Bölge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                const SizedBox(height: 8),
                const Text('Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak yok olur. Bu işlem geri alınamaz.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: cardColor,
                        title: Text('Hesabı Sil', style: TextStyle(color: textColor)),
                        content: const Text('Tüm verileriniz ve hesabınız kalıcı olarak silinecek. Emin misiniz?', style: TextStyle(color: AppTheme.textMuted)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hesabımı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await user?.delete();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/'); // Login'e gönder
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hesap silinemedi. Lütfen tekrar giriş yapıp deneyin. $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Hesabı Kalıcı Olarak Sil', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? AppTheme.background : const Color(0xFFF4F7FB);
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF111827);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol Sütun (%60)
              Expanded(
                flex: 60,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bölüm 1: Kullanıcı Kartı (Dinamik)
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _dbService.getUserProfile(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return Card(
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.1),
                              child: const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(child: CircularProgressIndicator(color: AppTheme.neonGreen)),
                              ),
                            );
                          }

                          final userData = snapshot.data;
                          final fullName = userData?['fullName'] ?? 'Kullanıcı';
                          final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
                          final role = userData?['role'] == 'esnaf' ? 'Esnaf Kullanıcı' : 'Bireysel Kullanıcı';
                          final int avatarSeed = userData?['avatarSeed'] ?? 0;

                          return Card(
                            color: cardColor,
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showEditProfileSheet(fullName, avatarSeed),
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: Colors.transparent,
                                          child: ClipOval(
                                            child: Image.network(
                                              'https://api.dicebear.com/7.x/bottts/png?seed=$avatarSeed',
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                                                radius: 36,
                                                backgroundColor: AppTheme.electricBlue,
                                                child: Text(
                                                  initial,
                                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.neonGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.edit, size: 14, color: AppTheme.background),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName,
                                          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24, color: textColor, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          role,
                                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Bölüm 2: Artılar ve Eksiler (Dinamik Stream)
                      StreamBuilder<QuerySnapshot>(
                        stream: _dbService.getTransactionsStream(),
                        builder: (context, snapshot) {
                          double totalIncome = 0;
                          double totalExpense = 0;

                          if (snapshot.hasData) {
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final double amount = (data['amount'] ?? 0).toDouble();
                              if (data['type'] == 'income') {
                                totalIncome += amount;
                              } else if (data['type'] == 'expense') {
                                totalExpense += amount;
                              }
                            }
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Card(
                                  color: cardColor,
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.04),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.arrow_upward, color: primaryColor, size: 36),
                                        const SizedBox(height: 12),
                                        const Text('Artılar', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        Text(
                                          '+${FormatUtils.formatCurrency(totalIncome)}',
                                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                            color: primaryColor,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Card(
                                  color: cardColor,
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.04),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 36),
                                        const SizedBox(height: 12),
                                        const Text('Eksiler', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        Text(
                                          '-${FormatUtils.formatCurrency(totalExpense)}',
                                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                            color: Colors.redAccent,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 36),

                      // Bölüm 3: Hedefler Başlığı ve Yeni Hedef Ekle Butonu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hedefler & Birikimler',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onPressed: _showAddGoalSheet,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Yeni Hedef Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      StreamBuilder<QuerySnapshot>(
                        stream: _dbService.getGoalsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Card(
                              color: cardColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: textColor.withOpacity(0.1)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    'Henüz bir hedef eklemediniz.',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final String goalId = doc.id;
                              final String name = data['name'] ?? '';
                              final double target = (data['target'] ?? 0).toDouble();
                              final double current = (data['current'] ?? 0).toDouble();

                              final double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0;
                              final int percent = (progress * 100).toInt();

                              return Dismissible(
                                key: Key(goalId),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  color: Colors.redAccent,
                                  child: const Icon(Icons.delete, color: Colors.white, size: 32),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppTheme.cardColor,
                                      title: const Text('Hedefi Sil', style: TextStyle(color: Colors.white)),
                                      content: const Text('Bu hedefi kalıcı olarak silmek istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textMuted)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                },
                                onDismissed: (direction) async {
                                  await _dbService.deleteGoal(goalId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Hedef silindi'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Card(
                                  color: cardColor,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.04),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _showAddFundsDialog(goalId),
                                              icon: Icon(Icons.add_circle, color: primaryColor, size: 28),
                                              tooltip: 'Para Ekle',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${FormatUtils.formatCurrency(current)} / ${FormatUtils.formatCurrency(target)}',
                                              style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w500, fontSize: 15),
                                            ),
                                            Text(
                                              '%$percent',
                                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 12,
                                            backgroundColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFEBF0F6),
                                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
              // Sağ Sütun (%40)
              Expanded(
                flex: 40,
                child: SingleChildScrollView(
                  child: _buildSettingsPanel(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
