import 'package:flutter_test/flutter_test.dart';
import 'package:rent2day/main.dart';
import 'package:rent2day/data/json_storage_service.dart';

void main() {
  testWidgets('HomeScreen shows Dashboard title', (WidgetTester tester) async {
    final storageService = JsonStorageService();
    await storageService.init();
    await tester.pumpWidget(RentManagerApp(storageService: storageService));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
