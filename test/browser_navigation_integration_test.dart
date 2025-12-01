import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/router/app_router.dart';

/// Integration tests for browser navigation functionality
/// Tests back button, forward button, and manual URL entry
/// Requirements: 7.2, 7.3, 7.4
void main() {
  group('Browser Navigation Integration Tests', () {
    testWidgets('Back button functionality across multiple pages',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // App starts at home
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
      );

      // Navigate through multiple pages using push to build history
      AppRouter.router.push(AppRoutes.boardManagement);
      await tester.pumpAndSettle();

      AppRouter.router.push(AppRoutes.boardManagementNew);
      await tester.pumpAndSettle();

      AppRouter.router.push(AppRoutes.boardManagementComplete);
      await tester.pumpAndSettle();

      // Verify we're at the complete info page
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagementComplete,
      );

      // Test back button functionality - go back through the pages
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagementNew,
        reason: 'Back button should navigate to new board page',
      );

      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
        reason: 'Back button should navigate to board management page',
      );

      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
        reason: 'Back button should navigate to home page',
      );
    });

    testWidgets('Forward button functionality',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // App starts at home, build navigation history
      AppRouter.router.push(AppRoutes.boardManagement);
      await tester.pumpAndSettle();

      AppRouter.router.push(AppRoutes.boardManagementNew);
      await tester.pumpAndSettle();

      // Go back
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
      );

      // Forward navigation (simulated by re-pushing)
      // Note: In a real browser, this would be handled by the browser's forward button
      AppRouter.router.push(AppRoutes.boardManagementNew);
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagementNew,
        reason: 'Forward button should navigate to new board page',
      );
    });

    testWidgets('Manual URL entry navigates to correct page',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Test manual URL entry for various routes
      final testRoutes = [
        AppRoutes.boardManagement,
        AppRoutes.boardManagementNew,
        AppRoutes.boardManagementComplete,
        AppRoutes.boardManagementLimited,
        AppRoutes.boardTool,
        '/arboard/board_tool/test-board',
      ];

      for (final route in testRoutes) {
        // Simulate manual URL entry using go()
        AppRouter.router.go(route);
        await tester.pumpAndSettle();

        // Verify the URL matches
        expect(
          AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
          route,
          reason: 'Manual URL entry should navigate to: $route',
        );
      }
    });

    testWidgets('Back button works after manual URL entry',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Manual URL entry
      AppRouter.router.go(AppRoutes.boardManagement);
      await tester.pumpAndSettle();

      // Navigate to another page using push
      AppRouter.router.push(AppRoutes.boardManagementNew);
      await tester.pumpAndSettle();

      // Back button should work
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
        reason: 'Back button should work after manual URL entry',
      );
    });

    testWidgets('Navigation history is maintained across different sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // App starts at home, navigate through board management section
      AppRouter.router.push(AppRoutes.boardManagement);
      await tester.pumpAndSettle();

      AppRouter.router.push(AppRoutes.boardManagementNew);
      await tester.pumpAndSettle();

      // Navigate to board tool section
      AppRouter.router.push(AppRoutes.boardTool);
      await tester.pumpAndSettle();

      AppRouter.router.push('/arboard/board_tool/my-board');
      await tester.pumpAndSettle();

      // Back through the history
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardTool,
      );

      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagementNew,
      );

      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
      );

      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
      );
    });

    testWidgets('Browser navigation works with dynamic routes',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to board tool
      AppRouter.router.go(AppRoutes.boardTool);
      await tester.pumpAndSettle();

      // Navigate to specific boards
      final boards = ['board-1', 'board-2', 'board-3'];
      
      for (final board in boards) {
        final route = '/arboard/board_tool/$board';
        AppRouter.router.push(route);
        await tester.pumpAndSettle();

        expect(
          AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
          route,
        );
      }

      // Back through all boards
      for (int i = boards.length - 1; i > 0; i--) {
        AppRouter.router.pop();
        await tester.pumpAndSettle();
        
        final expectedRoute = '/arboard/board_tool/${boards[i - 1]}';
        expect(
          AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
          expectedRoute,
          reason: 'Back button should navigate to previous board',
        );
      }

      // One more back should go to board tool page
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardTool,
      );
    });

    testWidgets('Manual URL entry to invalid route shows error page',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Build some navigation history first
      AppRouter.router.push(AppRoutes.boardManagement);
      await tester.pumpAndSettle();

      // Manual URL entry to invalid route using push (to maintain history)
      AppRouter.router.push('/arboard/invalid-route');
      await tester.pumpAndSettle();

      // Should show error page
      expect(
        find.text('Oops! Page Not Found'),
        findsOneWidget,
        reason: 'Error page should be displayed for invalid URL',
      );

      // Back button should work from error page
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagement,
        reason: 'Back button should work from error page',
      );
    });

    testWidgets('Complex navigation scenario with mixed go and push',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Start with go (replaces location)
      AppRouter.router.go(AppRoutes.boardManagement);
      await tester.pumpAndSettle();

      // Use push to build history
      AppRouter.router.push(AppRoutes.boardManagementNew);
      await tester.pumpAndSettle();

      AppRouter.router.push(AppRoutes.boardManagementComplete);
      await tester.pumpAndSettle();

      // Use go (replaces current location)
      AppRouter.router.go(AppRoutes.boardTool);
      await tester.pumpAndSettle();

      // Push more pages
      AppRouter.router.push('/arboard/board_tool/test-board');
      await tester.pumpAndSettle();

      // Back should work for pushed pages
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardTool,
        reason: 'Back should work after push',
      );
    });
  });
}
