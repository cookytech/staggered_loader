import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staggered_loader/staggered_loader.dart';

Widget _harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StaggeredLoader', () {
    testWidgets('shows placeholder before delay elapses', (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(_harness(
        StaggeredLoader<String>(
          future: completer.future,
          delay: const Duration(milliseconds: 500),
          placeholder: const Text('BLANK'),
          loader: const Text('LOADING'),
          builder: (_, data) => Text('DATA:$data'),
        ),
      ));

      expect(find.text('BLANK'), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('BLANK'), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);

      completer.complete('x');
      await tester.pumpAndSettle();
    });

    testWidgets('skips loader when future resolves before delay',
        (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(_harness(
        StaggeredLoader<String>(
          future: completer.future,
          delay: const Duration(milliseconds: 500),
          placeholder: const Text('BLANK'),
          loader: const Text('LOADING'),
          builder: (_, data) => Text('DATA:$data'),
        ),
      ));

      expect(find.text('BLANK'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      completer.complete('fast');
      await tester.pumpAndSettle();

      expect(find.text('LOADING'), findsNothing);
      expect(find.text('DATA:fast'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('LOADING'), findsNothing);
      expect(find.text('DATA:fast'), findsOneWidget);
    });

    testWidgets('shows loader when delay elapses before future resolves',
        (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(_harness(
        StaggeredLoader<String>(
          future: completer.future,
          delay: const Duration(milliseconds: 500),
          placeholder: const Text('BLANK'),
          loader: const Text('LOADING'),
          builder: (_, data) => Text('DATA:$data'),
        ),
      ));

      expect(find.text('BLANK'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('LOADING'), findsOneWidget);
      expect(find.text('BLANK'), findsNothing);

      completer.complete('slow');
      await tester.pumpAndSettle();
      expect(find.text('DATA:slow'), findsOneWidget);
      expect(find.text('LOADING'), findsNothing);
    });

    testWidgets('respects custom 200ms delay', (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(_harness(
        StaggeredLoader<String>(
          future: completer.future,
          delay: const Duration(milliseconds: 200),
          placeholder: const Text('BLANK'),
          loader: const Text('LOADING'),
          builder: (_, data) => Text('DATA:$data'),
        ),
      ));

      expect(find.text('BLANK'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('BLANK'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('LOADING'), findsOneWidget);
      completer.complete('x');
      await tester.pump();
    });

    testWidgets('renders errorBuilder on rejection', (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(_harness(
        StaggeredLoader<String>(
          future: completer.future,
          delay: const Duration(milliseconds: 100),
          placeholder: const Text('BLANK'),
          loader: const Text('LOADING'),
          builder: (_, data) => Text('DATA:$data'),
          errorBuilder: (_, error, stack) => Text('ERR:$error'),
        ),
      ));

      completer.completeError(StateError('boom'));
      await tester.pump();
      expect(find.text('ERR:Bad state: boom'), findsOneWidget);
    });

    testWidgets('zero delay shows loader immediately', (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(_harness(
        StaggeredLoader<String>(
          future: completer.future,
          delay: Duration.zero,
          placeholder: const Text('BLANK'),
          loader: const Text('LOADING'),
          builder: (_, data) => Text('DATA:$data'),
        ),
      ));

      await tester.pump();
      expect(find.text('LOADING'), findsOneWidget);
      completer.complete('x');
      await tester.pumpAndSettle();
      expect(find.text('DATA:x'), findsOneWidget);
    });

    testWidgets('rebinds when future prop changes', (tester) async {
      final firstCompleter = Completer<String>();
      await tester.pumpWidget(_harness(
        StaggeredLoader<String>(
          future: firstCompleter.future,
          delay: const Duration(milliseconds: 300),
          placeholder: const Text('BLANK'),
          loader: const Text('LOADING'),
          builder: (_, data) => Text('DATA:$data'),
        ),
      ));
      firstCompleter.complete('one');
      await tester.pumpAndSettle();
      expect(find.text('DATA:one'), findsOneWidget);

      final secondCompleter = Completer<String>();
      await tester.pumpWidget(_harness(
        StaggeredLoader<String>(
          future: secondCompleter.future,
          delay: const Duration(milliseconds: 300),
          placeholder: const Text('BLANK'),
          loader: const Text('LOADING'),
          builder: (_, data) => Text('DATA:$data'),
        ),
      ));
      expect(find.text('BLANK'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('LOADING'), findsOneWidget);
      secondCompleter.complete('two');
      await tester.pumpAndSettle();
      expect(find.text('DATA:two'), findsOneWidget);
    });
  });
}
