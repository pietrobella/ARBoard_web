import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/pages/board_tool_page.dart';
import 'package:arboard_app/widgets/navbar.dart';
import 'package:arboard_app/router/app_router.dart';

/// Widget tests for BoardToolPage
/// Requirements: 5.2, 5.3
void main() {
  group('BoardToolPage Widget Tests', () {
    setUp(() {
      // Navigate to board tool page before each test
      AppRouter.router.go(AppRoutes.boardTool);
    });

    testWidgets('BoardToolPage displays navbar', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolPage is displayed
      expect(find.byType(BoardToolPage), findsOneWidget);
      
      // Verify that NavBar is present
      expect(find.byType(NavBar), findsOneWidget);
      
      // Verify that AppBar (which NavBar extends) is present
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('BoardToolPage displays dropdown menu', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolPage is displayed
      expect(find.byType(BoardToolPage), findsOneWidget);
      
      // Verify that dropdown menu is present
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      
      // Verify dropdown hint text
      expect(find.text('Select a board'), findsOneWidget);
    });

    testWidgets('BoardToolPage displays EDIT button', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolPage is displayed
      expect(find.byType(BoardToolPage), findsOneWidget);
      
      // Verify that EDIT button is present
      final editButtonFinder = find.widgetWithText(ElevatedButton, 'EDIT');
      expect(editButtonFinder, findsOneWidget);
    });

    testWidgets('BoardToolPage EDIT button is disabled when no board selected', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolPage is displayed
      expect(find.byType(BoardToolPage), findsOneWidget);
      
      // Find the EDIT button
      final editButtonFinder = find.widgetWithText(ElevatedButton, 'EDIT');
      expect(editButtonFinder, findsOneWidget);
      
      // Get the button widget and verify it's disabled
      final editButton = tester.widget<ElevatedButton>(editButtonFinder);
      expect(editButton.onPressed, isNull, 
          reason: 'EDIT button should be disabled when no board is selected');
    });

    testWidgets('BoardToolPage EDIT button is enabled when board is selected', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolPage is displayed
      expect(find.byType(BoardToolPage), findsOneWidget);
      
      // Find and tap the dropdown to open it
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      
      // Select a board from the dropdown
      final boardItemFinder = find.text('Board 1').last;
      await tester.tap(boardItemFinder);
      await tester.pumpAndSettle();
      
      // Find the EDIT button
      final editButtonFinder = find.widgetWithText(ElevatedButton, 'EDIT');
      expect(editButtonFinder, findsOneWidget);
      
      // Get the button widget and verify it's enabled
      final editButton = tester.widget<ElevatedButton>(editButtonFinder);
      expect(editButton.onPressed, isNotNull, 
          reason: 'EDIT button should be enabled when a board is selected');
    });

    testWidgets('BoardToolPage dropdown contains board items', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolPage is displayed
      expect(find.byType(BoardToolPage), findsOneWidget);
      
      // Find and tap the dropdown to open it
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      
      // Verify that board items are present in the dropdown
      expect(find.text('Board 1'), findsWidgets);
      expect(find.text('Board 2'), findsWidgets);
      expect(find.text('Board 3'), findsWidgets);
    });
  });
}
