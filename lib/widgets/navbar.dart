import 'package:flutter/material.dart';

/// Shared navigation bar widget with back button
///
/// This widget provides a consistent navigation bar across all pages
/// except the home page. It includes a back arrow button that allows
/// users to navigate to the previous page in the browser history.
///
/// Requirements: 2.1, 2.2, 2.3
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Use maybePop to respect PopScope/WillPopScope
          Navigator.of(context).maybePop();
        },
        tooltip: 'Back',
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
