# pitch_score 
Live Cricket Scorer

Score your local cricket match ball by ball. Watch live on any device.

## Features
- Live ball-by-ball scoring
- Real-time sync via Firebase — share a 6-digit code, anyone can watch live
- Works offline too — no internet? no problem
- Share scorecard image directly to WhatsApp
- Add players from contacts or manually
- Animated toss, over-by-over summary, full scorecard
- Wides / no balls (with free hit) / byes / leg byes with runs, run outs at either end
- Resume an unfinished match after the app is closed
- Undo any ball, including across overs and the innings-ending ball

## Tech Stack
- Flutter + Dart
- BLoC pattern (flutter_bloc)
- Firebase Realtime Database
- Hive (local storage)
- go_router

## Architecture
Event-sourced scoring — every delivery stored as a `Ball` object.
All match stats (CRR, RRR, strike rate, economy) computed from the ball log.
Undo is free — just remove last ball and recompute.

## Project structure
```
lib/
  bloc/scoring/   ScoringBloc, ScoringState, ScoringRules (pure cricket rules),
                  InningsSummary (scorecard stats computed from the ball log)
  bloc/setup/     MatchSetupCubit
  bloc/history/   MatchHistoryBloc (Hive 'matches' box)
  models/         Ball, Player, Match (+ generated Hive adapters)
  services/       FirebaseMatchService, MatchStorage (in-progress match), FCM
  screens/        splash, home, setup, toss, scoring, innings_break,
                  scorecard, result, live, history, settings
  widgets/        LiveScorePanel (shared by scorer + spectator), BallCircle,
                  InningsScorecard
```

## Firebase layout
```
/matches/{code}/meta              team names, overs, status
/matches/{code}/players           [{id, name, teamId}]
/matches/{code}/innings/{n}/balls ball list per innings
/matches/{code}/state             full snapshot — spectators listen here
/matches/{code}/viewers/{id}      presence (removed automatically on disconnect)
```

## Live links (deep links)
The scorer taps **Share** on the scoring screen → `https://pitchscore-d15a6.web.app/watch/<code>`.
Tapping it opens the app on Watch Live for that match (route `/watch/:code`).
Requires the hosting files to be deployed once — see [hosting/README.md](hosting/README.md):
```bash
firebase login --reauth && firebase deploy --only hosting
```
Fallback scheme: `pitchscore://app/watch/<code>`.

## App updates
Remote-controlled from Firebase `/config/app_update`
(`latest_version` → optional prompt, `min_version` → forced update, `android_url`, `message`).

## Tests
```bash
flutter test                                                   # 39 unit tests
flutter test integration_test/full_match_test.dart -d <device> # full match E2E
```

## Screenshots
*Coming soon*

## Getting Started
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after model changes
flutter run
```

> Add your `google-services.json` to `android/app/` before running.