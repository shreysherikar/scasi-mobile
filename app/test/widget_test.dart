// Basic smoke test for the sign-in screen. Kept deliberately independent of
// Supabase/Google Sign-In (no ScasiApp/main.dart here) since those need
// platform channels flutter_test doesn't provide out of the box.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scasi_standalone/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows the sign-in button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Scasi'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
