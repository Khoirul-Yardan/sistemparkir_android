import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'pages/dashboard_page.dart';
import 'pages/masuk_page.dart';
import 'pages/keluar_page.dart';
import 'pages/rekap_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  await initializeDateFormatting('id_ID', null);

  runApp(const ParkirApp());
}

class ParkirApp extends StatelessWidget {
  const ParkirApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF3659FF),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      cardTheme: CardThemeData(
        color: const Color(0xFF121A2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(12),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );

    return MaterialApp(
      title: 'Sistem Parkir Offline',
      theme: theme,
      debugShowCheckedModeBanner: false,
      // PERUBAHAN: Langsung arahkan ke LoginPage sebagai halaman utama
      home: const LoginPage(),
    );
  }
}


// Widget AuthWrapper sudah tidak diperlukan lagi dan bisa dihapus


class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  final _pages = const [
    DashboardPage(),
    MasukPage(),
    KeluarPage(),
    RekapPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final nav = NavigationDestinationLabelBehavior.alwaysShow;
        final items = const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.login),
            selectedIcon: Icon(Icons.login),
            label: 'Masuk',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout),
            selectedIcon: Icon(Icons.logout),
            label: 'Keluar',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Rekap',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];

        final content = Scaffold(
          appBar: AppBar(
            title: const Text('Sistem Parkir Offline'),
          ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  leading: const SizedBox(height: 8),
                  destinations: items
                      .map((e) => NavigationRailDestination(
                          icon: e.icon,
                          selectedIcon: e.selectedIcon,
                          label: Text(e.label)))
                      .toList(),
                ),
              Expanded(child: _pages[_index]),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  destinations: items,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelBehavior: nav,
                ),
        );

        return content;
      },
    );
  }
}