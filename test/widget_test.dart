import 'package:flutter_test/flutter_test.dart';
import 'package:rent2day/main.dart';

void main() {
  testWidgets('HomeScreen shows Dashboard title', (WidgetTester tester) async {
    await tester.pumpWidget(const RentManagerApp());
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
