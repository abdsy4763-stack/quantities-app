/// Number helpers (no intl dependency needed).
String fmt(double v, [int decimals = 2]) {
  final neg = v < 0;
  final s = v.abs().toStringAsFixed(decimals);
  final parts = s.split('.');
  final ip = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < ip.length; i++) {
    if (i > 0 && (ip.length - i) % 3 == 0) buf.write(',');
    buf.write(ip[i]);
  }
  final out = parts.length > 1 ? '$buf.${parts[1]}' : buf.toString();
  return neg ? '-$out' : out;
}

/// Parses user input, accepting Arabic-Indic digits and the Arabic decimal comma.
double parseNum(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in s.trim().split('')) {
    final i = ar.indexOf(ch);
    if (i >= 0) {
      b.write(i);
    } else if (ch == '،' || ch == ',' || ch == '٫') {
      b.write('.');
    } else {
      b.write(ch);
    }
  }
  return double.tryParse(b.toString()) ?? 0;
}

String numText(double v) {
  if (v == 0) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
