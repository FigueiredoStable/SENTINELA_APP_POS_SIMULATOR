
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  /// Formata o texto para o formato monetário brasileiro
  final NumberFormat _formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.tryParse(newValue.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
    String newText = _formatter.format(value / 100); // Dividir por 100 para lidar com centavos

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  /// Converte o texto formatado de volta para um double
  double parseToDouble(String formattedText) {
    String rawText = formattedText.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.');
    return double.tryParse(rawText) ?? 0.0;
  }

  /// Formata um double para BRL
  String formatDoubleToCurrency(double value) {
    String formattedValueWithPrefix = " ${"R\$"}${_formatter.format(value)}";
    return formattedValueWithPrefix;
  }
}
