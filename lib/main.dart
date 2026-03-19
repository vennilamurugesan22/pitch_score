import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pitch_score/models/ball_model.dart';
import 'package:pitch_score/models/match_model.dart';
import 'package:pitch_score/models/player_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp();
   await Hive.initFlutter();
   Hive.registerAdapter(BallAdapter());
   Hive.registerAdapter(PlayerAdapter());
   Hive.registerAdapter(MatchAdapter());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PitchScore',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: Text('PitchScore ✅', style: TextStyle(color: Colors.green)),
        ),
      ),
    );
  }
}