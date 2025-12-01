import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arboard_app/widgets/navbar.dart';

void main() {
  testWidgets('NavBar displays back arrow icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: const NavBar(),
          body: const Center(child: Text('Test')),
        ),
      ),
    );

    // Verify that the back arrow icon is present
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('NavBar has correct preferred size', (WidgetTester tester) async {
    const navbar = NavBar();
    
    // Verify that the preferred size is the standard toolbar height
    expect(navbar.preferredSize.height, kToolbarHeight);
  });
}
