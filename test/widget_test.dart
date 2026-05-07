import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Happy Oven'), findsWidgets);
  });
}
