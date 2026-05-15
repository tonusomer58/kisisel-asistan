import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../core/utils/format_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showAddGoalSheet() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
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
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textMain),
                decoration: const InputDecoration(
                  labelText: 'Hedef Adı (Örn: Monitör)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                style: const TextStyle(color: AppTheme.textMain),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hedef Tutar (₺)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final target = double.tryParse(targetController.text) ?? 0;
                  if (name.isNotEmpty && target > 0) {
                    await _dbService.addGoal(FormatUtils.capitalizeWords(name), target);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hedef başarıyla eklendi'),
                          backgroundColor: AppTheme.neonGreen,
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
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('Para Ekle', style: TextStyle(color: AppTheme.textMain)),
          content: TextField(
            controller: amountController,
            style: const TextStyle(color: AppTheme.textMain),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Eklenecek Tutar (₺)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
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
                  Text('Profili Düzenle', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppTheme.textMain),
                    decoration: const InputDecoration(labelText: 'Ad Soyad'),
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
                              border: isSelected ? Border.all(color: AppTheme.neonGreen, width: 3) : null,
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
                    onPressed: () async {
                      final newName = FormatUtils.capitalizeWords(nameController.text.trim());
                      if (newName.isNotEmpty) {
                        await _dbService.updateProfile(newName, selectedSeed);
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() {}); // refresh FutureBuilder
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil güncellendi'),
                              backgroundColor: AppTheme.neonGreen,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil ve Birikimler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bölüm 1: Kullanıcı Kartı (Dinamik)
            FutureBuilder<Map<String, dynamic>?>(
              future: _dbService.getUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.3),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
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
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showEditProfileSheet(fullName, avatarSeed),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.transparent,
                                child: ClipOval(
                                  child: Image.network(
                                    'https://api.dicebear.com/7.x/bottts/png?seed=$avatarSeed',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => CircleAvatar(
                                      radius: 30,
                                      backgroundColor: AppTheme.electricBlue,
                                      child: Text(
                                        initial,
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.neonGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 12, color: AppTheme.background),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role,
                                style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.w600),
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
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.arrow_upward, color: AppTheme.neonGreen, size: 32),
                              const SizedBox(height: 8),
                              const Text('Artılar', style: TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '+${FormatUtils.formatCurrency(totalIncome)}',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: AppTheme.neonGreen,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 32),
                              const SizedBox(height: 8),
                              const Text('Eksiler', style: TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '-${FormatUtils.formatCurrency(totalExpense)}',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.redAccent,
                                  fontSize: 18,
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
            const SizedBox(height: 32),

            // Bölüm 3: Dinamik Birikimler ve Ürün Hedefleri Listesi
            Text(
              'Hedefler & Birikimler',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: _dbService.getGoalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Henüz bir hedef eklemediniz.',
                        style: TextStyle(color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
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
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showAddFundsDialog(goalId),
                                  icon: const Icon(Icons.add_circle, color: AppTheme.neonGreen),
                                  tooltip: 'Para Ekle',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${FormatUtils.formatCurrency(current)} / ${FormatUtils.formatCurrency(target)}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '%$percent',
                                  style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: AppTheme.background,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonGreen),
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
            
            const SizedBox(height: 80), // Fab için boşluk
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalSheet,
        backgroundColor: AppTheme.neonGreen,
        icon: const Icon(Icons.add, color: AppTheme.background),
        label: const Text(
          'Yeni Hedef Ekle',
          style: TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
