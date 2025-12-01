import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/pages/board_management_page.dart';
import 'package:arboard_app/pages/new_board_page.dart';
import 'package:arboard_app/widgets/navbar.dart';
import 'package:arboard_app/router/app_router.dart';

/// Widget tests for BoardManagementPage
/// Requirements: 3.2, 3.4, 3.5, 4.1, 4.2
void main() {
  group('BoardManagementPage Widget Tests', () {
    setUp(() {
      // Navigate to board management page before each test
      AppRouter.router.go(AppRoutes.boardManagement);
    });

    testWidgets('BoardManagementPage displays navbar', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardManagementPage is displayed
      expect(find.byType(BoardManagementPage), findsOneWidget);
      
      // Verify that NavBar is present
      expect(find.byType(NavBar), findsOneWidget);
      
      // Verify that AppBar (which NavBar extends) is present
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('BoardManagementPage displays dropdown menu', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardManagementPage is displayed
      expect(find.byType(BoardManagementPage), findsOneWidget);
      
      // Verify that dropdown menu is present
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      
      // Verify dropdown hint text for empty list
      expect(find.text('No boards available'), findsOneWidget);
    });

    testWidgets('BoardManagementPage displays EDIT button that does nothing', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardManagementPage is displayed
      expect(find.byType(BoardManagementPage), findsOneWidget);
      
      // Verify that EDIT button is present
      expect(find.text('EDIT'), findsOneWidget);
      
      // Tap the EDIT button
      await tester.tap(find.text('EDIT'));
      await tester.pumpAndSettle();
      
      // Verify we're still on the same page (no navigation occurred)
      expect(find.byType(BoardManagementPage), findsOneWidget);
      
      // Verify URL hasn't changed
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
      );
    });

    testWidgets('BoardManagementPage NEW button navigates correctly', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardManagementPage is displayed
      expect(find.byType(BoardManagementPage), findsOneWidget);
      
      // Verify that NEW button is present
      expect(find.text('NEW'), findsOneWidget);
      
      // Tap the NEW button
      await tester.tap(find.text('NEW'));
      await tester.pumpAndSettle();
      
      // Verify navigation occurred to NewBoardPage
      expect(find.byType(BoardManagementPage), findsNothing);
      expect(find.byType(NewBoardPage), findsOneWidget);
      
      // Verify URL changed to new board page
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagementNew,
      );
    });
  });
}
