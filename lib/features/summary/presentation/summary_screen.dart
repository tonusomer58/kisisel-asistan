import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';

class SummaryScreen extends StatefulWidget {
  final bool isDarkMode;
  const SummaryScreen({Key? key, this.isDarkMode = true}) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _selectedRole = 0; // 0: Bireysel, 1: Esnaf/KOBİ
  int _chartFilterIndex = 3; // 0: Günlük, 1: Haftalık, 2: Aylık, 3: Tümü
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
    final bgColor = widget.isDarkMode ? AppTheme.background : const Color(0xFFF0F4F8);
    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: Text('Finansal Özet', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                _buildRoleToggle(),
                const SizedBox(height: 24),
                if (_selectedRole == 0) _buildBireyselView(docs) else _buildEsnafView(docs),
                const SizedBox(height: 80),
              ],
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

    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);

    return Column(
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
        const SizedBox(height: 24),
        _buildFilterToggle(),
        const SizedBox(height: 24),
        Text('Harcama Dağılımı', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor)),
        const SizedBox(height: 16),
        _buildPieChart(docs),
      ],
    );
  }

  Widget _buildEsnafView(List<QueryDocumentSnapshot> docs) {
    final textColor = widget.isDarkMode ? AppTheme.textMain : const Color(0xFF0F172A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterToggle(),
        const SizedBox(height: 24),
        Text('Nakit Akışı Trendi', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: textColor)),
        const SizedBox(height: 16),
        _buildLineChart(docs),
      ],
    );
  }

  Widget _buildPieChart(List<QueryDocumentSnapshot> docs) {
    Map<String, double> categoryTotals = {};
    double filteredTotal = 0;
    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      bool include = false;
      if (_chartFilterIndex == 0 && date.isAfter(now.subtract(const Duration(days: 1)))) include = true;
      else if (_chartFilterIndex == 1 && date.isAfter(now.subtract(const Duration(days: 7)))) include = true;
      else if (_chartFilterIndex == 2 && date.isAfter(DateTime(now.year, now.month, 1))) include = true;
      else if (_chartFilterIndex == 3) include = true;

      if (data['type'] == 'expense' && include) {
        final amount = (data['amount'] ?? 0).toDouble();
        final cat = data['category'] ?? 'Diğer';
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount;
        filteredTotal += amount;
      }
    }

    if (filteredTotal == 0) return const SizedBox(height: 200, child: Center(child: Text('Bu filtrede harcama yok', style: TextStyle(color: AppTheme.textMuted))));

    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);
    final colorMap = {
      'Market': AppTheme.electricBlue, 'Fatura': Colors.purpleAccent, 'Eğitim': Colors.orangeAccent,
      'Eğlence': primaryColor, 'Sağlık': Colors.pinkAccent, 'Diğer': Colors.blueGrey,
    };

    List<PieChartSectionData> sections = categoryTotals.entries.map((e) {
      final percentage = (e.value / filteredTotal * 100).toInt();
      return PieChartSectionData(color: colorMap[e.key] ?? Colors.blueGrey, value: e.value, title: '${e.key}\n%$percentage', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10));
    }).toList();

    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);

    return SizedBox(
      height: 250,
      child: Card(color: cardColor, child: Padding(padding: const EdgeInsets.all(16.0), child: PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 50, sections: sections)))),
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

    final cardColor = widget.isDarkMode ? AppTheme.cardColor : const Color(0xFFFFFFFF);
    final primaryColor = widget.isDarkMode ? AppTheme.neonGreen : const Color(0xFF2563EB);

    return SizedBox(
      height: 250,
      child: Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.only(right: 24.0, top: 24.0, bottom: 16.0, left: 16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1)),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < keys.length) {
                        return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(keys[value.toInt()], style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(FormatUtils.formatCurrency(value).replaceAll(' ₺', ''), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: maxX, minY: 0, maxY: actualMax > 0 ? actualMax * 1.2 : 10,
              lineBarsData: [
                LineChartBarData(spots: incomeSpots, isCurved: true, color: primaryColor, barWidth: 4, isStrokeCapRound: true, dotData: const FlDotData(show: true), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [primaryColor.withOpacity(0.3), primaryColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                LineChartBarData(spots: expenseSpots, isCurved: true, color: Colors.redAccent, barWidth: 4, isStrokeCapRound: true, dotData: const FlDotData(show: true), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.redAccent.withOpacity(0.3), Colors.redAccent.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              ],
            ),
          ),
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
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
