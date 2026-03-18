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

## Screenshots
*Coming soon*

## Getting Started
```bash
flutter pub get
flutter run
```

> Add your `google-services.json` to `android/app/` before running.