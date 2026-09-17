import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Smoke test app renders ping result',
    (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(pingResult: 42));

    expect(find.text('FFI Round-trip Smoke Test:'), findsOneWidget);
    expect(find.text('frb_platform_smoke_ping() = 42'), findsOneWidget);
    expect(find.text('SUCCESS (42)'), findsOneWidget);
    },
  );
}
