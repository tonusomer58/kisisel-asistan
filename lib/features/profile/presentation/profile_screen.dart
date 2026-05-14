import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<Map<String, dynamic>> _goals = [
    {
      'name': '1TB M.2 SSD',
      'target': 4000.0,
      'current': 2000.0,
    },
    {
      'name': 'Ryzen 5 5500 Sistem Yükseltmesi',
      'target': 8500.0,
      'current': 1500.0,
    },
  ];

  void _addGoal(String name, double target) {
    setState(() {
      _goals.add({
        'name': name,
        'target': target,
        'current': 0.0,
      });
    });
  }

  void _addFundsToGoal(int index, double amount) {
    setState(() {
      _goals[index]['current'] += amount;
      if (_goals[index]['current'] > _goals[index]['target']) {
        _goals[index]['current'] = _goals[index]['target'];
      }
    });
  }

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
                onPressed: () {
                  final name = nameController.text.trim();
                  final target = double.tryParse(targetController.text) ?? 0;
                  if (name.isNotEmpty && target > 0) {
                    _addGoal(name, target);
                    Navigator.pop(context);
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

  void _showAddFundsDialog(int index) {
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
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  _addFundsToGoal(index, amount);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
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
            // Bölüm 1: Kullanıcı Kartı
            Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.electricBlue,
                      child: Text(
                        'A',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ahmet Yılmaz',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Bireysel Kullanıcı',
                            style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bölüm 2: Artılar ve Eksiler
            Row(
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
                          const Text('Gelirler', style: TextStyle(color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '+₺45.000',
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
                          const Text('Giderler', style: TextStyle(color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '-₺28.500',
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
            ),
            const SizedBox(height: 32),

            // Bölüm 3: Dinamik Birikimler ve Ürün Hedefleri Listesi
            Text(
              'Hedefler & Birikimler',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            ..._goals.asMap().entries.map((entry) {
              final index = entry.key;
              final goal = entry.value;
              final double target = goal['target'];
              final double current = goal['current'];
              final double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0;
              final int percent = (progress * 100).toInt();

              return Card(
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
                              goal['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showAddFundsDialog(index),
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
                            '₺${current.toStringAsFixed(0)} / ₺${target.toStringAsFixed(0)}',
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
              );
            }).toList(),
            
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
