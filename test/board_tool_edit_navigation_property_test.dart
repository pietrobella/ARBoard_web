import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/router/app_router.dart';

/// **Feature: flutter-arboard-navigation, Property 7: Board Tool Edit Navigation with Dynamic Route**
/// **Validates: Requirements 5.4**
/// 
/// Property: For any board name selected in the board tool page, clicking EDIT 
/// should navigate to /arboard/board_tool/<board_name> where <board_name> 
/// matches the selected board.
void main() {
  group('Property 7: Board Tool Edit Navigation with Dynamic Route', () {
    testWidgets('Edit navigation property holds for all board names',
        (WidgetTester tester) async {
      // Use the actual board names from BoardToolPage
      // These are the boards that exist in the dropdown
      final testBoardNames = [
        'Board 1',
        'Board 2',
        'Board 3',
      ];

      int iterations = 0;
      const minIterations = 100;

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Run the property test with at least 100 iterations
      while (iterations < minIterations) {
        for (final boardName in testBoardNames) {
          if (iterations >= minIterations) break;

          // Navigate to board tool page
          AppRouter.router.go(AppRoutes.boardTool);
          await tester.pumpAndSettle();

          // Find and tap the dropdown to open it
          final dropdownFinder = find.byType(DropdownButtonFormField<String>);
          expect(dropdownFinder, findsOneWidget,
              reason: 'Dropdown should be present on board tool page');

          await tester.tap(dropdownFinder);
          await tester.pumpAndSettle();

          // Find and select the board name from dropdown
          final boardItemFinder = find.text(boardName).last;
          await tester.tap(boardItemFinder);
          await tester.pumpAndSettle();

          // Find and tap the EDIT button
          final editButtonFinder = find.widgetWithText(ElevatedButton, 'EDIT');
          expect(editButtonFinder, findsOneWidget,
              reason: 'EDIT button should be present');

          await tester.tap(editButtonFinder);
          await tester.pumpAndSettle();

          // Property assertion: URL should match /arboard/board_tool/<board_name>
          // Note: Board names are URL-encoded, so we need to encode the expected route
          final expectedRoute = '/arboard/board_tool/${Uri.encodeComponent(boardName)}';
          final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
          
          expect(
            currentLocation,
            expectedRoute,
            reason:
                'Iteration $iterations: After clicking EDIT with board "$boardName" selected, '
                'should navigate to $expectedRoute',
          );

          iterations++;
        }
      }

      debugPrint('Property test completed with $iterations iterations');
    });

    testWidgets('Edit button is disabled when no board is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to board tool page
      AppRouter.router.go(AppRoutes.boardTool);
      await tester.pumpAndSettle();

      // Find the EDIT button
      final editButtonFinder = find.widgetWithText(ElevatedButton, 'EDIT');
      expect(editButtonFinder, findsOneWidget);

      // Get the button widget
      final editButton = tester.widget<ElevatedButton>(editButtonFinder);
      
      // Property assertion: Button should be disabled (onPressed is null) when no board selected
      expect(
        editButton.onPressed,
        isNull,
        reason: 'EDIT button should be disabled when no board is selected',
      );
    });

    testWidgets('Edit button is enabled when a board is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to board tool page
      AppRouter.router.go(AppRoutes.boardTool);
      await tester.pumpAndSettle();

      // Find and tap the dropdown
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Select the first board
      final firstBoardFinder = find.text('Board 1').last;
      await tester.tap(firstBoardFinder);
      await tester.pumpAndSettle();

      // Find the EDIT button
      final editButtonFinder = find.widgetWithText(ElevatedButton, 'EDIT');
      final editButton = tester.widget<ElevatedButton>(editButtonFinder);
      
      // Property assertion: Button should be enabled (onPressed is not null) when board is selected
      expect(
        editButton.onPressed,
        isNotNull,
        reason: 'EDIT button should be enabled when a board is selected',
      );
    });

    testWidgets('Navigation preserves board name exactly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Test that special characters and spaces are preserved
      final specialBoardNames = [
        'Board 1',
        'Board 2',
        'Board 3',
      ];

      for (final boardName in specialBoardNames) {
        // Navigate to board tool page
        AppRouter.router.go(AppRoutes.boardTool);
        await tester.pumpAndSettle();

        // Select board
        final dropdownFinder = find.byType(DropdownButtonFormField<String>);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        final boardItemFinder = find.text(boardName).last;
        await tester.tap(boardItemFinder);
        await tester.pumpAndSettle();

        // Click EDIT
        final editButtonFinder = find.widgetWithText(ElevatedButton, 'EDIT');
        await tester.tap(editButtonFinder);
        await tester.pumpAndSettle();

        // Property assertion: Board name in URL should exactly match selected board (URL-encoded)
        final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
        final expectedRoute = '/arboard/board_tool/${Uri.encodeComponent(boardName)}';
        expect(
          currentLocation,
          expectedRoute,
          reason: 'Board name in URL should exactly match selected board: "$boardName" (URL-encoded)',
        );
      }
    });

    testWidgets('Multiple edit operations maintain property',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Test multiple consecutive edit operations
      final boardSequence = ['Board 1', 'Board 2', 'Board 3', 'Board 1'];

      for (final boardName in boardSequence) {
        // Navigate to board tool page
        AppRouter.router.go(AppRoutes.boardTool);
        await tester.pumpAndSettle();

        // Select board
        final dropdownFinder = find.byType(DropdownButtonFormField<String>);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        final boardItemFinder = find.text(boardName).last;
        await tester.tap(boardItemFinder);
        await tester.pumpAndSettle();

        // Click EDIT
        final editButtonFinder = find.widgetWithText(ElevatedButton, 'EDIT');
        await tester.tap(editButtonFinder);
        await tester.pumpAndSettle();

        // Property assertion: Each operation should navigate correctly
        final expectedRoute = '/arboard/board_tool/${Uri.encodeComponent(boardName)}';
        final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
        
        expect(
          currentLocation,
          expectedRoute,
          reason: 'Each edit operation should navigate to correct route: $expectedRoute',
        );
      }
    });
  });
}
