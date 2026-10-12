/// Mimics VBA's Round(x, n): banker's rounding (half to even) applied to the
/// 15-significant-digit decimal value of the double, so 2.675 -> 2.68 like Excel.
double vbaRound(double x, [int n = 2]) {
  if (x.isNaN || x.isInfinite || x == 0) return x;
  final neg = x < 0;
  final s = x.abs().toStringAsPrecision(15);
  if (s.contains('e') || s.contains('E')) {
    // Out of the normal range (tiny or huge): plain rounding is good enough.
    final p = _pow10(n);
    return (x * p).roundToDouble() / p;
  }
  final dot = s.indexOf('.');
  final intPart = dot < 0 ? s : s.substring(0, dot);
  final frac = dot < 0 ? '' : s.substring(dot + 1);
  if (frac.length <= n) return x;
  final keep = frac.substring(0, n);
  final rest = frac.substring(n);
  var digits = BigInt.parse(intPart + keep);
  final first = rest.codeUnitAt(0) - 48;
  final anyAfter = rest.substring(1).codeUnits.any((c) => c != 48);
  bool up;
  if (first > 5 || (first == 5 && anyAfter)) {
    up = true;
  } else if (first == 5) {
    up = digits.isOdd; // exact tie -> round to even
  } else {
    up = false;
  }
  if (up) digits += BigInt.one;
  var str = digits.toString().padLeft(n + 1, '0');
  final cut = str.length - n;
  final out = n == 0 ? str : '${str.substring(0, cut)}.${str.substring(cut)}';
  final v = double.parse(out);
  return neg ? -v : v;
}

double _pow10(int n) {
  var p = 1.0;
  for (var i = 0; i < n; i++) {
    p *= 10;
  }
  return p;
}
