import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pitch_score/bloc/history/match_history_bloc.dart';
import 'package:pitch_score/bloc/history/match_history_event.dart';
import 'package:pitch_score/bloc/scoring/scoring_bloc.dart';
import 'package:pitch_score/models/ball_model.dart';
import 'package:pitch_score/models/match_model.dart';
import 'package:pitch_score/models/player_model.dart';
import 'package:pitch_score/router/app_router.dart';
import 'package:pitch_score/services/firebase/firebase_match_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp();
   // Add this line
   FirebaseDatabase.instance.databaseURL = 'https://pitchscore-d15a6-default-rtdb.firebaseio.com';
   await Hive.initFlutter();
   Hive.registerAdapter(BallAdapter());
   Hive.registerAdapter(PlayerAdapter());
   Hive.registerAdapter(MatchAdapter());

/// hive write and read tesing 
  final box = await Hive.openBox<Ball>('test_balls');
  await box.put('test', Ball(
    runs: 4,
    isWicket: false,
    isWide: false,
    isNoBall: false,
    isBye: false,
    isLegBye: false,
    batsmanId: 'p1',
    bowlerId: 'p2',
    strikerNameBefore: 'p1',
    nonStrikerNameBefore: 'p3',
    timestamp: DateTime.now(),
  ));
  final retrieved = box.get('test');
  print('✅ Hive working — runs: ${retrieved?.runs}');

  // Temporary Firebase test — remove after verifying
  final testService = FirebaseMatchService();
  await testService.createMatch(
    matchCode: 'TEST01',
    teamOneName: 'Chennai XI',
    teamTwoName: 'Mumbai Kings',
    totalOvers: 6,
    maxWickets: 10,
  );
  print('✅ Firebase write successful!');


  runApp(const PitchScoreApp());
}
class PitchScoreApp extends StatelessWidget {
  const PitchScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ScoringBloc — top level, needed across multiple screens
        BlocProvider(
          create: (_) => ScoringBloc(
            matchCode: '',
            isLiveMode: false,
          ),
        ),
        // MatchHistoryBloc — top level, load history on app start
        BlocProvider(
          create: (_) => MatchHistoryBloc()
            ..add(const LoadHistoryEvent()),
        ),
      ],
      child: MaterialApp.router(
        title: 'PitchScore',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          // Primary green accent — used for buttons, highlights
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00C853),
            secondary: Color(0xFF1DE9B6),
            surface: Color(0xFF1A1A2E),
          ),  
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F0F1A),
            elevation: 0,
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}