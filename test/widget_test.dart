import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HappyOvenApp()));
    expect(find.text('Happy Oven'), findsWidgets);
  });
}
