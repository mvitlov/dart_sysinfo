import 'package:dart_sysinfo/dart_sysinfo.dart';

Future<void> main() async {
  await SysInfo.instance.network.snapshot();
}
