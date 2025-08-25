import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String rupiah(num v) => _idr.format(v);

String dtHuman(DateTime dt) => DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(dt);
