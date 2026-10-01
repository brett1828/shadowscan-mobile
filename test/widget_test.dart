import 'package:flutter_test/flutter_test.dart';
import 'package:shadowscan_mobile/main.dart';

void main() {
  testWidgets('ShadowScan splash screen loads', (tester) async {
    await tester.pumpWidget(const ShadowScanApp());

    expect(find.text('SHADOWSCAN'), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);
  });
}
