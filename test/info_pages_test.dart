import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/pages/complete_info_page.dart';
import 'package:arboard_app/pages/limited_info_page.dart';
import 'package:arboard_app/widgets/navbar.dart';
import 'package:arboard_app/router/app_router.dart';

/// Widget tests for CompleteInfoPage and LimitedInfoPage
/// Requirements: 4.4, 4.5
void main() {
  group('CompleteInfoPage Widget Tests', () {
    setUp(() {
      // Navigate to complete info page before each test
      AppRouter.router.go(AppRoutes.boardManagementComplete);
    });

    testWidgets('CompleteInfoPage displays navbar', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that CompleteInfoPage is displayed
      expect(find.byType(CompleteInfoPage), findsOneWidget);
      
      // Verify that NavBar is present
      expect(find.byType(NavBar), findsOneWidget);
      
      // Verify that AppBar (which NavBar extends) is present
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('CompleteInfoPage displays placeholder content', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that CompleteInfoPage is displayed
      expect(find.byType(CompleteInfoPage), findsOneWidget);
      
      // Verify placeholder text is displayed
      expect(find.text('Complete Information Page'), findsOneWidget);
    });
  });

  group('LimitedInfoPage Widget Tests', () {
    setUp(() {
      // Navigate to limited info page before each test
      AppRouter.router.go(AppRoutes.boardManagementLimited);
    });

    testWidgets('LimitedInfoPage displays navbar', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that LimitedInfoPage is displayed
      expect(find.byType(LimitedInfoPage), findsOneWidget);
      
      // Verify that NavBar is present
      expect(find.byType(NavBar), findsOneWidget);
      
      // Verify that AppBar (which NavBar extends) is present
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('LimitedInfoPage displays placeholder content', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that LimitedInfoPage is displayed
      expect(find.byType(LimitedInfoPage), findsOneWidget);
      
      // Verify placeholder text is displayed
      expect(find.text('Limited Information Page'), findsOneWidget);
    });
  });
}
