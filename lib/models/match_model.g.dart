// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchAdapter extends TypeAdapter<Match> {
  @override
  final int typeId = 2;

  @override
  Match read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Match(
      id: fields[0] as String,
      matchCode: fields[1] as String,
      teamOneName: fields[2] as String,
      teamTwoName: fields[3] as String,
      totalOvers: fields[4] as int,
      maxWickets: fields[5] as int,
      players: (fields[6] as List).cast<Player>(),
      firstInningsBalls: (fields[7] as List).cast<Ball>(),
      secondInningsBalls: (fields[8] as List).cast<Ball>(),
      result: fields[9] as String?,
      tossWinner: fields[10] as String?,
      tossChoice: fields[11] as String?,
      matchDate: fields[12] as DateTime,
      isLiveMode: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Match obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.matchCode)
      ..writeByte(2)
      ..write(obj.teamOneName)
      ..writeByte(3)
      ..write(obj.teamTwoName)
      ..writeByte(4)
      ..write(obj.totalOvers)
      ..writeByte(5)
      ..write(obj.maxWickets)
      ..writeByte(6)
      ..write(obj.players)
      ..writeByte(7)
      ..write(obj.firstInningsBalls)
      ..writeByte(8)
      ..write(obj.secondInningsBalls)
      ..writeByte(9)
      ..write(obj.result)
      ..writeByte(10)
      ..write(obj.tossWinner)
      ..writeByte(11)
      ..write(obj.tossChoice)
      ..writeByte(12)
      ..write(obj.matchDate)
      ..writeByte(13)
      ..write(obj.isLiveMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
