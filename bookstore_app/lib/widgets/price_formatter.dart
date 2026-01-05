String formatPrice(double value) {
  final formatted = value.toStringAsFixed(0);
  return '$formatted\u00A0VND';
}

