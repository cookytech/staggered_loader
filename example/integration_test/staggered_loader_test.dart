import 'package:example/main.dart';
import 'package:example/mock_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDemo(WidgetTester tester, MockApi api) async {
    await tester.pumpWidget(DemoApp(api: api));
    await tester.pumpAndSettle();
  }

  Future<void> tapLoad(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('loadButton')));
    await tester.pump();
  }

  group('StaggeredLoader integration', () {
    testWidgets('fast API (200ms) never shows the loader', (tester) async {
      final api = MockApi(responseDelay: const Duration(milliseconds: 200));
      await pumpDemo(tester, api);
      await tapLoad(tester);

      // Immediately after tap: placeholder, no loader, no items.
      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);
      expect(find.byKey(const ValueKey('loader')), findsNothing);

      // Advance to 300ms — API resolved (200ms) before default 1s loader delay.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('loader')), findsNothing);
      expect(find.byKey(const ValueKey('items')), findsOneWidget);
      expect(find.text('Item #1'), findsOneWidget);

      // Hold past the delay to confirm loader never appears retroactively.
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const ValueKey('loader')), findsNothing);
      expect(find.byKey(const ValueKey('items')), findsOneWidget);
    });

    testWidgets('slow API (3s) shows the loader after the 1s deadline',
        (tester) async {
      final api = MockApi(responseDelay: const Duration(seconds: 3));
      await pumpDemo(tester, api);
      await tapLoad(tester);

      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);
      expect(find.byKey(const ValueKey('loader')), findsNothing);

      // Advance to 500ms — still under the 1s loader deadline.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);
      expect(find.byKey(const ValueKey('loader')), findsNothing);

      // Cross the 1s deadline while the future is still pending.
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('loader')), findsOneWidget);
      expect(find.byKey(const ValueKey('placeholder')), findsNothing);

      // Let the future resolve.
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.byKey(const ValueKey('items')), findsOneWidget);
      expect(find.byKey(const ValueKey('loader')), findsNothing);
      expect(find.text('Item #1'), findsOneWidget);
    });

    testWidgets('borderline API (800ms) with 500ms deadline shows loader',
        (tester) async {
      final api = MockApi(responseDelay: const Duration(milliseconds: 800));
      await pumpDemo(tester, api);

      // Switch loader delay to 500ms.
      await tester.tap(find.byKey(const ValueKey('delay-500')));
      await tester.pump();

      await tapLoad(tester);
      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);

      // At 400ms, still under 500ms delay.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);
      expect(find.byKey(const ValueKey('loader')), findsNothing);

      // At 600ms, loader is visible; API not yet resolved.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('loader')), findsOneWidget);

      // At 900ms, API resolved.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('items')), findsOneWidget);
      expect(find.text('Item #1'), findsOneWidget);
    });

    testWidgets('borderline API (800ms) with 1s deadline never shows loader',
        (tester) async {
      final api = MockApi(responseDelay: const Duration(milliseconds: 800));
      await pumpDemo(tester, api);
      // Default 1s delay is already selected.

      await tapLoad(tester);
      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);

      // At 700ms, still under 1s delay and still awaiting API.
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);
      expect(find.byKey(const ValueKey('loader')), findsNothing);

      // At 900ms API resolves before the 1s deadline — no loader.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('loader')), findsNothing);
      expect(find.byKey(const ValueKey('items')), findsOneWidget);
    });

    testWidgets('reloading with a new API duration re-runs the state machine',
        (tester) async {
      final api = MockApi(responseDelay: const Duration(milliseconds: 200));
      await pumpDemo(tester, api);

      // First load: fast API, no loader.
      await tapLoad(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('items')), findsOneWidget);

      // Switch to slow API (3s) and reload.
      await tester.tap(find.byKey(const ValueKey('api-3000')));
      await tester.pump();
      await tapLoad(tester);

      expect(find.byKey(const ValueKey('placeholder')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.byKey(const ValueKey('loader')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.byKey(const ValueKey('items')), findsOneWidget);
    });
  });
}
