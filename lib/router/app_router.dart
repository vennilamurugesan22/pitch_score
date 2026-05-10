import 'package:go_router/go_router.dart';
import 'package:pitch_score/bloc/setup/match_setup_state.dart';
import 'package:pitch_score/screens/match_setup_screen.dart';
import 'package:pitch_score/screens/toss_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/scoring/scoring_screen.dart';
import '../screens/result/match_result_screen.dart';
import '../screens/history/match_history_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',          builder: (ctx, state) => const HomeScreen()),
    GoRoute(path: '/setup',     builder: (ctx, state) => const MatchSetupScreen()),
    GoRoute(path: '/toss',  builder: (ctx, state) => TossScreen(matchSetup: state.extra as MatchSetupState,),),
    GoRoute(path: '/scoring',   builder: (ctx, state) => const ScoringScreen()),
    GoRoute(path: '/result',    builder: (ctx, state) => const MatchResultScreen()),
    GoRoute(path: '/history',   builder: (ctx, state) => const MatchHistoryScreen()),
  ],
);