String? stringFromJson(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

int? intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int intFromJsonOrZero(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double? doubleFromJson(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool boolFromJson(dynamic v) {
  if (v is bool) return v;
  final s = v?.toString().toLowerCase();
  return s == '1' || s == 'true';
}
