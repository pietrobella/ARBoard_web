import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/main.dart';
import 'package:arboard_app/pages/board_tool_detail_page.dart';
import 'package:arboard_app/widgets/navbar.dart';
import 'package:arboard_app/router/app_router.dart';

/// Widget tests for BoardToolDetailPage
/// Requirements: 5.5
void main() {
  group('BoardToolDetailPage Widget Tests', () {
    testWidgets('BoardToolDetailPage displays navbar', (WidgetTester tester) async {
      // Navigate to board tool detail page with a board name
      AppRouter.router.go('/arboard/board_tool/TestBoard');
      
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolDetailPage is displayed
      expect(find.byType(BoardToolDetailPage), findsOneWidget);
      
      // Verify that NavBar is present
      expect(find.byType(NavBar), findsOneWidget);
      
      // Verify that AppBar (which NavBar extends) is present
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('BoardToolDetailPage displays for any board name', 
        (WidgetTester tester) async {
      // Test with different board names
      final testBoardNames = ['Board1', 'TestBoard', 'My-Board-123', 'Board%20With%20Spaces'];
      
      for (final boardName in testBoardNames) {
        // Navigate to board tool detail page with the board name
        AppRouter.router.go('/arboard/board_tool/$boardName');
        
        // Build the app with the router
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        
        // Verify that BoardToolDetailPage is displayed
        expect(find.byType(BoardToolDetailPage), findsOneWidget);
        
        // Verify that the board name is displayed (decoded from URL)
        final decodedBoardName = Uri.decodeComponent(boardName);
        expect(find.textContaining(decodedBoardName), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('BoardToolDetailPage displays placeholder content', 
        (WidgetTester tester) async {
      // Navigate to board tool detail page
      AppRouter.router.go('/arboard/board_tool/SampleBoard');
      
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolDetailPage is displayed
      expect(find.byType(BoardToolDetailPage), findsOneWidget);
      
      // Verify placeholder content is displayed
      expect(find.text('Board Tool Detail'), findsOneWidget);
      expect(find.text('Placeholder content - to be implemented'), findsOneWidget);
    });

    testWidgets('BoardToolDetailPage displays correct board name', 
        (WidgetTester tester) async {
      const testBoardName = 'MySpecialBoard';
      
      // Navigate to board tool detail page with specific board name
      AppRouter.router.go('/arboard/board_tool/$testBoardName');
      
      // Build the app with the router
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verify that BoardToolDetailPage is displayed
      expect(find.byType(BoardToolDetailPage), findsOneWidget);
      
      // Verify that the specific board name is displayed
      expect(find.text('Board: $testBoardName'), findsOneWidget);
    });
  });
}
