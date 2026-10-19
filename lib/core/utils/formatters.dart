String formatPrice(double value) => '\$${value.toStringAsFixed(2)}';

String formatDiscount(double percent) => '-${percent.round()}%';

/// Keeps only the date part of an ISO-8601 timestamp, e.g. 2025-04-30.
String formatIsoDate(String? iso) {
  if (iso == null || iso.length < 10) return '';
  return iso.substring(0, 10);
}
