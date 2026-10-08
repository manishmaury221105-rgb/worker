import 'package:flutter_test/flutter_test.dart';
import 'package:worker_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkerManagementApp());
    expect(find.byType(WorkerManagementApp), findsOneWidget);
  });
}
