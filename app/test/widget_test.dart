import 'package:flutter_test/flutter_test.dart';
import 'package:presmai_app/main.dart';

void main() {
  testWidgets('App starts and shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PresMAIApp());
    expect(find.text('PresMAI'), findsWidgets);
  });
}
