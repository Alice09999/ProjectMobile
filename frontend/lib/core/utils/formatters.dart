import 'package:intl/intl.dart';

String formatTanggal(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return DateFormat('dd MMM yyyy', 'id_ID').format(date);
}

String toIsoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
