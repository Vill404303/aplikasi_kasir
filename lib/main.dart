import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/printer_service.dart';
import 'services/database_service.dart';
import 'screens/transaction_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/printer_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrinterService.loadProfiles();
  await initializeDateFormatting('id_ID', null);
  await DatabaseService.autoCleanHistory();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const KasirSnackApp());
}

class KasirSnackApp extends StatelessWidget {
  const KasirSnackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir Snack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange,
          surface: Color(0xFF16213E),
        ),
        fontFamily: 'sans-serif',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _screens = const [
    TransactionScreen(),
    ExpenseScreen(),
    HistoryScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF16213E),
          border: Border(top: BorderSide(color: Color(0xFF0F3460), width: 1)),
        ),
        child: Row(
          children: [
            _navItem(0, Icons.calculate_rounded, 'Transaksi', Colors.orange),
            _navItem(
              1,
              Icons.arrow_upward_rounded,
              'Pengeluaran',
              Colors.redAccent,
            ),
            _navItem(2, Icons.history_rounded, 'History', Colors.tealAccent),
            _navItem(3, Icons.bar_chart_rounded, 'Laporan', Colors.orange),
            _printerItem(),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label, Color activeColor) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? activeColor : Colors.white38,
                size: 21,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: active ? activeColor : Colors.white38,
                  fontSize: 9,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _printerItem() {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.print_rounded,
                color: PrinterService.isConnected
                    ? Colors.green
                    : Colors.white38,
                size: 21,
              ),
              const SizedBox(height: 3),
              Text(
                'Printer',
                style: TextStyle(
                  color: PrinterService.isConnected
                      ? Colors.green
                      : Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
