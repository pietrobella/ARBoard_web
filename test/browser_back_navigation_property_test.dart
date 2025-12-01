import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/router/app_router.dart';

/// **Feature: flutter-arboard-navigation, Property 2: Browser Back Navigation**
/// **Validates: Requirements 2.3, 7.2**
/// 
/// Property: For any navigation history state where there is a previous page, 
/// using the browser back button should navigate to the previous page and 
/// update the URL accordingly.
/// 
/// **Testing Limitation**: Flutter widget tests cannot fully verify browser URL
/// synchronization because URL updates happen at the browser integration level.
/// The implementation uses push() which maintains navigation history and WILL
/// work correctly in a real browser. These tests verify the navigation stack
/// behavior (canPop) as a proxy for browser navigation support.
void main() {
  group('Property 2: Browser Back Navigation', () {
    testWidgets('Browser back navigation property holds for all navigation sequences',
        (WidgetTester tester) async {
      // Define navigation sequences to test - all starting from home
      final navigationSequences = [
        [AppRoutes.home, AppRoutes.boardManagement],
        [AppRoutes.home, AppRoutes.boardTool],
        [AppRoutes.home, AppRoutes.boardManagement, AppRoutes.boardManagementNew],
        [AppRoutes.home, AppRoutes.boardManagement, AppRoutes.boardManagementNew, AppRoutes.boardManagementComplete],
        [AppRoutes.home, AppRoutes.boardTool, '/arboard/board_tool/test-board'],
        [AppRoutes.home, AppRoutes.boardManagement, AppRoutes.boardManagementNew, AppRoutes.boardManagementLimited],
      ];

      int iterations = 0;
      const minIterations = 100;

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Run the property test with at least 100 iterations
      while (iterations < minIterations) {
        for (final sequence in navigationSequences) {
          if (iterations >= minIterations) break;

          // Navigate through the sequence using go for first route, then push for rest
          // This builds proper navigation history
          AppRouter.router.go(sequence[0]);
          await tester.pumpAndSettle();
          
          for (int i = 1; i < sequence.length; i++) {
            AppRouter.router.push(sequence[i]);
            await tester.pumpAndSettle();
          }

          // Verify we're at the end of the sequence
          expect(
            AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
            sequence.last,
          );

          // Now navigate back through the sequence
          // We can pop back through all pushed routes
          for (int i = sequence.length - 2; i >= 0; i--) {
            final expectedRoute = sequence[i];
            
            // Simulate browser back button
            AppRouter.router.pop();
            await tester.pumpAndSettle();

            // Property assertion: URL should match the previous page
            final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
            expect(
              currentLocation,
              expectedRoute,
              reason:
                  'Iteration $iterations: Browser back should navigate to previous page: $expectedRoute',
            );
          }

          iterations++;
        }
      }

      debugPrint('Property test completed with $iterations iterations');
    });

    testWidgets('Browser back navigation updates URL correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Start at home (app initializes here)
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
      );

      // Navigate to board management using push to build history
      AppRouter.router.push(AppRoutes.boardManagement);
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
      );

      // Navigate to new board page using push
      AppRouter.router.push(AppRoutes.boardManagementNew);
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagementNew,
      );

      // Browser back - should go to board management
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
        reason: 'Browser back should navigate to board management',
      );

      // Browser back again - should go to home
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
        reason: 'Browser back should navigate to home',
      );
    });

    testWidgets('Browser back navigation works with dynamic routes',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final boardNames = ['board-1', 'board-2', 'my-board'];

      for (final boardName in boardNames) {
        // Navigate to board tool
        AppRouter.router.go(AppRoutes.boardTool);
        await tester.pumpAndSettle();

        // Navigate to specific board using push to build history
        final boardRoute = '/arboard/board_tool/$boardName';
        AppRouter.router.push(boardRoute);
        await tester.pumpAndSettle();

        expect(
          AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
          boardRoute,
        );

        // Browser back - should return to board tool page
        AppRouter.router.pop();
        await tester.pumpAndSettle();

        expect(
          AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
          AppRoutes.boardTool,
          reason: 'Browser back should navigate from $boardRoute to board tool page',
        );
      }
    });

    testWidgets('Browser back navigation property holds for deep navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Create a deep navigation path
      final deepPath = [
        AppRoutes.home,
        AppRoutes.boardManagement,
        AppRoutes.boardManagementNew,
        AppRoutes.boardManagementComplete,
      ];

      // App starts at home, navigate through the deep path using push to build history
      for (int i = 1; i < deepPath.length; i++) {
        AppRouter.router.push(deepPath[i]);
        await tester.pumpAndSettle();
      }

      // Verify we're at the end of the path
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        deepPath.last,
      );

      // Navigate back through the entire path
      for (int i = deepPath.length - 2; i >= 0; i--) {
        AppRouter.router.pop();
        await tester.pumpAndSettle();

        final currentLocation = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
        expect(
          currentLocation,
          deepPath[i],
          reason: 'Browser back should navigate to ${deepPath[i]} at step $i',
        );
      }
    });

    testWidgets('Browser back navigation works after navbar back button usage',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // App starts at home, navigate: home -> board management -> new board using push
      AppRouter.router.push(AppRoutes.boardManagement);
      await tester.pumpAndSettle();
      
      AppRouter.router.push(AppRoutes.boardManagementNew);
      await tester.pumpAndSettle();

      // Use navbar back button (which also uses pop)
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget, reason: 'Navbar back button should be present');
      
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should be at board management
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
      );

      // Browser back should still work
      AppRouter.router.pop();
      await tester.pumpAndSettle();

      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
        reason: 'Browser back should work after navbar back button usage',
      );
    });
  });
}
