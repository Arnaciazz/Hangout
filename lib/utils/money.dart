/// Money helpers. Amounts are integer **paise** everywhere, matching the
/// database, so nothing is lost to floating point.
library;

/// "₹1,00,000", "₹1,234.50". Indian digit grouping; paise shown only when
/// there are any.
String formatRupees(int paise) {
  final negative = paise < 0;
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final rest = abs % 100;

  final digits = rupees.toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (head.length > 2) {
      parts.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) parts.insert(0, head);
    grouped = '${parts.join(',')},$last3';
  }

  final paisePart = rest == 0 ? '' : '.${rest.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}₹$grouped$paisePart';
}

/// Parses what a person types ("1,234", "1234.5", "₹ 850") into paise.
/// Returns null for anything that isn't a positive amount with at most two
/// decimal places.
int? parseRupees(String input) {
  final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '');
  final match = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final rupees = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final paise = rupees * 100 + int.parse(fraction.isEmpty ? '0' : fraction);
  return paise > 0 ? paise : null;
}

/// Splits [totalPaise] across [count] people exactly as the database does:
/// everyone gets the same, and the leftover paise go one each to the first
/// people. The result always adds back up to the total.
List<int> splitEvenly(int totalPaise, int count) {
  if (count <= 0) return const [];
  final base = totalPaise ~/ count;
  final remainder = totalPaise % count;
  return [for (var i = 0; i < count; i++) base + (i < remainder ? 1 : 0)];
}

/// Same rule as the database's `create_bill`: a handle, "@", then a bank or
/// app suffix (name@okicici, 9876543210@ybl).
final _upiPattern = RegExp(r'^[A-Za-z0-9._-]{2,64}@[A-Za-z][A-Za-z0-9]{1,63}$');

bool isValidUpiId(String value) => _upiPattern.hasMatch(value.trim());

/// A `upi://pay` link that opens the phone's UPI app (GPay, PhonePe, Paytm…)
/// prefilled. Hangout never moves money; the UPI app does.
Uri upiPaymentUri({
  required String payeeUpi,
  required String payeeName,
  required int amountPaise,
  required String note,
}) {
  final amount =
      '${amountPaise ~/ 100}.${(amountPaise % 100).toString().padLeft(2, '0')}';
  // The UPI ID is validated to safe characters, so it goes in unescaped:
  // some UPI apps don't decode "%40" in the payee address.
  final query = [
    'pa=${payeeUpi.trim()}',
    'pn=${Uri.encodeQueryComponent(payeeName)}',
    'am=$amount',
    'cu=INR',
    'tn=${Uri.encodeQueryComponent(note)}',
  ].join('&');
  return Uri.parse('upi://pay?$query');
}
