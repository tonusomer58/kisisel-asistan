import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _selectedRole = 0; // 0: Bireysel, 1: Esnaf/KOBİ
  final DatabaseService _dbService = DatabaseService();

  void _showAddTransactionSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense'; // default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                    'İşlem Ekle',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'income', label: Text('Gelir')),
                      ButtonSegment(value: 'expense', label: Text('Gider')),
                    ],
                    selected: {type},
                    onSelectionChanged: (Set<String> newSelection) {
                      setModalState(() {
                        type = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return type == 'income' ? AppTheme.neonGreen : Colors.redAccent;
                          }
                          return Colors.transparent;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.background;
                          }
                          return AppTheme.textMuted;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppTheme.textMain),
                    decoration: const InputDecoration(
                      labelText: 'İşlem Adı (Örn: Maaş, Market)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    style: const TextStyle(color: AppTheme.textMain),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tutar (₺)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (title.isNotEmpty && amount > 0) {
                        await _dbService.addTransaction(title, amount, type);
                        if (context.mounted) Navigator.pop(context);
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
        title: const Text('Finansal Özet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role Toggle
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Bireysel', 0),
                    _buildToggleButton('Esnaf', 1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_selectedRole == 0) ...[
              _buildBireyselView(),
            ] else ...[
              _buildEsnafView(),
            ],
            
            const SizedBox(height: 80), // Fab için boşluk
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: AppTheme.neonGreen,
        child: const Icon(Icons.add, color: AppTheme.background, size: 32),
      ),
    );
  }

  Widget _buildToggleButton(String title, int index) {
    final isSelected = _selectedRole == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.background : AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBireyselView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'Toplam Harcama',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '₺14,250',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Harcama Dağılımı',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      color: AppTheme.electricBlue,
                      value: 40,
                      title: 'Market\n%40',
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: Colors.purpleAccent,
                      value: 25,
                      title: 'Fatura\n%25',
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: AppTheme.neonGreen,
                      value: 20,
                      title: 'Eğlence\n%20',
                      radius: 60,
                      titleStyle: const TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: Colors.orangeAccent,
                      value: 15,
                      title: 'Ulaşım\n%15',
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEsnafView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aylık Nakit Akışı',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0, top: 24.0, bottom: 16.0, left: 16.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Oca', 'Şub', 'Mar', 'Nis', 'May'];
                          if (value.toInt() >= 0 && value.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(titles[value.toInt()], style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value % 2 != 0) return const SizedBox.shrink();
                          return Text('${value.toInt()}k', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 4,
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 4),
                        FlSpot(1, 6),
                        FlSpot(2, 5),
                        FlSpot(3, 8),
                        FlSpot(4, 7),
                      ],
                      isCurved: true,
                      color: AppTheme.neonGreen,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.neonGreen.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Yaklaşan Ödemeler',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        _buildPaymentItem('Tedarikçi Ödemesi', '₺12,500', 'Yarın', Colors.orangeAccent),
        const SizedBox(height: 12),
        _buildPaymentItem('Dükkan Kirası', '₺8,000', '3 Gün Sonra', AppTheme.electricBlue),
        const SizedBox(height: 12),
        _buildPaymentItem('Vergi Taksiti', '₺4,200', '1 Hafta Sonra', Colors.purpleAccent),
      ],
    );
  }

  Widget _buildPaymentItem(String title, String amount, String date, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.payment, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
        subtitle: Text(date, style: const TextStyle(color: AppTheme.textMuted)),
        trailing: Text(
          amount,
          style: const TextStyle(
            color: AppTheme.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
