import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App renders Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const WarehouseApp());
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
