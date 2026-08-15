import 'dart:async';

/// Fake network client used by the example and integration tests to simulate
/// configurable API response times.
class MockApi {
  MockApi({this.responseDelay = const Duration(milliseconds: 800)});

  Duration responseDelay;

  Future<String> fetchGreeting({String name = 'world'}) {
    return Future.delayed(responseDelay, () => 'Hello, $name!');
  }

  Future<List<String>> fetchItems() {
    return Future.delayed(
      responseDelay,
      () => List.generate(5, (i) => 'Item #${i + 1}'),
    );
  }

  Future<void> failAfterDelay() {
    return Future.delayed(
      responseDelay,
      () => Future<void>.error(StateError('Simulated failure')),
    );
  }
}
