import 'package:flutter_test/flutter_test.dart';
import 'package:rent_box/main.dart';

void main() {
  testWidgets('RentBox app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RentBoxApp());
    expect(find.text('RentBox'), findsWidgets);
  });
}
