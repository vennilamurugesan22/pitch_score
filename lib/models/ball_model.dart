import 'package:hive/hive.dart';

part 'ball_model.g.dart';

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

  @HiveField(6)
  final String batsmanId;

  @HiveField(7)
  final String bowlerId;

  @HiveField(8)
  final String? wicketType; // caught / bowled / runout / lbw / stumped / hitwicket

  @HiveField(9)
  final DateTime timestamp;

  @HiveField(10)
  final String strikerNameBefore;  // who was batting before this ball

  @HiveField(11)  
  final String nonStrikerNameBefore; // who was at other end

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
      'nonStrikerNameBefore': nonStrikerNameBefore
    };
  }

  // For Firebase — create Ball from Map
  factory Ball.fromMap(Map<String, dynamic> map) {
    return Ball(
      runs: map['runs'],
      isWicket: map['isWicket'],
      isWide: map['isWide'],
      isNoBall: map['isNoBall'],
      isBye: map['isBye'],
      isLegBye: map['isLegBye'],
      batsmanId: map['batsmanId'],
      bowlerId: map['bowlerId'],
      wicketType: map['wicketType'],
      timestamp: DateTime.parse(map['timestamp']), 
      strikerNameBefore: map['strikerNameBefore'], 
      nonStrikerNameBefore: map['nonStrikerNameBefore'],
    );
  }

  // Helper — does this ball count in the over?
  bool get isLegalDelivery => !isWide && !isNoBall;

  // Helper — did batsman actually score (not extras)?
  bool get isBatsmanRun => !isBye && !isLegBye && !isWide;
}