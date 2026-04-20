// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uretim_takip/main.dart';
import 'package:uretim_takip/providers/auth_provider.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';

void main() {
  testWidgets('MyApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(isLoggedIn: false, authProvider: AuthProvider(), tenantProvider: TenantProvider()));

    // App should render a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Pump the splash screen timer (2 seconds) to avoid pending timer errors
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
