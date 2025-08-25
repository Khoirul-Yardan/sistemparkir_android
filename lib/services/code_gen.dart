import 'dart:math';

String generateTicketCode() {
  final now = DateTime.now();
  final ts = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  final rand = Random().nextInt(9000) + 1000; // 4 digits
  return 'TCK-$ts-$rand';
}
