import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pitch_score/bloc/history/match_history_bloc.dart';
import 'package:pitch_score/bloc/history/match_history_event.dart';
import 'package:pitch_score/firebase_options.dart';
import 'package:pitch_score/models/ball_model.dart';
import 'package:pitch_score/models/match_model.dart';
import 'package:pitch_score/models/player_model.dart';
import 'package:pitch_score/router/app_router.dart';
import 'package:pitch_score/services/app_update_service.dart';
import 'package:pitch_score/services/firebase/push_notification_service.dart';
import 'package:pitch_score/services/local/match_storage.dart';
import 'package:pitch_score/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive (offline storage) — the app must always work without internet
  await Hive.initFlutter();
  Hive.registerAdapter(BallAdapter());
  Hive.registerAdapter(PlayerAdapter());
  Hive.registerAdapter(MatchAdapter());
  await MatchStorage.init();
  await AppUpdateService.init();

  // ── Firebase (live sharing) — optional; failure = offline-only app
  try {
    // Android may already have created [DEFAULT] natively from
    // google-services.json — initialising again throws duplicate-app
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      } on FirebaseException catch (e) {
        if (e.code != 'duplicate-app') rethrow;
      }
    }
    final db = FirebaseDatabase.instance;
    db.databaseURL = 'https://pitchscore-d15a6-default-rtdb.firebaseio.com';
    // Queue writes while the ground has no signal, send when it's back
    db.setPersistenceEnabled(true);
    // Not awaited — waiting for an FCM / APNs token must never block startup
    PushNotificationService.init();
  } catch (e) {
    debugPrint('Firebase unavailable, running offline only: $e');
  }

  runApp(const PitchScoreApp());
}

class PitchScoreApp extends StatelessWidget {
  const PitchScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // MatchHistoryBloc — top level, load history on app start
        BlocProvider(
          create: (_) => MatchHistoryBloc()..add(const LoadHistoryEvent()),
        ),
      ],
      child: MaterialApp.router(
        title: 'PitchScore',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          // Primary green accent — used for buttons, highlights
          colorScheme: const ColorScheme.dark(
            primary: AppColors.green,
            secondary: Color(0xFF1DE9B6),
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceLight,
            contentTextStyle: TextStyle(color: AppColors.textPrimary),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: AppColors.surface,
          ),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
