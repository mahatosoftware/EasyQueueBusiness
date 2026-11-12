import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_queue_business/features/auth/sign_in_screen.dart';

void main() {
  testWidgets('SignInScreen displays branding, email/password, reset, and Google sign in', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );

    // Verify Brand Title
    expect(find.text('EasyQueue Business'), findsOneWidget);

    // Verify Fields
    expect(find.text('Work Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Forgot Password button
    expect(find.text('Forgot Password?'), findsOneWidget);

    // Verify Buttons
    expect(find.text('Sign In with Email'), findsOneWidget);
    expect(find.text('Sign In with Google'), findsOneWidget);
    expect(find.text('New business? Create an Account'), findsOneWidget);

    // Tap Forgot Password and check dialog opens
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });
}
