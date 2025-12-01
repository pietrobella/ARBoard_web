import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/router/app_router.dart';
import 'package:arboard_app/pages/error_page.dart';

/// **Feature: flutter-arboard-navigation, Property 6: Invalid Route Handling**
/// **Validates: Requirements 6.1, 7.5**
/// 
/// Property: For any URL that starts with `/arboard/` but does not match a 
/// defined route, the application should display the error page.
void main() {
  group('Property 6: Invalid Route Handling', () {
    testWidgets('Invalid route property holds for undefined routes',
        (WidgetTester tester) async {
      // List of invalid routes that should trigger the error page
      // These all start with /arboard/ but are not defined in the router
      final invalidRoutes = [
        '/arboard/invalid',
        '/arboard/nonexistent',
        '/arboard/board_management/invalid',
        '/arboard/board_tool/edit/invalid',
        '/arboard/random_page',
        '/arboard/test',
        '/arboard/board_management/unknown',
        '/arboard/board_tool/detail/extra',
        '/arboard/xyz',
        '/arboard/123',
      ];

      // Run the property test with at least 100 iterations
      int iterations = 0;
      const minIterations = 100;

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Test each invalid route multiple times to reach minimum iterations
      while (iterations < minIterations) {
        for (final route in invalidRoutes) {
          if (iterations >= minIterations) break;

          // Navigate to the invalid route
          AppRouter.router.go(route);
          await tester.pumpAndSettle();

          // Property assertion: ErrorPage should be displayed
          expect(
            find.byType(ErrorPage),
            findsOneWidget,
            reason:
                'Iteration $iterations: ErrorPage should be displayed for invalid route: $route',
          );

          // Additional verification: Check for error page content
          expect(
            find.text('Oops! Page Not Found'),
            findsOneWidget,
            reason:
                'Iteration $iterations: Error message should be displayed for invalid route: $route',
          );

          iterations++;
        }
      }

      debugPrint('Property test completed with $iterations iterations');
    });

    testWidgets('Invalid route property holds for various invalid patterns',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Test various patterns of invalid routes
      final invalidPatterns = [
        '/arboard/board_management/new/extra',
        '/arboard/board_management/complete/extra',
        '/arboard/board_management/limited/extra',
        '/arboard/unknown/path/here',
        '/arboard/settings',
        '/arboard/profile',
      ];

      for (final route in invalidPatterns) {
        AppRouter.router.go(route);
        await tester.pumpAndSettle();

        // Property assertion: ErrorPage should be displayed
        expect(
          find.byType(ErrorPage),
          findsOneWidget,
          reason: 'ErrorPage should be displayed for invalid pattern: $route',
        );

        // Verify the home button is present
        expect(
          find.text('Back to Home'),
          findsOneWidget,
          reason: 'Home button should be present on error page for route: $route',
        );
      }
    });

    testWidgets('Valid routes do not trigger error page',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // List of valid routes that should NOT trigger the error page
      final validRoutes = [
        AppRoutes.home,
        AppRoutes.boardManagement,
        AppRoutes.boardManagementNew,
        AppRoutes.boardManagementComplete,
        AppRoutes.boardManagementLimited,
        AppRoutes.boardTool,
        '/arboard/board_tool/test-board',
      ];

      for (final route in validRoutes) {
        AppRouter.router.go(route);
        await tester.pumpAndSettle();

        // Property assertion: ErrorPage should NOT be displayed for valid routes
        expect(
          find.byType(ErrorPage),
          findsNothing,
          reason: 'ErrorPage should NOT be displayed for valid route: $route',
        );
      }
    });
  });
}
