import 'package:hive/hive.dart';

part 'ball_model.g.dart';

// One delivery.
//
// `runs` = runs physically scored on this delivery — off the bat, or byes /
// leg byes / wides that were run. It does NOT include the 1-run penalty for a
// wide or no ball; that is added by [totalRuns].
//
//   Plain wide        → isWide, runs 0   → total 1
//   Wide + ran 2      → isWide, runs 2   → total 3
//   No ball hit for 4 → isNoBall, runs 4 → total 5 (4 to batsman)
//   2 leg byes        → isLegBye, runs 2 → total 2
@HiveType(typeId: 0)
class Ball extends HiveObject {

  @HiveField(0)
  final int runs;

  @HiveField(1)
  final bool isWicket;

  @HiveField(2)
  final bool isWide;

  @HiveField(3)
  final bool isNoBall;

  @HiveField(4)
  final bool isBye;

  @HiveField(5)
  final bool isLegBye;

  // Striker who faced this ball
  @HiveField(6)
  final String batsmanId;

  @HiveField(7)
  final String bowlerId;

  @HiveField(8)
  final String? wicketType; // caught / bowled / runout / lbw / stumped / hitwicket

  @HiveField(9)
  final DateTime timestamp;

  @HiveField(10)
  final String strikerNameBefore;  // id of striker before this ball

  @HiveField(11)
  final String nonStrikerNameBefore; // id of non-striker before this ball

  // Who got out — usually the striker, but a run out can be either end
  @HiveField(12)
  final String? dismissedBatsmanId;

  Ball({
    required this.runs,
    required this.isWicket,
    required this.isWide,
    required this.isNoBall,
    required this.isBye,
    required this.isLegBye,
    required this.batsmanId,
    required this.bowlerId,
    this.wicketType,
    required this.timestamp,
    required this.strikerNameBefore,
    required this.nonStrikerNameBefore,
    this.dismissedBatsmanId,
  });

  // For Firebase — convert to Map
  Map<String, dynamic> toMap() {
    return {
      'runs': runs,
      'isWicket': isWicket,
      'isWide': isWide,
      'isNoBall': isNoBall,
      'isBye': isBye,
      'isLegBye': isLegBye,
      'batsmanId': batsmanId,
      'bowlerId': bowlerId,
      'wicketType': wicketType,
      'timestamp': timestamp.toIso8601String(),
      'strikerNameBefore': strikerNameBefore,
      'nonStrikerNameBefore': nonStrikerNameBefore,
      'dismissedBatsmanId': dismissedBatsmanId,
    };
  }

  // For Firebase — create Ball from Map
  factory Ball.fromMap(Map<dynamic, dynamic> map) {
    return Ball(
      runs: (map['runs'] as num?)?.toInt() ?? 0,
      isWicket: map['isWicket'] == true,
      isWide: map['isWide'] == true,
      isNoBall: map['isNoBall'] == true,
      isBye: map['isBye'] == true,
      isLegBye: map['isLegBye'] == true,
      batsmanId: map['batsmanId'] ?? '',
      bowlerId: map['bowlerId'] ?? '',
      wicketType: map['wicketType'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      strikerNameBefore: map['strikerNameBefore'] ?? '',
      nonStrikerNameBefore: map['nonStrikerNameBefore'] ?? '',
      dismissedBatsmanId: map['dismissedBatsmanId'],
    );
  }

  // Helper — does this ball count in the over?
  bool get isLegalDelivery => !isWide && !isNoBall;

  // 1-run penalty for wide / no ball
  int get penaltyRuns => (isWide || isNoBall) ? 1 : 0;

  // Everything added to the team total on this delivery
  int get totalRuns => runs + penaltyRuns;

  // Runs credited to the batsman (off the bat)
  int get batsmanRuns => (isWide || isBye || isLegBye) ? 0 : runs;

  // Runs that go into the extras column
  int get extraRuns => totalRuns - batsmanRuns;

  // Runs charged to the bowler — byes and leg byes are not the bowler's fault
  int get bowlerRuns => (isBye || isLegBye) ? 0 : totalRuns;

  // Wide does NOT count as a ball faced by the batsman
  bool get isFacedByBatsman => !isWide;

  // Run outs are not credited to the bowler
  bool get isBowlerWicket => isWicket && wicketType != 'runout';

  bool get isFour => batsmanRuns == 4;
  bool get isSix => batsmanRuns == 6;

  // Who was dismissed on this ball (null if no wicket)
  String? get outBatsmanId =>
      isWicket ? (dismissedBatsmanId ?? batsmanId) : null;

  // Short label for ball circles e.g. "4", "W", "Wd+1", "NB4", "2LB"
  String get label {
    if (isWicket) return runs > 0 ? 'W+$runs' : 'W';
    if (isWide) return runs > 0 ? 'Wd+$runs' : 'Wd';
    if (isNoBall) return runs > 0 ? 'NB$runs' : 'NB';
    if (isLegBye) return '${runs}LB';
    if (isBye) return '${runs}B';
    if (runs == 0) return '•';
    return '$runs';
  }
}
