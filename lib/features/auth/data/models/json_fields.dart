// Internal parsing helpers. Error messages never include field values.
T requiredField<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! T) {
    throw FormatException('Expected $key to be a non-null $T.');
  }
  return value;
}

T? optionalField<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! T) {
    throw FormatException('Expected $key to be a $T or null.');
  }
  return value;
}
