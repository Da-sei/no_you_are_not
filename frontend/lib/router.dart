import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/chat_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/goal_form_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/thought_log_screen.dart';
import 'screens/tutorial_screen.dart';
import 'widgets/app_shell.dart';

// Auth redirect is handled in main.dart (App widget).
// This router only governs authenticated routes.
final appRouter = GoRouter(
  initialLocation: '/missions',
  redirect: (context, state) async {
    if (state.uri.path == '/tutorial') return null;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('tutorial_seen') ?? false;
    if (!seen) return '/tutorial?forced=true';
    return null;
  },
  routes: [
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => TutorialScreen(
        forcedFlow: state.uri.queryParameters['forced'] == 'true',
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/missions',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/archive',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThoughtLogScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/goal/new',
      builder: (context, state) => const GoalFormScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['conversationId']!);
        final goal = state.uri.queryParameters['goal'] ?? '';
        return ChatScreen(conversationId: id, goalContent: goal);
      },
    ),
  ],
);
