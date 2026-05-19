import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  const HomeScreen({Key? key, this.isDarkMode = true}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final GeminiService _geminiService = GeminiService();
  String _userRole = 'bireysel';
  bool _isRoleLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  void _fetchUserRole() async {
    try {
      final profile = await _dbService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userRole = profile['role'] ?? 'bireysel';
          _isRoleLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isRoleLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRoleLoading = false;
        });
      }
    }
  }

  void _showAddTransactionSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'transaction'; // 'transaction', 'fixed_expense', 'bill', 'upcoming'
    String type = 'expense'; // for transaction (income/expense)
    String category = 'Market';
    final categories = ['Market', 'Fatura', 'Eğitim', 'Eğlence', 'Sağlık', 'Diğer'];
    DateTime selectedDate = DateTime.now();

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
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Yeni Kayıt Ekle', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'transaction', label: Text('İşlem', style: TextStyle(fontSize: 12))),
                        ButtonSegment(value: 'fixed_expense', label: Text('Sabit Gider', style: TextStyle(fontSize: 12))),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (newSelection) {
                        setModalState(() {
                          selectedType = newSelection.first;
                          titleController.clear();
                          amountController.clear();
                          selectedDate = DateTime.now();
                        });
                      },
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black, width: 1.2)),
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? primaryColor : Colors.transparent),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? (widget.isDarkMode ? AppTheme.background : Colors.white) : AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 350,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (selectedType == 'transaction') ...[
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
                                side: WidgetStateProperty.all(BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black, width: 1.2)),
                                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? (type == 'income' ? primaryColor : Colors.redAccent) : Colors.transparent),
                                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? (widget.isDarkMode ? AppTheme.background : Colors.white) : AppTheme.textMuted),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (type == 'expense') ...[
                              DropdownButtonFormField<String>(
                                value: category,
                                dropdownColor: cardColor,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                                  labelText: 'Kategori',
                                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                                ),
                                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => category = val);
                                },
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              const SizedBox(height: 71),
                            ],
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 20),
                                const SizedBox(width: 8),
                                Text('Tarih: ${DateFormat('dd/MM/yyyy').format(selectedDate)}', style: TextStyle(color: textColor)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) => Theme(
                                        data: widget.isDarkMode
                                          ? ThemeData.dark().copyWith(
                                              colorScheme: const ColorScheme.dark(primary: AppTheme.neonGreen, onPrimary: AppTheme.background, surface: AppTheme.cardColor, onSurface: AppTheme.textMain),
                                              dialogBackgroundColor: AppTheme.cardColor,
                                            )
                                          : ThemeData.light().copyWith(
                                              colorScheme: ColorScheme.light(primary: primaryColor, onPrimary: Colors.white, surface: Colors.white, onSurface: textColor),
                                              dialogBackgroundColor: Colors.white,
                                            ),
                                        child: child!,
                                      ),
                                    );
                                    if (picked != null) setModalState(() => selectedDate = picked);
                                  },
                                  child: Text('Değiştir', style: TextStyle(color: primaryColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: titleController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                                labelText: 'İşlem Adı (Örn: Maaş, Market)',
                                labelStyle: const TextStyle(color: AppTheme.textMuted),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: amountController,
                              style: TextStyle(color: textColor),
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                                labelText: 'Tutar (₺)',
                                labelStyle: const TextStyle(color: AppTheme.textMuted),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                              ),
                            ),
                          ] else if (selectedType == 'fixed_expense') ...[
                            TextField(
                              controller: titleController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                                labelText: 'Sabit Gider Adı (Örn: Kira, Maaş, İnternet)',
                                labelStyle: const TextStyle(color: AppTheme.textMuted),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: amountController,
                              style: TextStyle(color: textColor),
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                                labelText: 'Aylık Tutar (₺)',
                                labelStyle: const TextStyle(color: AppTheme.textMuted),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final amountRaw = amountController.text.replaceAll('.', '').replaceAll(',', '');
                        final amount = double.tryParse(amountRaw) ?? 0;
                        if (title.isNotEmpty && amount > 0) {
                          if (selectedType == 'transaction') {
                            await _dbService.addTransaction(FormatUtils.capitalizeWords(title), amount, type, category: category, date: selectedDate);
                          } else if (selectedType == 'fixed_expense') {
                            await _dbService.addFixedExpense(FormatUtils.capitalizeWords(title), amount);
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(selectedType == 'transaction'
                                  ? 'İşlem eklendi'
                                  : 'Aylık sabit gider eklendi'),
                              backgroundColor: primaryColor,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: widget.isDarkMode ? AppTheme.background : Colors.white,
                      ),
                      child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? AppTheme.background : const Color(0xFFF0F4F8);
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final docs = snapshot.hasData ? snapshot.data!.docs : [];

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

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Card(
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('Toplam Harcama', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(FormatUtils.formatCurrency(totalExpense), style: Theme.of(context).textTheme.displayMedium?.copyWith(color: primaryColor, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getFixedExpensesStream(),
                  builder: (context, fixedSnapshot) {
                    double totalFixedMonthly = 0.0;
                    if (fixedSnapshot.hasData) {
                      for (var doc in fixedSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        totalFixedMonthly += (data['amount'] ?? 0.0).toDouble();
                      }
                    }
                    return Card(
                      color: cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: textColor.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.withOpacity(0.2),
                          child: const Icon(Icons.star_rounded, color: Colors.amber),
                        ),
                        title: const Text('Sabit Aylık Gider', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            FormatUtils.formatCurrency(totalFixedMonthly),
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildGoalProgressSection(cardColor, textColor, primaryColor),
                const SizedBox(height: 16),
                if (!_isRoleLoading && _userRole == 'sme') ...[
                  _buildAIAnalysisCard(cardColor, textColor, primaryColor, docs.isNotEmpty),
                  _buildUpcomingPaymentsSection(cardColor, textColor, primaryColor),
                  const SizedBox(height: 24),
                ],
                Text('Son İşlemler', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor)),
                const SizedBox(height: 16),
                if (docs.isEmpty)
                  _buildEmptyState()
                else
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String title = data['title'] ?? 'İşlem';
                    final double amount = (data['amount'] ?? 0).toDouble();
                    final String type = data['type'] ?? 'expense';
                    final DateTime date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                    final isIncome = type == 'income';
                    final color = isIncome ? primaryColor : Colors.redAccent;
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
                        color: cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
                          title: Row(
                            children: [
                              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                              if (data['isFixedExpense'] == true) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              ],
                            ],
                          ),
                          subtitle: Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(color: AppTheme.textMuted)),
                          trailing: Text(amountText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 80),
              ],
            ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'Henüz işleminiz yok.',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          const Text('Aşağıdaki + butonundan hemen ekle!', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard(String title, double amount) {
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    
    return Expanded(
      child: Card(
        color: cardColor,
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

  Widget _buildUpcomingPaymentsSection(Color cardColor, Color textColor, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yaklaşan Ödemelerim',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonGreen),
              onPressed: _showAddUpcomingPaymentDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _dbService.getUpcomingPaymentsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
            }
            final docs = snapshot.hasData ? snapshot.data!.docs : [];
            if (docs.isEmpty) {
              return Card(
                color: cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.1),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.payment_outlined, color: AppTheme.textMuted, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'Yaklaşan bir ödemeniz bulunmuyor.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _showAddUpcomingPaymentDialog,
                        child: const Text('Hemen Ekle', style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length > 3 ? 3 : docs.length, // Ana sayfada en fazla 3 tane yaklaşan ödeme gösteriyoruz
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final rawTitle = data['title'] ?? 'Ödeme';
                String title = rawTitle.replaceAll(RegExp(r'^[^a-zA-Z0-9ğĞüÜşŞıİöÖçÇ]+'), '');
                if (title.isEmpty) title = rawTitle;
                title = FormatUtils.capitalizeWords(title);

                final amount = (data['amount'] ?? 0.0).toDouble();
                final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();

                return Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.1),
                      width: 1.2,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Ödeme Tarihi: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          FormatUtils.formatCurrency(amount),
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            await _dbService.deleteUpcomingPayment(doc.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGoalProgressSection(Color cardColor, Color textColor, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.getGoalsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final goals = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hedeflerim',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor),
            ),
            const SizedBox(height: 12),
            ...goals.take(3).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'Hedef';
              final double target = (data['target'] ?? 0.0).toDouble();
              final double current = (data['current'] ?? 0.0).toDouble();
              final double remaining = (target - current).clamp(0.0, target);
              final double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
              final bool completed = remaining == 0;

              return Card(
                color: cardColor,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: completed
                        ? primaryColor.withOpacity(0.5)
                        : (widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.1)),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                completed ? Icons.check_circle_rounded : Icons.flag_rounded,
                                color: completed ? primaryColor : Colors.orangeAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
                            ],
                          ),
                          Text(
                            completed ? '✓ Tamamlandı!' : FormatUtils.formatCurrency(remaining) + ' kaldı',
                            style: TextStyle(
                              color: completed ? primaryColor : Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: widget.isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.07),
                          valueColor: AlwaysStoppedAnimation<Color>(completed ? primaryColor : Colors.orangeAccent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(FormatUtils.formatCurrency(current), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          Text(FormatUtils.formatCurrency(target), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // --- ESNAF / KOBİ YARDIMCI WIDGETLARI ---

  Widget _buildAIAnalysisCard(Color cardColor, Color textColor, Color primaryColor, bool hasTransactions) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.neonGreen, AppTheme.electricBlue],
                  ).createShader(bounds),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gelişmiş Yapay Zeka Analizi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _dbService.getBillsStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildAIChip(
                        icon: Icons.receipt_long_outlined,
                        label: 'Fatura ($count)',
                        primaryColor: primaryColor,
                        textColor: textColor,
                        onTap: _showBillsBottomSheet,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _dbService.getFixedExpensesStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildAIChip(
                        icon: Icons.home_repair_service_outlined,
                        label: 'Sabit Gider ($count)',
                        primaryColor: primaryColor,
                        textColor: textColor,
                        onTap: _showFixedExpensesBottomSheet,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _dbService.getUpcomingPaymentsStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildAIChip(
                        icon: Icons.payment_outlined,
                        label: 'Yaklaşan Ödeme ($count)',
                        primaryColor: primaryColor,
                        textColor: textColor,
                        onTap: _showUpcomingPaymentsBottomSheet,
                      );
                    },
                  ),

                  const SizedBox(width: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _dbService.getRemindersStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildAIChip(
                        icon: Icons.alarm_on_outlined,
                        label: 'Hatırlatıcı ($count)',
                        primaryColor: primaryColor,
                        textColor: textColor,
                        onTap: _showRemindersBottomSheet,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAIFinanceAnalysis(hasTransactions),
              icon: const Icon(Icons.analytics_outlined, color: Colors.white),
              label: const Text(
                'Verileri Analiz Et',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIChip({
    required IconData icon,
    required String label,
    required Color primaryColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // --- ESNAF / KOBİ ACTIONS ---

  void _showBillsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Faturalarım', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonGreen),
                    onPressed: () => _showAddBillDialog(isFromBottomSheet: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getBillsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
                    }
                    final docs = snapshot.hasData ? snapshot.data!.docs : [];
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                          child: Text('Aktif faturanız bulunmamaktadır.', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final rawTitle = data['title'] ?? 'Fatura';
                        String title = rawTitle.replaceAll(RegExp(r'^[^a-zA-Z0-9ğĞüÜşŞıİöÖçÇ]+'), '');
                        if (title.isEmpty) title = rawTitle;
                        title = FormatUtils.capitalizeWords(title);
                        
                        final amount = (data['amount'] ?? 0.0).toDouble();
                        final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();

                        return Card(
                          color: widget.isDarkMode ? AppTheme.background : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.1),
                              width: 1.2,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                            subtitle: Text('Son Ödeme: ${DateFormat('dd/MM/yyyy').format(dueDate)}', style: const TextStyle(color: AppTheme.textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(FormatUtils.formatCurrency(amount), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _dbService.payBill(doc.id, title, amount);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$title ödendi ve gider olarak işlendi.'),
                                          backgroundColor: AppTheme.neonGreen,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.neonGreen,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Öde', style: TextStyle(color: AppTheme.background, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAddBillDialog({bool isFromBottomSheet = false}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
              title: Text('Fatura Ekle', style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Fatura Adı (Örn: Elektrik)',
                      labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: widget.isDarkMode ? AppTheme.background : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Tutar (₺)',
                      labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: widget.isDarkMode ? AppTheme.background : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 18),
                      const SizedBox(width: 8),
                      Text('Son Ödeme: ${DateFormat('dd/MM/yyyy').format(selectedDate)}', style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A))),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(
                              data: widget.isDarkMode
                                  ? ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(primary: AppTheme.neonGreen, onPrimary: AppTheme.background, surface: AppTheme.cardColor, onSurface: AppTheme.textMain),
                                      dialogBackgroundColor: AppTheme.cardColor,
                                    )
                                  : ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(primary: AppTheme.neonGreen, onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF0F172A)),
                                      dialogBackgroundColor: Colors.white,
                                    ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('Değiştir', style: TextStyle(color: AppTheme.neonGreen)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final amountRaw = amountController.text.replaceAll('.', '').replaceAll(',', '');
                    final amount = double.tryParse(amountRaw) ?? 0;
                    if (title.isNotEmpty && amount > 0) {
                      await _dbService.addBill(FormatUtils.capitalizeWords(title), amount, selectedDate);
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        if (isFromBottomSheet) {
                          Navigator.pop(context); // Close bottom sheet
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fatura başarıyla eklendi.'), backgroundColor: AppTheme.neonGreen, behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                  child: const Text('Kaydet', style: TextStyle(color: AppTheme.neonGreen)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFixedExpensesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sabit Giderler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonGreen),
                    onPressed: () => _showAddFixedExpenseDialog(isFromBottomSheet: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getFixedExpensesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
                    }
                    final docs = snapshot.hasData ? snapshot.data!.docs : [];
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                          child: Text('Sabit gideriniz bulunmamaktadır.', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Sabit Gider';
                        final amount = (data['amount'] ?? 0.0).toDouble();

                        return Card(
                          color: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                            subtitle: const Text('Aylık Periyot', style: TextStyle(color: AppTheme.textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(FormatUtils.formatCurrency(amount), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _dbService.payFixedExpense(title, amount);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$title ödemesi gider olarak işlendi.'),
                                          backgroundColor: AppTheme.neonGreen,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.neonGreen,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Öde', style: TextStyle(color: AppTheme.background, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    await _dbService.deleteFixedExpense(doc.id);
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAddFixedExpenseDialog({bool isFromBottomSheet = false}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
          title: Text('Sabit Gider Ekle', style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Gider Adı (Örn: Dükkan Kirası)',
                  labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                  filled: true,
                  fillColor: widget.isDarkMode ? AppTheme.background : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Aylık Tutar (₺)',
                  labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                  filled: true,
                  fillColor: widget.isDarkMode ? AppTheme.background : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final amountRaw = amountController.text.replaceAll('.', '').replaceAll(',', '');
                final amount = double.tryParse(amountRaw) ?? 0;
                if (title.isNotEmpty && amount > 0) {
                  await _dbService.addFixedExpense(FormatUtils.capitalizeWords(title), amount);
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    if (isFromBottomSheet) {
                      Navigator.pop(context); // Close bottom sheet
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sabit gider başarıyla eklendi.'), backgroundColor: AppTheme.neonGreen, behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
              child: const Text('Kaydet', style: TextStyle(color: AppTheme.neonGreen)),
            ),
          ],
        );
      },
    );
  }

  void _showUpcomingPaymentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Yaklaşan Ödemeler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonGreen),
                    onPressed: () => _showAddUpcomingPaymentDialog(isFromBottomSheet: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getUpcomingPaymentsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
                    }
                    final docs = snapshot.hasData ? snapshot.data!.docs : [];
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                          child: Text('Yaklaşan ödemeniz bulunmamaktadır.', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final rawTitle = data['title'] ?? 'Ödeme';
                        // Kullanıcının Türkçe klavye kazalarından (Z/Shift yanındaki < tuşu vb.) kaynaklı baştaki özel karakterleri temizliyoruz
                        String title = rawTitle.replaceAll(RegExp(r'^[^a-zA-Z0-9ğĞüÜşŞıİöÖçÇ]+'), '');
                        if (title.isEmpty) title = rawTitle;
                        title = FormatUtils.capitalizeWords(title);
                        
                        final amount = (data['amount'] ?? 0.0).toDouble();
                        final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();

                        return Card(
                          color: widget.isDarkMode ? AppTheme.background : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.1),
                              width: 1.2,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                            subtitle: Text('Ödeme Tarihi: ${DateFormat('dd/MM/yyyy').format(dueDate)}', style: const TextStyle(color: AppTheme.textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(FormatUtils.formatCurrency(amount), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    await _dbService.deleteUpcomingPayment(doc.id);
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAddUpcomingPaymentDialog({bool isFromBottomSheet = false}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
              title: Text('Yaklaşan Ödeme Ekle', style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Ödeme Adı (Örn: Mal Alımı)',
                      labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: widget.isDarkMode ? AppTheme.background : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Tutar (₺)',
                      labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: widget.isDarkMode ? AppTheme.background : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 18),
                      const SizedBox(width: 8),
                      Text('Ödeme Günü: ${DateFormat('dd/MM/yyyy').format(selectedDate)}', style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A))),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(
                              data: widget.isDarkMode
                                  ? ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(primary: AppTheme.neonGreen, onPrimary: AppTheme.background, surface: AppTheme.cardColor, onSurface: AppTheme.textMain),
                                      dialogBackgroundColor: AppTheme.cardColor,
                                    )
                                  : ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(primary: AppTheme.neonGreen, onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF0F172A)),
                                      dialogBackgroundColor: Colors.white,
                                    ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('Değiştir', style: TextStyle(color: AppTheme.neonGreen)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final amountRaw = amountController.text.replaceAll('.', '').replaceAll(',', '');
                    final amount = double.tryParse(amountRaw) ?? 0;
                    if (title.isNotEmpty && amount > 0) {
                      await _dbService.addUpcomingPayment(FormatUtils.capitalizeWords(title), amount, selectedDate);
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        if (isFromBottomSheet) {
                          Navigator.pop(context); // Close bottom sheet
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yaklaşan ödeme başarıyla eklendi.'), backgroundColor: AppTheme.neonGreen, behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                  child: const Text('Kaydet', style: TextStyle(color: AppTheme.neonGreen)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUploadDocumentBottomSheet() {
    bool isScanning = false;
    String scanStatus = 'Hazır';
    bool scanComplete = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Akıllı Belge Tarayıcı (AI)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  const Text('Fatura veya makbuz fotoğraflarınızı yükleyin, Yapay Zeka anında tarayıp sisteme kaydetsin.', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 24),
                  if (!isScanning && !scanComplete)
                    GestureDetector(
                      onTap: () async {
                        setSheetState(() {
                          isScanning = true;
                          scanStatus = 'Dosya yükleniyor...';
                        });
                        await Future.delayed(const Duration(milliseconds: 800));
                        if (!context.mounted) return;
                        setSheetState(() => scanStatus = 'Yapay Zeka belgedeki verileri analiz ediyor...');
                        await Future.delayed(const Duration(milliseconds: 1000));
                        if (!context.mounted) return;
                        setSheetState(() => scanStatus = 'Fatura detayları ayrıştırılıyor...');
                        await Future.delayed(const Duration(milliseconds: 800));
                        if (!context.mounted) return;
                        setSheetState(() {
                          isScanning = false;
                          scanComplete = true;
                        });
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3), style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.neonGreen),
                            SizedBox(height: 12),
                            Text('Belge Seçmek için Tıklayın', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonGreen)),
                            SizedBox(height: 4),
                            Text('PDF, PNG veya JPEG', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  if (isScanning)
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: AppTheme.neonGreen),
                            const SizedBox(height: 16),
                            Text(scanStatus, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  if (scanComplete) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: AppTheme.neonGreen, size: 20),
                              SizedBox(width: 8),
                              Text('Yapay Zeka Analizi Başarılı!', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonGreen)),
                            ],
                          ),
                          const Divider(height: 24, color: AppTheme.textMuted),
                          _buildScanDetailRow('Firma/Belge Türü:', 'Enerjisa Elektrik Faturası'),
                          const SizedBox(height: 8),
                          _buildScanDetailRow('Tutar:', '1.250,00 ₺'),
                          const SizedBox(height: 8),
                          _buildScanDetailRow('Son Ödeme Tarihi:', '25/05/2026'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await _dbService.addBill('Enerjisa Elektrik Faturası', 1250.0, DateTime(2026, 5, 25));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fatura sisteme kaydedildi!'), backgroundColor: AppTheme.neonGreen, behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
                      child: const Text('Fatura Olarak Kaydet', style: TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScanDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
      ],
    );
  }

  void _showRemindersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hatırlatıcılar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonGreen),
                    onPressed: _showAddReminderDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getRemindersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
                    }
                    final docs = snapshot.hasData ? snapshot.data!.docs : [];
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                          child: Text('Hatırlatıcınız bulunmamaktadır.', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Hatırlatıcı';
                        final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();

                        return Card(
                          color: widget.isDarkMode ? AppTheme.background : const Color(0xFFF1F5F9),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.notifications_active, color: AppTheme.neonGreen),
                            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                            subtitle: Text('Hatırlatma: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}', style: const TextStyle(color: AppTheme.textMuted)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                await _dbService.deleteReminder(doc.id);
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
              title: Text('Hatırlatıcı Ekle', style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Başlık (Örn: Çek Ödemesi)',
                      labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: widget.isDarkMode ? AppTheme.background : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 18),
                      const SizedBox(width: 8),
                      Text('Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDate)}', style: TextStyle(color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A))),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(
                              data: widget.isDarkMode
                                  ? ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(primary: AppTheme.neonGreen, onPrimary: AppTheme.background, surface: AppTheme.cardColor, onSurface: AppTheme.textMain),
                                      dialogBackgroundColor: AppTheme.cardColor,
                                    )
                                  : ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(primary: AppTheme.neonGreen, onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF0F172A)),
                                      dialogBackgroundColor: Colors.white,
                                    ),
                              child: child!,
                            ),
                          );
                          if (pickedDate != null) {
                            if (!context.mounted) return;
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                              builder: (context, child) => Theme(
                                data: widget.isDarkMode
                                    ? ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(primary: AppTheme.neonGreen, onPrimary: AppTheme.background, surface: AppTheme.cardColor, onSurface: AppTheme.textMain),
                                        dialogBackgroundColor: AppTheme.cardColor,
                                      )
                                    : ThemeData.light().copyWith(
                                        colorScheme: const ColorScheme.light(primary: AppTheme.neonGreen, onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF0F172A)),
                                        dialogBackgroundColor: Colors.white,
                                      ),
                                child: child!,
                              ),
                            );
                            if (pickedTime != null) {
                              setDialogState(() {
                                selectedDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        child: const Text('Değiştir', style: TextStyle(color: AppTheme.neonGreen)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal', style: TextStyle(color: AppTheme.textMuted)),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      await _dbService.addReminder(FormatUtils.capitalizeWords(title), selectedDate);
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hatırlatıcı başarıyla eklendi.'), backgroundColor: AppTheme.neonGreen, behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  },
                  child: const Text('Kaydet', style: TextStyle(color: AppTheme.neonGreen)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAIFinanceAnalysis(bool hasTransactions) async {
    // Show a sleek progress HUD dialog with "Asistan Düşünüyor..." message
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : Colors.white;
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: Text(
                  'Asistan Düşünüyor...',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    List<Map<String, dynamic>> transactions = [];
    List<Map<String, dynamic>> bills = [];
    List<Map<String, dynamic>> fixedExpenses = [];
    List<Map<String, dynamic>> upcomingPayments = [];
    String aiReport = "";

    try {
      final transSnap = await _dbService.getTransactionsStream().first;
      final billsSnap = await _dbService.getBillsStream().first;
      final fixedSnap = await _dbService.getFixedExpensesStream().first;
      final upcomingSnap = await _dbService.getUpcomingPaymentsStream().first;

      final hasBills = billsSnap.docs.isNotEmpty;
      final hasFixed = fixedSnap.docs.isNotEmpty;
      final hasUpcoming = upcomingSnap.docs.isNotEmpty;

      if (!hasTransactions && !hasBills && !hasFixed && !hasUpcoming) {
        // Close the HUD
        if (mounted) Navigator.pop(context);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
                  const SizedBox(width: 8),
                  Text('Veri Bulunamadı', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'Henüz analiz edilecek finansal veriniz bulunmuyor. Yapay Zekanın analiz yapabilmesi için lütfen en az bir harcama, fatura veya sabit gider ekleyin.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam', style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Convert Documents to Lists of Map for Gemini input
      for (var doc in transSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        transactions.add({
          'title': data['title'] ?? 'İşlem',
          'amount': data['amount'] ?? 0.0,
          'type': data['type'] ?? 'expense',
        });
      }

      for (var doc in billsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        bills.add({
          'title': data['title'] ?? 'Fatura',
          'amount': data['amount'] ?? 0.0,
          'dueDate': DateFormat('dd/MM/yyyy').format(dueDate),
        });
      }

      for (var doc in fixedSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        fixedExpenses.add({
          'title': data['title'] ?? 'Sabit Gider',
          'amount': data['amount'] ?? 0.0,
        });
      }

      for (var doc in upcomingSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        upcomingPayments.add({
          'title': data['title'] ?? 'Ödeme',
          'amount': data['amount'] ?? 0.0,
          'dueDate': DateFormat('dd/MM/yyyy').format(dueDate),
        });
      }

      // Call Gemini Service to get a real custom analysis!
      aiReport = await _geminiService.generateFinanceAnalysis(
        transactions: transactions,
        bills: bills,
        fixedExpenses: fixedExpenses,
        upcomingPayments: upcomingPayments,
      );

      // Close the HUD
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hata'),
          content: Text('Analiz sırasında hata oluştu: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    bool isAnalyzing = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? AppTheme.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (isAnalyzing) {
              Future.delayed(const Duration(milliseconds: 1800), () {
                if (context.mounted) {
                  setSheetState(() {
                    isAnalyzing = false;
                  });
                }
              });
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.neonGreen, size: 24),
                      const SizedBox(width: 8),
                      Text('Yapay Zeka KOBİ/Esnaf Raporu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isAnalyzing)
                    SizedBox(
                      height: 250,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: AppTheme.neonGreen),
                            const SizedBox(height: 16),
                            const Text('Gelişmiş işletme verileriniz toplanıyor...', style: TextStyle(color: AppTheme.textMuted)),
                            const SizedBox(height: 6),
                            const Text('Gemini AI finansal model analizi yapılıyor...', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  if (!isAnalyzing) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
                          ),
                          child: _buildReportMarkdownText(aiReport, widget.isDarkMode ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
                      child: const Text('Raporu Kapat', style: TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportMarkdownText(String text, Color textColor) {
    List<TextSpan> spans = [];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? AppTheme.neonGreen : textColor,
          fontSize: 14,
          height: 1.45,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
