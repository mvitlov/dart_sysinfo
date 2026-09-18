import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart';
import 'package:dart_sysinfo/src/core/abi_guard.dart';
import 'package:dart_sysinfo_flutter/dart_sysinfo_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mock_rust_lib_api.dart';

void main() {
  late MockRustLibApi mockRustLibApi;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockRustLibApi = MockRustLibApi();
    RustLib.initMock(api: mockRustLibApi);
  });

  setUp(() {
    mockRustLibApi
      ..initCalls = 0
      ..disposeCalls = 0
      ..initResult = const InitResult(
        createdFresh: true,
        abiVersion: AbiGuard.expectedAbi,
      );
    DartSysinfoFlutter.resetForTesting();
  });

  tearDown(() async {
    DartSysinfoFlutter.resetForTesting();
    SysInfo.resetForTesting();
    await SysInfo.disposeInstance();
  });

  test('ensureInitialized is idempotent', () async {
    await DartSysinfoFlutter.ensureInitialized();
    final disposeCallsAfterFirst = mockRustLibApi.disposeCalls;

    await DartSysinfoFlutter.ensureInitialized();

    expect(mockRustLibApi.disposeCalls, disposeCallsAfterFirst);
  });

  test('ensureInitialized clears stale native state via prepareFreshIsolate',
      () async {
    await DartSysinfoFlutter.ensureInitialized();

    expect(mockRustLibApi.disposeCalls, 1);
  });

  test('detached lifecycle triggers dispose path', () async {
    var detachedDisposeCalls = 0;
    DartSysinfoFlutter.onDetachedDisposeForTesting = () async {
      detachedDisposeCalls++;
    };

    await DartSysinfoFlutter.ensureInitialized();
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.detached,
    );
    await pumpEventQueue();

    expect(detachedDisposeCalls, 1);
  });
}
