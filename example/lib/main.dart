import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:dart_sysinfo_flutter/dart_sysinfo_flutter.dart';
import 'package:example/p1_demo_page.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDartSysinfoBridge();
  await DartSysinfoFlutter.ensureInitialized();

  final pingResult = frbPlatformSmokePing();
  debugPrint('[SMOKE_TEST] frb_platform_smoke_ping() returned: $pingResult');

  const autoStartStream = bool.fromEnvironment('QA_AUTO_START');
  if (autoStartStream) {
    runApp(
      MyApp(
        pingResult: pingResult,
        autoStartStream: true,
      ),
    );
  } else {
    runApp(MyApp(pingResult: pingResult));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.pingResult,
    this.autoStartStream = false,
    super.key,
  });

  final int pingResult;
  final bool autoStartStream;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dart_sysinfo example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: P1DemoPage(
        smokePingResult: pingResult,
        autoStartStream: autoStartStream,
      ),
    );
  }
}
