import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDartSysinfoBridge();

  final pingResult = frbPlatformSmokePing();
  debugPrint('[SMOKE_TEST] frb_platform_smoke_ping() returned: $pingResult');

  runApp(MyApp(pingResult: pingResult));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.pingResult, super.key});

  final int pingResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('dart_sysinfo smoke test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('FFI Round-trip Smoke Test:'),
              const SizedBox(height: 12),
              Text(
                'frb_platform_smoke_ping() = $pingResult',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pingResult == 42 ? 'SUCCESS (42)' : 'UNEXPECTED RESULT',
                style: TextStyle(
                  color: pingResult == 42 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
