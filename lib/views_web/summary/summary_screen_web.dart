import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';

class SummaryScreenWeb extends StatefulWidget {
  final bool isDarkMode;
  const SummaryScreenWeb({Key? key, this.isDarkMode = true}) : super(key: key);

  @override
  State<SummaryScreenWeb> createState() => _SummaryScreenWebState();
}

class _SummaryScreenWebState extends State<SummaryScreenWeb> {
  int _selectedRole = 0; // 0: Bireysel, 1: Esnaf/KOBİ
  int _chartFilterIndex = 3; // 0: Günlük, 1: Haftalık, 2: Aylık, 3: Tümü
  final DatabaseService _dbService = DatabaseService();
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
          if (_userRole == 'bireysel') {
            _selectedRole = 0;
          }
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
    String type = 'expense';
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
                    Text('İşlem Ekle', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor, fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (_isRoleLoading) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_userRole == 'sme') ...[
                  _buildRoleToggle(),
                  const SizedBox(height: 24),
                ],
                if (_selectedRole == 0 || _userRole == 'bireysel') _buildBireyselView(docs) else _buildEsnafView(docs),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.account_balance_wallet, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'Henüz analiz edilecek veri yok.',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: widget.isDarkMode ? AppTheme.textMuted : const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text('Aşağıdaki + butonundan hemen ekle!', style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildRoleToggle() {
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    return Center(
      child: Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton('Bireysel', 0),
            _buildToggleButton('Esnaf', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String title, int index) {
    final isSelected = _selectedRole == index;
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(30)),
        child: Text(title, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterToggle() {
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Günlük')),
            ButtonSegment(value: 1, label: Text('Haftalık')),
            ButtonSegment(value: 2, label: Text('Aylık')),
            ButtonSegment(value: 3, label: Text('Tümü')),
          ],
          selected: {_chartFilterIndex},
          onSelectionChanged: (newSelection) => setState(() => _chartFilterIndex = newSelection.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? primaryColor : Colors.transparent),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) => states.contains(WidgetState.selected) ? Colors.white : AppTheme.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildBireyselView(List<QueryDocumentSnapshot> docs) {
    double totalIncome = 0;
    double totalExpense = 0;
    double todayExpense = 0;
    double weekExpense = 0;
    double monthExpense = 0;
    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0).toDouble();
      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      if (data['type'] == 'income') {
        totalIncome += amount;
      } else if (data['type'] == 'expense') {
        totalExpense += amount;
        if (date.year == now.year && date.month == now.month && date.day == now.day) todayExpense += amount;
        if (date.isAfter(now.subtract(const Duration(days: 7)))) weekExpense += amount;
        if (date.year == now.year && date.month == now.month) monthExpense += amount;
      }
    }
    final netBalance = totalIncome - totalExpense;

    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol Sütun (%60)
        Expanded(
          flex: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Net Bakiye
              Card(
                color: cardColor,
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text('Net Bakiye', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        FormatUtils.formatCurrency(netBalance),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: netBalance >= 0 ? primaryColor : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Gelir / Gider Satırı
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.arrow_upward_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              const Text('Toplam Gelir', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                            ]),
                            const SizedBox(height: 8),
                            Text(FormatUtils.formatCurrency(totalIncome), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.arrow_downward_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              const Text('Toplam Gider', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                            ]),
                            const SizedBox(height: 8),
                            Text(FormatUtils.formatCurrency(totalExpense), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Günlük / Haftalık / Aylık Mini Kartlar
              Row(
                children: [
                  _buildSummaryMiniCard('Günlük Gider', todayExpense),
                  const SizedBox(width: 12),
                  _buildSummaryMiniCard('Haftalık Gider', weekExpense),
                  const SizedBox(width: 12),
                  _buildSummaryMiniCard('Aylık Gider', monthExpense),
                ],
              ),
              const SizedBox(height: 32),
              _buildFilterToggle(),
              const SizedBox(height: 32),
              // Nakit Akışı Trendi
              Text('Nakit Akışı Trendi', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildLineChart(docs),
              const SizedBox(height: 48),
              // Dağılımlar Yan Yana (Pie Charts)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Harcama Dağılımı', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        _buildPieChart(docs, type: 'expense'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Gelir Dağılımı', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        _buildPieChart(docs, type: 'income'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        // Sağ Sütun (%40)
        Expanded(
          flex: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Yaklaşan Ödemeler
              StreamBuilder<QuerySnapshot>(
                stream: _dbService.getUpcomingPaymentsStream(),
                builder: (context, upSnap) {
                  final upDocs = upSnap.hasData ? upSnap.data!.docs : [];
                  if (upDocs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Yaklaşan Ödemelerim', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ...upDocs.take(5).map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final rawTitle = data['title'] ?? 'Ödeme';
                        String title = rawTitle.replaceAll(RegExp(r'^[^a-zA-Z0-9ğĞüÜşŞıİöÖçÇ]+'), '');
                        if (title.isEmpty) title = rawTitle;
                        title = FormatUtils.capitalizeWords(title);
                        final amount = (data['amount'] ?? 0.0).toDouble();
                        final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? now;
                        final daysLeft = dueDate.difference(now).inDays;
                        final isUrgent = daysLeft <= 3;
                        return Card(
                          color: cardColor,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isUrgent ? Colors.redAccent.withOpacity(0.4) : (widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.1)),
                              width: 1.2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: (isUrgent ? Colors.redAccent : primaryColor).withOpacity(0.15),
                              radius: 24,
                              child: Icon(Icons.payment_outlined, color: isUrgent ? Colors.redAccent : primaryColor, size: 24),
                            ),
                            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                daysLeft <= 0 ? 'Bugün!' : '$daysLeft gün kaldı',
                                style: TextStyle(color: isUrgent ? Colors.redAccent : AppTheme.textMuted, fontSize: 14, fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal),
                              ),
                            ),
                            trailing: Text(FormatUtils.formatCurrency(amount), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
              // Son İşlemler (Artık Sağ Sütunda Container içinde)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Son İşlemler', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: _showAddTransactionSheet,
                              icon: Icon(Icons.add_circle, color: primaryColor, size: 28),
                              tooltip: 'Yeni İşlem Ekle',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      SizedBox(
                        height: 500, // İşlemlerin uzamasını engellemek için scrollable alan
                        child: _buildTransactionsList(docs),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEsnafView(List<QueryDocumentSnapshot> docs) {
    double totalIncome = 0;
    double totalExpense = 0;
    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      bool include = false;
      if (_chartFilterIndex == 0 && date.isAfter(now.subtract(const Duration(days: 1)))) include = true;
      else if (_chartFilterIndex == 1 && date.isAfter(now.subtract(const Duration(days: 7)))) include = true;
      else if (_chartFilterIndex == 2 && date.isAfter(DateTime(now.year, now.month, 1))) include = true;
      else if (_chartFilterIndex == 3) include = true;

      if (include) {
        final amount = (data['amount'] ?? 0).toDouble();
        if (data['type'] == 'income') {
          totalIncome += amount;
        } else if (data['type'] == 'expense') {
          totalExpense += amount;
        }
      }
    }

    final netCashFlow = totalIncome - totalExpense;
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);

    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.getFixedExpensesStream(),
      builder: (context, fixedSnapshot) {
        double totalFixedExpense = 0;
        final fixedDocs = fixedSnapshot.hasData ? fixedSnapshot.data!.docs : <QueryDocumentSnapshot>[];
        for (var doc in fixedDocs) {
          final data = doc.data() as Map<String, dynamic>;
          totalFixedExpense += (data['amount'] ?? 0).toDouble();
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol Sütun (%60)
            Expanded(
              flex: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Esnaf Summary Cards
                  Card(
                    color: cardColor,
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text('Dönem Net Kar/Zarar', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            FormatUtils.formatCurrency(netCashFlow),
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: netCashFlow >= 0 ? primaryColor : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: cardColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                            child: Column(
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.arrow_upward_rounded, color: primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Toplam Gelir', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                                ]),
                                const SizedBox(height: 8),
                                Text(FormatUtils.formatCurrency(totalIncome), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          color: cardColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                            child: Column(
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.arrow_downward_rounded, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Toplam Gider', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                                ]),
                                const SizedBox(height: 8),
                                Text(FormatUtils.formatCurrency(totalExpense), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          color: cardColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3), width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                            child: Column(
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.business_center, color: Colors.orangeAccent, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Sabit Gider', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                                ]),
                                const SizedBox(height: 8),
                                Text(FormatUtils.formatCurrency(totalFixedExpense), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildFilterToggle(),
                  const SizedBox(height: 32),
                  Text('Nakit Akışı Trendi', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildLineChart(docs),
                  const SizedBox(height: 48),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Gider Dağılımı', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            _buildPieChart(docs, type: 'expense'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Gelir Dağılımı', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            _buildPieChart(docs, type: 'income'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text('Sabit Gider Dağılımı', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  _buildPieChart(fixedDocs, type: 'fixed_expense'),
                ],
              ),
            ),
            const SizedBox(width: 48),
            // Sağ Sütun (%40)
            Expanded(
              flex: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Aktif Sabit Giderler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Aktif Sabit Giderler', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor, fontWeight: FontWeight.bold)),
                if (fixedDocs.isNotEmpty)
                  Text(
                    '${fixedDocs.length} Gider',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (fixedDocs.isEmpty)
              Card(
                color: cardColor,
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('Kayıtlı sabit gider bulunmuyor.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ),
              )
            else
              Column(
                children: fixedDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String title = data['title'] ?? 'Sabit Gider';
                  final double amount = (data['amount'] ?? 0).toDouble();

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                        child: const Icon(Icons.business_center, color: Colors.orangeAccent),
                      ),
                      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      subtitle: const Text('Her ay tekrarlanır', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(FormatUtils.formatCurrency(amount), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.orangeAccent),
                            tooltip: 'Ödendi Olarak İşaretle',
                            onPressed: () async {
                              await _dbService.payFixedExpense(title, amount);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$title için ödeme kaydedildi!'),
                                    backgroundColor: primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPieChart(List<QueryDocumentSnapshot> docs, {String type = 'expense'}) {
    Map<String, double> categoryTotals = {};
    double filteredTotal = 0;
    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      bool include = false;
      if (type == 'fixed_expense' || type == 'bill') {
        include = true;
      } else {
        if (_chartFilterIndex == 0 && date.isAfter(now.subtract(const Duration(days: 1)))) include = true;
        else if (_chartFilterIndex == 1 && date.isAfter(now.subtract(const Duration(days: 7)))) include = true;
        else if (_chartFilterIndex == 2 && date.isAfter(DateTime(now.year, now.month, 1))) include = true;
        else if (_chartFilterIndex == 3) include = true;
      }

      if (include) {
        final amount = (data['amount'] ?? 0).toDouble();
        if (type == 'expense' && data['type'] == 'expense') {
          final cat = data['category'] ?? 'Diğer';
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount;
          filteredTotal += amount;
        } else if (type == 'income' && data['type'] == 'income') {
          final title = data['title'] ?? 'Diğer';
          categoryTotals[title] = (categoryTotals[title] ?? 0) + amount;
          filteredTotal += amount;
        } else if (type == 'fixed_expense') {
          final title = data['title'] ?? 'Diğer';
          categoryTotals[title] = (categoryTotals[title] ?? 0) + amount;
          filteredTotal += amount;
        } else if (type == 'bill') {
          final title = data['title'] ?? 'Diğer';
          categoryTotals[title] = (categoryTotals[title] ?? 0) + amount;
          filteredTotal += amount;
        }
      }
    }

    if (filteredTotal == 0) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            type == 'income'
                ? 'Bu filtrede gelir verisi yok'
                : type == 'fixed_expense'
                    ? 'Bu filtrede sabit gider verisi yok'
                    : type == 'bill'
                        ? 'Bu filtrede fatura verisi yok'
                        : 'Bu filtrede gider verisi yok',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    
    // Gelir, Gider, Sabit Gider ve Faturalar için özel renk paletleri
    final colorMap = type == 'income'
        ? {
            'Maaş': primaryColor,
            'Satış': Colors.tealAccent,
            'Yatırım': Colors.cyanAccent,
            'Hizmet': Colors.greenAccent,
            'Diğer': Colors.blueGrey,
          }
        : type == 'fixed_expense'
            ? {
                'Kira': Colors.deepOrangeAccent,
                'Maaş': Colors.orangeAccent,
                'Fatura': Colors.redAccent,
                'Muhasebe': Colors.amberAccent,
                'Diğer': Colors.blueGrey,
              }
            : type == 'bill'
                ? {
                    'Elektrik': Colors.blueAccent,
                    'Su': Colors.cyanAccent,
                    'Doğalgaz': Colors.orangeAccent,
                    'İnternet': Colors.tealAccent,
                    'Diğer': Colors.blueGrey,
                  }
                : {
                    'Market': AppTheme.electricBlue,
                    'Fatura': Colors.purpleAccent,
                    'Eğitim': Colors.orangeAccent,
                    'Eğlence': primaryColor,
                    'Sağlık': Colors.pinkAccent,
                    'Diğer': Colors.blueGrey,
                  };

    // Bilinmeyen / dinamik kategoriler için yedek şık renkler
    final List<Color> dynamicColors = [
      Colors.teal,
      Colors.greenAccent,
      Colors.lightGreenAccent,
      Colors.cyan,
      Colors.amberAccent,
      Colors.indigoAccent,
      Colors.limeAccent,
    ];
    int colorIndex = 0;

    List<PieChartSectionData> sections = categoryTotals.entries.map((e) {
      final percentage = (e.value / filteredTotal * 100).toInt();
      Color color = colorMap[e.key] ?? Colors.blueGrey;
      if (color == Colors.blueGrey && e.key != 'Diğer') {
        color = dynamicColors[colorIndex % dynamicColors.length];
        colorIndex++;
      }

      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '%$percentage',
        radius: 50,
        showTitle: true,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      );
    }).toList();

    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 230,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 48,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categoryTotals.entries.map((e) {
                      final percentage = (e.value / filteredTotal * 100).toInt();
                      Color color = colorMap[e.key] ?? Colors.blueGrey;
                      if (color == Colors.blueGrey && e.key != 'Diğer') {
                        // sections ile aynı rengi alması için index bazlı yedek renk eşleşmesi yapıyoruz
                        final keysList = categoryTotals.keys.toList();
                        final keyIdx = keysList.indexOf(e.key);
                        color = dynamicColors[keyIdx % dynamicColors.length];
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.key,
                                style: TextStyle(color: textColor, fontSize: 14.5, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              FormatUtils.formatCurrency(e.value),
                              style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 15.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    var filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      if (_chartFilterIndex == 0) return date.isAfter(now.subtract(const Duration(days: 1)));
      if (_chartFilterIndex == 1) return date.isAfter(now.subtract(const Duration(days: 7)));
      if (_chartFilterIndex == 2) return date.isAfter(DateTime(now.year, now.month, 1));
      return true; // Tümü
    }).toList().reversed.toList();

    if (filteredDocs.isEmpty) return const SizedBox(height: 250, child: Center(child: Text('Bu filtrede veri yok', style: TextStyle(color: AppTheme.textMuted))));

    Map<String, Map<String, double>> groupedData = {};
    double actualMax = 0;

    for (var doc in filteredDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0).toDouble();
      final type = data['type'] ?? 'expense';
      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      
      String key;
      if (_chartFilterIndex == 0) key = DateFormat('HH:00').format(date);
      else if (_chartFilterIndex == 1) key = DateFormat('dd MMM').format(date);
      else if (_chartFilterIndex == 2) key = DateFormat('dd MMM').format(date);
      else key = DateFormat('MM/yyyy').format(date);

      if (!groupedData.containsKey(key)) groupedData[key] = {'income': 0.0, 'expense': 0.0};
      groupedData[key]![type] = groupedData[key]![type]! + amount;

      if (groupedData[key]!['income']! > actualMax) actualMax = groupedData[key]!['income']!;
      if (groupedData[key]!['expense']! > actualMax) actualMax = groupedData[key]!['expense']!;
    }

    final keys = groupedData.keys.toList();
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    for (int i = 0; i < keys.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), groupedData[keys[i]]!['income']!));
      expenseSpots.add(FlSpot(i.toDouble(), groupedData[keys[i]]!['expense']!));
    }

    // CRASH PROTECTION: If there's only 1 point, line chart fails to draw a curve properly. We add a dummy visual constraint.
    double maxX = keys.length > 1 ? (keys.length - 1).toDouble() : 1.0;
    if (keys.length == 1) {
      incomeSpots.add(FlSpot(1.0, groupedData[keys[0]]!['income']!));
      expenseSpots.add(FlSpot(1.0, groupedData[keys[0]]!['expense']!));
    }

    final lastIncomeY = incomeSpots.isNotEmpty ? incomeSpots.last.y : 0.0;
    final lastExpenseY = expenseSpots.isNotEmpty ? expenseSpots.last.y : 0.0;

    String formatValue(double value) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M ₺';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K ₺';
      } else {
        return '${value.toStringAsFixed(0)} ₺';
      }
    }

    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final gridColor = widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => cardColor.withOpacity(0.95),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isIncome = spot.barIndex == 0;
                          final typeText = isIncome ? 'Gelir' : 'Gider';
                          final color = isIncome ? primaryColor : Colors.redAccent;
                          return LineTooltipItem(
                            '$typeText: ${FormatUtils.formatCurrency(spot.y)}',
                            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();
                          if (index >= 0 && index < keys.length && value % 1 == 0) {
                            // Çok fazla veri noktası olduğunda yazıların üst üste binmesini önlemek için akıllı atlama mantığı
                            bool showLabel = true;
                            if (keys.length > 5) {
                              final interval = (keys.length / 4).ceil();
                              showLabel = index % interval == 0 || index == keys.length - 1;
                            }
                            
                            if (showLabel) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  keys[index],
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        interval: (actualMax / 4) > 0 ? (actualMax / 4) : 2.5,
                        getTitlesWidget: (value, meta) {
                          String label;
                          if (value >= 1000000) {
                            label = '${(value / 1000000).toStringAsFixed(1)}M ₺';
                          } else if (value >= 1000) {
                            label = '${(value / 1000).toStringAsFixed(0)}K ₺';
                          } else {
                            label = '${value.toStringAsFixed(0)} ₺';
                          }
                          return Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (lastIncomeY > 0)
                        HorizontalLine(
                          y: lastIncomeY,
                          color: primaryColor.withOpacity(0.4),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 12, bottom: 4),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            labelResolver: (line) => 'Gelir: ${formatValue(line.y)}',
                          ),
                        ),
                      if (lastExpenseY > 0)
                        HorizontalLine(
                          y: lastExpenseY,
                          color: Colors.redAccent.withOpacity(0.4),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 12, bottom: 4),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            labelResolver: (line) => 'Gider: ${formatValue(line.y)}',
                          ),
                        ),
                    ],
                  ),
                  minX: 0, maxX: maxX, minY: 0, maxY: actualMax > 0 ? actualMax : 10.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.redAccent.withOpacity(0.2), Colors.redAccent.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(width: 14, height: 4, color: primaryColor),
                    const SizedBox(width: 6),
                    Text('Gelir', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Container(width: 14, height: 4, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Text('Gider', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<QueryDocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final String title = data['title'] ?? 'İşlem';
        final double amount = (data['amount'] ?? 0).toDouble();
        final String type = data['type'] ?? 'expense';
        final DateTime date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
        final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);

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
            await _dbService.deleteTransaction(doc.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem silindi'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
            }
          },
          child: Card(
            color: widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF),
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
}
