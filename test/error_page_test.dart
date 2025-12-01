import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/pages/error_page.dart';
import 'package:arboard_app/pages/home_page.dart';
import 'package:arboard_app/router/app_router.dart';

/// Widget tests for ErrorPage
/// Requirements: 6.2, 6.3, 6.4
void main() {
  group('ErrorPage Widget Tests', () {
    testWidgets('ErrorPage displays error message', (WidgetTester tester) async {
      // Build the app and navigate to an invalid route
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Navigate to an invalid route to trigger error page
      AppRouter.router.go('/arboard/invalid');
      await tester.pumpAndSettle();
      
      // Verify that ErrorPage is displayed
      expect(find.byType(ErrorPage), findsOneWidget);
      
      // Verify error message is displayed
      expect(find.text('Oops! Page Not Found'), findsOneWidget);
      expect(find.text('Looks like you\'ve wandered off the map!'), findsOneWidget);
      expect(find.text('The page you\'re looking for doesn\'t exist.'), findsOneWidget);
      
      // Verify error icon is displayed
      expect(find.byIcon(Icons.sentiment_dissatisfied), findsOneWidget);
    });

    testWidgets('ErrorPage displays home button', (WidgetTester tester) async {
      // Build the app and navigate to an invalid route
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Navigate to an invalid route to trigger error page
      AppRouter.router.go('/arboard/nonexistent');
      await tester.pumpAndSettle();
      
      // Verify that ErrorPage is displayed
      expect(find.byType(ErrorPage), findsOneWidget);
      
      // Verify home button text and icon are present
      expect(find.text('Back to Home'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('ErrorPage home button navigates to home', (WidgetTester tester) async {
      // Build the app and navigate to an invalid route
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Navigate to an invalid route to trigger error page
      AppRouter.router.go('/arboard/invalid_route');
      await tester.pumpAndSettle();
      
      // Verify that ErrorPage is displayed
      expect(find.byType(ErrorPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      
      // Tap the home button
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      
      // Verify navigation to home page occurred
      expect(find.byType(ErrorPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      
      // Verify URL changed to home
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home,
      );
    });

    testWidgets('ErrorPage is displayed for multiple invalid routes', 
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Test multiple invalid routes
      final invalidRoutes = [
        '/arboard/invalid',
        '/arboard/nonexistent',
        '/arboard/random',
        '/arboard/board_management/invalid',
      ];
      
      for (final route in invalidRoutes) {
        // Navigate to invalid route
        AppRouter.router.go(route);
        await tester.pumpAndSettle();
        
        // Verify ErrorPage is displayed
        expect(
          find.byType(ErrorPage), 
          findsOneWidget,
          reason: 'ErrorPage should be displayed for route: $route',
        );
        
        // Verify error message is present
        expect(
          find.text('Oops! Page Not Found'), 
          findsOneWidget,
          reason: 'Error message should be displayed for route: $route',
        );
      }
    });
  });
}
