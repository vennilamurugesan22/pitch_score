import 'package:hive/hive.dart';
import 'ball_model.dart';
import 'player_model.dart';

part 'match_model.g.dart';

@HiveType(typeId: 2)
class Match extends HiveObject {

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String matchCode; // 6-digit code e.g. CR4829

  @HiveField(2)
  final String teamOneName;

  @HiveField(3)
  final String teamTwoName;

  @HiveField(4)
  final int totalOvers;

  @HiveField(5)
  final int maxWickets;

  @HiveField(6)
  final List<Player> players;

  @HiveField(7)
  final List<Ball> firstInningsBalls;

  @HiveField(8)
  final List<Ball> secondInningsBalls;

  @HiveField(9)
  final String? result; // "Chennai XI won by 4 runs"

  @HiveField(10)
  final String? tossWinner;

  @HiveField(11)
  final String? tossChoice; // 'bat' or 'bowl'

  @HiveField(12)
  final DateTime matchDate;

  @HiveField(13)
  final bool isLiveMode;

  Match({
    required this.id,
    required this.matchCode,
    required this.teamOneName,
    required this.teamTwoName,
    required this.totalOvers,
    required this.maxWickets,
    required this.players,
    required this.firstInningsBalls,
    required this.secondInningsBalls,
    this.result,
    this.tossWinner,
    this.tossChoice,
    required this.matchDate,
    required this.isLiveMode,
  });

  // For Firebase meta
  Map<String, dynamic> toMetaMap() {
    return {
      'id': id,
      'matchCode': matchCode,
      'teamOneName': teamOneName,
      'teamTwoName': teamTwoName,
      'totalOvers': totalOvers,
      'maxWickets': maxWickets,
      'tossWinner': tossWinner,
      'tossChoice': tossChoice,
      'isLiveMode': isLiveMode,
      'status': 'live',
      'matchDate': matchDate.toIso8601String(),
      'players': players.map((p) => p.toMap()).toList(),
    };
  }
}