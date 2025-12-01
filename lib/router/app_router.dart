import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/board_management_page.dart';
import '../pages/new_board_page.dart';
import '../pages/complete_info_page.dart';
import '../pages/limited_info_page.dart';
import '../pages/board_tool_page.dart';
import '../pages/board_tool_detail_page.dart';
import '../pages/board_edit_page.dart';
import '../pages/error_page.dart';

/// Route path constants for the ARBoard application
class AppRoutes {
  static const String home = '/';
  static const String boardManagement = '/board_management';
  static const String boardManagementNew = '/board_management/new';
  static const String boardManagementComplete = '/board_management/new/complete';
  static const String boardManagementLimited = '/board_management/new/limited';
  static const String boardManagementDetail = '/board_management/:boardName';
  static const String boardTool = '/board_tool';
  static const String boardToolDetail = '/board_tool/:boardName';
  
  /// Helper to build board detail route with board name
  static String buildBoardDetailRoute(String boardName) {
    return '/board_management/${Uri.encodeComponent(boardName)}';
  }
}

/// Central router configuration for the ARBoard application
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    errorBuilder: (context, state) => const ErrorPage(),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          // Board Management routes (nested under /arboard)
          GoRoute(
            path: 'board_management',
            builder: (context, state) => const BoardManagementPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NewBoardPage(),
                routes: [
                  GoRoute(
                    path: 'complete',
                    builder: (context, state) => const CompleteInfoPage(),
                  ),
                  GoRoute(
                    path: 'limited',
                    builder: (context, state) => const LimitedInfoPage(),
                  ),
                ],
              ),
              GoRoute(
                path: ':boardName',
                builder: (context, state) {
                  final boardName = state.pathParameters['boardName'] ?? '';
                  return BoardEditPage(boardName: boardName);
                },
              ),
            ],
          ),
          // Board Tool routes (nested under /arboard)
          GoRoute(
            path: 'board_tool',
            builder: (context, state) => const BoardToolPage(),
            routes: [
              GoRoute(
                path: ':boardName',
                builder: (context, state) {
                  final boardName = state.pathParameters['boardName'] ?? '';
                  return BoardToolDetailPage(boardName: boardName);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
