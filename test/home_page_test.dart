import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/pages/home_page.dart';
import 'package:arboard_app/pages/board_management_page.dart';
import 'package:arboard_app/pages/board_tool_page.dart';
import 'package:arboard_app/widgets/navbar.dart';
import 'package:arboard_app/router/app_router.dart';

/// Widget tests for HomePage
/// Requirements: 1.2, 1.3, 1.4, 1.5
void main() {
  group('HomePage Widget Tests', () {
    setUp(() {
      // Reset router to home before each test
      AppRouter.router.go(AppRoutes.home);
    });

    testWidgets('HomePage displays two buttons', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that two ElevatedButtons are present
      expect(find.byType(ElevatedButton), findsNWidgets(2));
      
      // Verify button texts
      expect(find.text('Board Management'), findsOneWidget);
      expect(find.text('Board Tool'), findsOneWidget);
    });

    testWidgets('HomePage first button navigates to board_management', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify we start on HomePage
      expect(find.byType(HomePage), findsOneWidget);
      
      // Find and tap the Board Management button
      await tester.tap(find.text('Board Management'));
      await tester.pumpAndSettle();
      
      // Verify navigation occurred by checking if we're on the board management page
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(BoardManagementPage), findsOneWidget);
      
      // Verify URL changed
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
      );
    });

    testWidgets('HomePage second button navigates to board_tool', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify we start on HomePage
      expect(find.byType(HomePage), findsOneWidget);
      
      // Find and tap the Board Tool button
      await tester.tap(find.text('Board Tool'));
      await tester.pumpAndSettle();
      
      // Verify navigation occurred by checking if we're on the board tool page
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(BoardToolPage), findsOneWidget);
      
      // Verify URL changed
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardTool,
      );
    });

    testWidgets('HomePage does not display navbar', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that HomePage is displayed
      expect(find.byType(HomePage), findsOneWidget);
      
      // Verify that NavBar is not present on the home page
      expect(find.byType(NavBar), findsNothing);
      
      // Verify that no AppBar is present (NavBar extends AppBar)
      expect(find.byType(AppBar), findsNothing);
    });
  });
}
