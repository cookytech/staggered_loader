import 'package:example/main.dart';
import 'package:example/mock_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DemoApp renders idle state', (tester) async {
    final api = MockApi(responseDelay: const Duration(milliseconds: 100));
    await tester.pumpWidget(DemoApp(api: api));

    expect(find.text('StaggeredLoader Demo'), findsOneWidget);
    expect(find.text('Press "Load items" to start.'), findsOneWidget);
  });
}
