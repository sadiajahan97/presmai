import 'package:flutter_test/flutter_test.dart';
import 'package:presmai_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts and shows welcome screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      PresMAIApp(
        initialRoute: '/welcome',
        prefs: prefs,
      ),
    );
    expect(find.text('PresMAI'), findsWidgets);
  });
}
