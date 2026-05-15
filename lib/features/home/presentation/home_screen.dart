import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/services/database_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DatabaseService _dbService = DatabaseService();

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
                ],
              ),
            );
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
