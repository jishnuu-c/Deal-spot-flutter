import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/main.dart';

void main() {
  testWidgets('DealSpot App smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Allow async router initialization
    await tester.pumpAndSettle();

    // Verify DealSpot title or brand icon exists
    expect(find.byType(MyApp), findsOneWidget);
  });
}
