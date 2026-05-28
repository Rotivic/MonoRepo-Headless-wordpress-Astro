import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

DateTime? parseApiDateTime(String? value) {
  if (value == null) return null;

  final v = value.trim();
  if (v.isEmpty) return null;

  try {
    return DateTime.parse(v);
  } catch (_) {}

  try {
    return DateTime.parse(v.replaceFirst(' ', 'T'));
  } catch (_) {}

  return null;
}

String formatUiDateTime(BuildContext context, DateTime? dt) {
  if (dt == null) return '-';
  final locale = Localizations.localeOf(context).toString();
  return DateFormat('dd/MM/yyyy HH:mm', locale).format(dt.toLocal());
}
