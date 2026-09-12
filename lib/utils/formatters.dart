import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String inr(num? amount, {bool decimals = true}) {
    if (amount == null) return '₹0';
    if (decimals) {
      return _currencyFormat.format(amount);
    }
    return _compactCurrency.format(amount);
  }

  static String formatNumber(num? amount, {int decimals = 2}) {
    if (amount == null) return '0';
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: decimals,
    );
    return formatter.format(amount).trim();
  }

  static String todayISO() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String currentTimeStr() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  static String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd-MMM-yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd-MMM-yyyy hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String numberToWordsINR(num amount) {
    final intAmount = amount.floor();
    final paise = ((amount - intAmount) * 100).round();

    if (intAmount == 0 && paise == 0) return 'Zero Rupees Only';

    String words = _convertChunk(intAmount);
    if (words.isNotEmpty) words += ' Rupees';

    if (paise > 0) {
      final paiseWords = _convertChunk(paise);
      words += words.isNotEmpty ? ' and $paiseWords Paise' : '$paiseWords Paise';
    }

    return '$words Only';
  }

  static String _convertChunk(int n) {
    if (n == 0) return '';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    if (n < 20) return units[n];
    if (n < 100) {
      return '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${units[n % 10]}' : ''}';
    }
    if (n < 1000) {
      return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${_convertChunk(n % 100)}' : ''}';
    }
    if (n < 100000) {
      return '${_convertChunk(n ~/ 1000)} Thousand${n % 1000 != 0 ? ' ${_convertChunk(n % 1000)}' : ''}';
    }
    if (n < 10000000) {
      return '${_convertChunk(n ~/ 100000)} Lakh${n % 100000 != 0 ? ' ${_convertChunk(n % 100000)}' : ''}';
    }
    return '${_convertChunk(n ~/ 10000000)} Crore${n % 10000000 != 0 ? ' ${_convertChunk(n % 10000000)}' : ''}';
  }
}
