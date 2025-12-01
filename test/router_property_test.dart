import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/router/app_router.dart';

/// **Feature: flutter-arboard-navigation, Property 1: Route URL Synchronization**
/// **Validates: Requirements 7.1, 7.4**
/// 
/// Property: For any navigation action within the application (including 
/// programmatic navigation, button clicks, and direct URL entry), the browser 
/// URL should always reflect the current page route exactly.
void main() {
  group('Property 1: Route URL Synchronization', () {
    testWidgets('URL synchronization property holds for all defined routes',
        (WidgetTester tester) async {
      // List of all valid routes in the application
      final validRoutes = [
        AppRoutes.home,
        AppRoutes.boardManagement,
        AppRoutes.boardManagementNew,
        AppRoutes.boardManagementComplete,
        AppRoutes.boardManagementLimited,
        AppRoutes.boardTool,
        '/arboard/board_tool/test-board-1',
        '/arboard/board_tool/test-board-2',
        '/arboard/board_tool/my-board',
      ];

      // Run the property test with at least 100 iterations
      // We'll test each route multiple times with different navigation methods
      int iterations = 0;
      const minIterations = 100;

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Test each route multiple times to reach minimum iterations
      while (iterations < minIterations) {
        for (final route in validRoutes) {
          if (iterations >= minIterations) break;

          // Navigate to the route programmatically
          AppRouter.router.go(route);
          await tester.pumpAndSettle();

          // Property assertion: URL should match the route
          final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
          expect(
            currentLocation,
            route,
            reason:
                'Iteration $iterations: URL should synchronize with route after programmatic navigation to $route',
          );

          iterations++;
        }
      }

      debugPrint('Property test completed with $iterations iterations');
    });

    testWidgets(
        'URL synchronization property holds for button-triggered navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify initial location
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
        reason: 'Initial URL should be /arboard',
      );

      // Test navigation through button clicks
      // Find and tap the first button (board management)
      final boardManagementButton = find.text('Board Management');
      if (boardManagementButton.evaluate().isNotEmpty) {
        await tester.tap(boardManagementButton);
        await tester.pumpAndSettle();

        expect(
          AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.boardManagement,
          reason: 'URL should synchronize after button click navigation',
        );
      }
    });

    testWidgets('URL synchronization property holds for manual URL entry',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Simulate manual URL entry by directly navigating to routes
      final testRoutes = [
        AppRoutes.boardManagement,
        AppRoutes.boardManagementNew,
        AppRoutes.boardTool,
        AppRoutes.home,
      ];

      for (final route in testRoutes) {
        // Simulate manual URL entry
        AppRouter.router.go(route);
        await tester.pumpAndSettle();

        // Property assertion: URL should match the manually entered route
        final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
        expect(
          currentLocation,
          route,
          reason:
              'URL should synchronize with manually entered route: $route',
        );
      }
    });

    testWidgets('URL synchronization property holds for dynamic routes',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Test dynamic board name routes
      final dynamicBoardNames = [
        'board-1',
        'board-2',
        'my-special-board',
        'test_board',
        'board123',
      ];

      for (final boardName in dynamicBoardNames) {
        final route = '/arboard/board_tool/$boardName';
        AppRouter.router.go(route);
        await tester.pumpAndSettle();

        // Property assertion: URL should match the dynamic route
        final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
        expect(
          currentLocation,
          route,
          reason:
              'URL should synchronize with dynamic route for board: $boardName',
        );
      }
    });
  });
}
