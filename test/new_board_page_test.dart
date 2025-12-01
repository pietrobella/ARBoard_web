import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/pages/new_board_page.dart';
import 'package:arboard_app/pages/complete_info_page.dart';
import 'package:arboard_app/pages/limited_info_page.dart';
import 'package:arboard_app/widgets/navbar.dart';
import 'package:arboard_app/router/app_router.dart';

/// Widget tests for NewBoardPage
/// Requirements: 4.3, 4.4, 4.5
void main() {
  group('NewBoardPage Widget Tests', () {
    setUp(() {
      // Navigate to new board page before each test
      AppRouter.router.go(AppRoutes.boardManagementNew);
    });

    testWidgets('NewBoardPage displays two buttons', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that NewBoardPage is displayed
      expect(find.byType(NewBoardPage), findsOneWidget);
      
      // Verify that two ElevatedButtons are present
      expect(find.byType(ElevatedButton), findsNWidgets(2));
      
      // Verify button texts
      expect(find.text('Complete Information'), findsOneWidget);
      expect(find.text('Limited Information'), findsOneWidget);
    });

    testWidgets('NewBoardPage first button navigates to complete info page', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify we start on NewBoardPage
      expect(find.byType(NewBoardPage), findsOneWidget);
      
      // Find and tap the Complete Information button
      await tester.tap(find.text('Complete Information'));
      await tester.pumpAndSettle();
      
      // Verify navigation occurred to CompleteInfoPage
      expect(find.byType(NewBoardPage), findsNothing);
      expect(find.byType(CompleteInfoPage), findsOneWidget);
      
      // Verify URL changed
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagementComplete,
      );
    });

    testWidgets('NewBoardPage second button navigates to limited info page', 
        (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify we start on NewBoardPage
      expect(find.byType(NewBoardPage), findsOneWidget);
      
      // Find and tap the Limited Information button
      await tester.tap(find.text('Limited Information'));
      await tester.pumpAndSettle();
      
      // Verify navigation occurred to LimitedInfoPage
      expect(find.byType(NewBoardPage), findsNothing);
      expect(find.byType(LimitedInfoPage), findsOneWidget);
      
      // Verify URL changed
      expect(
        AppRouter.router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.boardManagementLimited,
      );
    });

    testWidgets('NewBoardPage displays navbar', (WidgetTester tester) async {
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that NewBoardPage is displayed
      expect(find.byType(NewBoardPage), findsOneWidget);
      
      // Verify that NavBar is present
      expect(find.byType(NavBar), findsOneWidget);
      
      // Verify that AppBar (which NavBar extends) is present
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
