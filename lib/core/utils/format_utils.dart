import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class FormatUtils {
  static String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    return format.format(amount);
  }

  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    // Remove all non-digits
    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    
    final number = double.parse(cleanText);
    final formatted = NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 0).format(number).trim();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
