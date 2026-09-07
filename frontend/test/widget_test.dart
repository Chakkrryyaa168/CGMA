import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('GarageApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GarageApp());
    expect(find.text('Car Garage Management System'), findsOneWidget);
  });
}
