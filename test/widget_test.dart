import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/main.dart';
import 'package:happy_oven/features/auth/presentation/views/login_view.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HappyOvenApp()));
    // The splash screen finishes synchronously and the router redirects to /login.
    await tester.pump();
    expect(find.byType(LoginView), findsOneWidget);
  });
}
