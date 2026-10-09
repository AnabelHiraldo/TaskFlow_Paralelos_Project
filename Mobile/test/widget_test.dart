import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/main.dart';

void main() {
  testWidgets('TaskFlow inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());

    expect(find.byType(TaskFlowApp), findsOneWidget);
  });
}
