# dart_sysinfo example app

Demonstrates P1 domains (OS, CPU, memory) and a CPU load stream with observable
tick counts for hot-restart QA.

## Run locally

From this directory:

```bash
fvm flutter pub get
fvm flutter run -d macos
```

Use any supported desktop or mobile device instead of `macos` if preferred.

## Bootstrap order

The example wires lifecycle glue before the first `SysInfo.instance` access:

```dart
WidgetsFlutterBinding.ensureInitialized();
await initDartSysinfoBridge();
await DartSysinfoFlutter.ensureInitialized();
```

Flutter apps should depend on both `dart_sysinfo` and `dart_sysinfo_flutter`.

## Manual QA

Hot-restart verification (start CPU load stream → hot restart → no duplicate
workers) is documented in
[`docs/example-app-qa.md`](../docs/example-app-qa.md).
