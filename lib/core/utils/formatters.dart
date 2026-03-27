import 'package:intl/intl.dart';

class AppFormatters {
  static const _locale = 'pt_BR';

  static final NumberFormat _currency = NumberFormat.currency(
    locale: _locale,
    symbol: 'R\$',
  );
  static final NumberFormat _quantity = NumberFormat('#,##0.##', _locale);
  static final NumberFormat _compact = NumberFormat.compact(locale: _locale);
  static final DateFormat _date = DateFormat('dd/MM/yyyy', _locale);
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm', _locale);

  static String currency(double value) => _currency.format(value);

  static String quantity(double value) => _quantity.format(value);

  static String compactNumber(double value) => _compact.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static double parseDecimal(String rawValue) {
    var normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '.');
    }

    return double.parse(normalized);
  }
}
