import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pitch_score/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive (offline storage) — the app must always work without internet
  await Hive.initFlutter();
  Hive.registerAdapter(BallAdapter());
  Hive.registerAdapter(PlayerAdapter());
  Hive.registerAdapter(MatchAdapter());
  await MatchStorage.init();
  await AppUpdateService.init();
  await ThemeController.instance.init();

  // ── Firebase (live sharing) — optional; failure = offline-only app
  try {
    // Android may already have created [DEFAULT] natively from
    // google-services.json — initialising again throws duplicate-app
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
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

class PitchScoreApp extends StatefulWidget {
  const PitchScoreApp({super.key});

  @override
  State<PitchScoreApp> createState() => _PitchScoreAppState();
}

class _PitchScoreAppState extends State<PitchScoreApp>
    with WidgetsBindingObserver {
  final _theme = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _theme.addListener(_applyTheme);
    AppColors.palette = _theme.resolve(_platformBrightness);
  }

  @override
  void dispose() {
    _theme.removeListener(_applyTheme);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 'System' theme follows the phone's dark / light switch
  @override
  void didChangePlatformBrightness() => _applyTheme();

  Brightness get _platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  void _applyTheme() {
    final palette = _theme.resolve(_platformBrightness);
    if (identical(palette, AppColors.palette)) return;
    setState(() => AppColors.palette = palette);
    // Screens read AppColors directly, so rebuild every widget —
    // including routes further down the stack — to pick up the new colors
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  ThemeData _buildTheme(AppPalette p) {
    final isDark = p.brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      // Primary green accent — used for buttons, highlights
      colorScheme:
          (isDark ? const ColorScheme.dark() : const ColorScheme.light())
              .copyWith(
                primary: p.green,
                onPrimary: p.onAccent,
                secondary: p.blue,
                onSecondary: p.onAccent,
                error: p.red,
                surface: p.surface,
                onSurface: p.textPrimary,
                outline: p.border,
              ),
      scaffoldBackgroundColor: p.background,
      dividerColor: p.border,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: p.surface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.surfaceLight : p.textPrimary,
        contentTextStyle: TextStyle(color: isDark ? p.textPrimary : p.surface),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.green),
      textSelectionTheme: TextSelectionThemeData(cursorColor: p.green),
    );
  }

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
        theme: _buildTheme(AppColors.palette),
        routerConfig: appRouter,
      ),
    );
  }
}
