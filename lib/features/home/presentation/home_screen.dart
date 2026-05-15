import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showAddTransactionSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';
    String category = 'Market';
    final categories = ['Market', 'Fatura', 'Eğitim', 'Eğlence', 'Sağlık', 'Diğer'];
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('İşlem Ekle', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'income', label: Text('Gelir')),
                      ButtonSegment(value: 'expense', label: Text('Gider')),
                    ],
                    selected: {type},
                    onSelectionChanged: (newSelection) {
                      setModalState(() => type = newSelection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? (type == 'income' ? AppTheme.neonGreen : Colors.redAccent) : Colors.transparent),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? AppTheme.background : AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (type == 'expense')
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: AppTheme.cardColor,
                      style: const TextStyle(color: AppTheme.textMain),
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                  if (type == 'expense') const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 20),
                      const SizedBox(width: 8),
                      Text('Tarih: ${DateFormat('dd/MM/yyyy').format(selectedDate)}', style: const TextStyle(color: AppTheme.textMain)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(primary: AppTheme.neonGreen, onPrimary: AppTheme.background, surface: AppTheme.cardColor, onSurface: AppTheme.textMain),
                                dialogBackgroundColor: AppTheme.cardColor,
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setModalState(() => selectedDate = picked);
                        },
                        child: const Text('Değiştir', style: TextStyle(color: AppTheme.neonGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppTheme.textMain),
                    decoration: const InputDecoration(labelText: 'İşlem Adı (Örn: Maaş, Market)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    style: const TextStyle(color: AppTheme.textMain),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Tutar (₺)'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final amountRaw = amountController.text.replaceAll('.', '').replaceAll(',', '');
                      final amount = double.tryParse(amountRaw) ?? 0;
                      if (title.isNotEmpty && amount > 0) {
                        await _dbService.addTransaction(FormatUtils.capitalizeWords(title), amount, type, category: category, date: selectedDate);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem eklendi'), backgroundColor: AppTheme.neonGreen, behavior: SnackBarBehavior.floating));
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
      appBar: AppBar(title: const Text('Ana Sayfa')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
          }

          final docs = snapshot.hasData ? snapshot.data!.docs : [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          double totalExpense = 0;
          double todayExpense = 0;
          double weekExpense = 0;
          double monthExpense = 0;
          final now = DateTime.now();

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['type'] == 'expense') {
              final amount = (data['amount'] ?? 0).toDouble();
              totalExpense += amount;
              final date = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
              if (date.year == now.year && date.month == now.month && date.day == now.day) todayExpense += amount;
              if (date.isAfter(now.subtract(const Duration(days: 7)))) weekExpense += amount;
              if (date.year == now.year && date.month == now.month) monthExpense += amount;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('Toplam Harcama', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(FormatUtils.formatCurrency(totalExpense), style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.neonGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSummaryMiniCard('Günlük Gider', todayExpense),
                    const SizedBox(width: 8),
                    _buildSummaryMiniCard('Haftalık Gider', weekExpense),
                    const SizedBox(width: 8),
                    _buildSummaryMiniCard('Aylık Gider', monthExpense),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Son İşlemler', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
                const SizedBox(height: 16),
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String title = data['title'] ?? 'İşlem';
                  final double amount = (data['amount'] ?? 0).toDouble();
                  final String type = data['type'] ?? 'expense';
                  final DateTime date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                  final isIncome = type == 'income';
                  final color = isIncome ? AppTheme.neonGreen : Colors.redAccent;
                  final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;
                  final amountText = isIncome ? '+${FormatUtils.formatCurrency(amount)}' : '-${FormatUtils.formatCurrency(amount)}';

                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete, color: Colors.white, size: 32),
                    ),
                    onDismissed: (direction) async {
                      final deletedData = doc.data() as Map<String, dynamic>;
                      await _dbService.deleteTransaction(doc.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('İşlem silindi.'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'Geri Al',
                              textColor: Colors.white,
                              onPressed: () async {
                                await _dbService.restoreTransaction(doc.id, deletedData);
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(color: AppTheme.textMuted)),
                        trailing: Text(amountText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: AppTheme.neonGreen,
        child: const Icon(Icons.add, color: AppTheme.background, size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'Henüz işleminiz yok.',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          const Text('Aşağıdaki + butonundan hemen ekle!', style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard(String title, double amount) {
    return Expanded(
      child: Card(
        color: AppTheme.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(FormatUtils.formatCurrency(amount), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
