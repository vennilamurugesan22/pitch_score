import 'package:hive/hive.dart';

part 'player_model.g.dart';

@HiveType(typeId: 1)
class Player extends HiveObject {

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String teamId; // 'team1' or 'team2'

  Player({
    required this.id,
    required this.name,
    required this.teamId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teamId': teamId,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'],
      teamId: map['teamId'],
    );
  }
}