import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/router/app_router.dart';
import 'package:arboard_app/widgets/navbar.dart';

/// **Feature: flutter-arboard-navigation, Property 4: Navbar Visibility Rule**
/// **Validates: Requirements 2.1, 2.4**
/// 
/// Property: For any page route, the navbar should be visible if and only if 
/// the route is not /arboard.
void main() {
  group('Property 4: Navbar Visibility Rule', () {
    testWidgets('Navbar visibility property holds for all routes',
        (WidgetTester tester) async {
      // List of all routes with their expected navbar visibility
      final routeTestCases = [
        // Home route - navbar should NOT be visible
        (route: AppRoutes.home, shouldHaveNavbar: false),
        
        // All other routes - navbar SHOULD be visible
        (route: AppRoutes.boardManagement, shouldHaveNavbar: true),
        (route: AppRoutes.boardManagementNew, shouldHaveNavbar: true),
        (route: AppRoutes.boardManagementComplete, shouldHaveNavbar: true),
        (route: AppRoutes.boardManagementLimited, shouldHaveNavbar: true),
        (route: AppRoutes.boardTool, shouldHaveNavbar: true),
        (route: '/arboard/board_tool/test-board', shouldHaveNavbar: true),
        (route: '/arboard/board_tool/another-board', shouldHaveNavbar: true),
      ];

      int iterations = 0;
      const minIterations = 100;

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Run the property test with at least 100 iterations
      while (iterations < minIterations) {
        for (final testCase in routeTestCases) {
          if (iterations >= minIterations) break;

          // Navigate to the route
          AppRouter.router.go(testCase.route);
          await tester.pumpAndSettle();

          // Property assertion: Check navbar visibility
          final navbarFinder = find.byType(NavBar);
          
          if (testCase.shouldHaveNavbar) {
            expect(
              navbarFinder,
              findsOneWidget,
              reason:
                  'Iteration $iterations: Navbar should be visible for route ${testCase.route}',
            );
          } else {
            expect(
              navbarFinder,
              findsNothing,
              reason:
                  'Iteration $iterations: Navbar should NOT be visible for route ${testCase.route}',
            );
          }

          iterations++;
        }
      }

      debugPrint('Property test completed with $iterations iterations');
    });

    testWidgets('Navbar is absent on home page only',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify current route is home
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
      );

      // Verify navbar is not present on home page
      expect(
        find.byType(NavBar),
        findsNothing,
        reason: 'Navbar should not be visible on home page (/arboard)',
      );
    });

    testWidgets('Navbar is present on all non-home pages',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final nonHomeRoutes = [
        AppRoutes.boardManagement,
        AppRoutes.boardManagementNew,
        AppRoutes.boardManagementComplete,
        AppRoutes.boardManagementLimited,
        AppRoutes.boardTool,
        '/arboard/board_tool/sample-board',
      ];

      for (final route in nonHomeRoutes) {
        // Navigate to non-home route
        AppRouter.router.go(route);
        await tester.pumpAndSettle();

        // Property assertion: Navbar must be present
        expect(
          find.byType(NavBar),
          findsOneWidget,
          reason: 'Navbar should be visible on route: $route',
        );
      }
    });

    testWidgets('Navbar visibility toggles correctly when navigating',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify we start at home
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
      );
      
      // Start at home - no navbar
      expect(find.byType(NavBar), findsNothing);

      // Navigate to board management - navbar should appear
      AppRouter.router.go(AppRoutes.boardManagement);
      await tester.pumpAndSettle();
      expect(find.byType(NavBar), findsOneWidget);

      // Navigate back to home - navbar should disappear
      AppRouter.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(find.byType(NavBar), findsNothing);

      // Navigate to board tool - navbar should appear
      AppRouter.router.go(AppRoutes.boardTool);
      await tester.pumpAndSettle();
      expect(find.byType(NavBar), findsOneWidget);

      // Navigate to home again - navbar should disappear
      AppRouter.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(find.byType(NavBar), findsNothing);
    });

    testWidgets('Navbar visibility property holds for dynamic routes',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Test various dynamic board names
      final dynamicBoardNames = [
        'board-1',
        'board-2',
        'my-board',
        'test_board',
        'special-board-123',
      ];

      for (final boardName in dynamicBoardNames) {
        final route = '/arboard/board_tool/$boardName';
        AppRouter.router.go(route);
        await tester.pumpAndSettle();

        // Property assertion: Navbar must be present for all dynamic routes
        expect(
          find.byType(NavBar),
          findsOneWidget,
          reason:
              'Navbar should be visible on dynamic route: $route',
        );
      }
    });

    testWidgets('Navbar visibility property holds for error page',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to an invalid route (should show error page)
      AppRouter.router.go('/arboard/invalid-route');
      await tester.pumpAndSettle();

      // Error page is not /arboard, so navbar should be visible
      // Note: This depends on how ErrorPage is implemented
      // For now, we'll just verify the test can handle error routes
      final navbarFinder = find.byType(NavBar);
      
      // The error page should follow the same rule:
      // if it's not /arboard, it should have a navbar
      // We'll check if navbar exists (it should based on the property)
      expect(
        navbarFinder,
        findsOneWidget,
        reason: 'Navbar should be visible on error page (not /arboard)',
      );
    });
  });
}
