import 'package:go_router/go_router.dart';
import 'package:pitch_score/bloc/scoring/scoring_bloc.dart';
import 'package:pitch_score/bloc/scoring/scoring_state.dart';
import 'package:pitch_score/bloc/setup/match_setup_state.dart';
import '../screens/history/match_history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/innings_break/innings_break_screen.dart';
import '../screens/live/watch_live_screen.dart';
import '../screens/result/match_result_screen.dart';
import '../screens/scorecard/scorecard_screen.dart';
import '../screens/scoring/scoring_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/setup/match_setup_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/toss/toss_screen.dart';

// Every screen is a child of Home, so context.go('/result') etc. always
// leaves Home underneath — the back button never exits the app by surprise.
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
    GoRoute(
      path: '/',
      builder: (ctx, state) => const HomeScreen(),
      routes: [
        GoRoute(path: 'setup', builder: (ctx, state) => const MatchSetupScreen()),
        GoRoute(
          path: 'toss',
          builder: (ctx, state) =>
              TossScreen(matchSetup: state.extra as MatchSetupState),
        ),
        GoRoute(
          path: 'scoring',
          builder: (ctx, state) =>
              ScoringScreen(initialState: state.extra as ScoringState),
        ),
        GoRoute(
          path: 'innings-break',
          builder: (ctx, state) =>
              InningsBreakScreen(bloc: state.extra as ScoringBloc),
        ),
        GoRoute(
          path: 'result',
          builder: (ctx, state) =>
              MatchResultScreen(state: state.extra as ScoringState),
        ),
        GoRoute(
          path: 'scorecard',
          builder: (ctx, state) =>
              ScorecardScreen(state: state.extra as ScoringState),
        ),
        GoRoute(
          path: 'watch',
          builder: (ctx, state) =>
              WatchLiveScreen(initialCode: state.extra as String?),
          routes: [
            // Deep link from a shared live link — opens straight into the match
            GoRoute(
              path: ':code',
              builder: (ctx, state) =>
                  WatchLiveScreen(initialCode: state.pathParameters['code']),
            ),
          ],
        ),
        GoRoute(path: 'history', builder: (ctx, state) => const MatchHistoryScreen()),
        GoRoute(path: 'settings', builder: (ctx, state) => const SettingsScreen()),
      ],
    ),
  ],
  // e.g. hot restart on a screen whose `extra` is gone — go home safely
  errorBuilder: (ctx, state) => const HomeScreen(),
);
