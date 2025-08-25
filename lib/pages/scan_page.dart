import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  final void Function(String kode) onDetect;
  const ScanPage({super.key, required this.onDetect});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Tiket')),
      body: Stack(children: [
        MobileScanner(
          onDetect: (capture) {
            if (_done) return;
            final barcodes = capture.barcodes;
            for (final b in barcodes) {
              final raw = b.rawValue;
              if (raw != null && raw.startsWith('TCK-')) {
                _done = true;
                widget.onDetect(raw);
                Navigator.pop(context);
                break;
              }
            }
          },
        ),
        Align(alignment: Alignment.bottomCenter, child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Arahkan kamera ke QR tiket', style: Theme.of(context).textTheme.bodyLarge),
        )),
      ]),
    );
  }
}
