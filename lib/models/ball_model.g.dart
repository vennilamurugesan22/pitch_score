// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ball_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BallAdapter extends TypeAdapter<Ball> {
  @override
  final int typeId = 0;

  @override
  Ball read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ball(
      runs: fields[0] as int,
      isWicket: fields[1] as bool,
      isWide: fields[2] as bool,
      isNoBall: fields[3] as bool,
      isBye: fields[4] as bool,
      isLegBye: fields[5] as bool,
      batsmanId: fields[6] as String,
      bowlerId: fields[7] as String,
      wicketType: fields[8] as String?,
      timestamp: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Ball obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.runs)
      ..writeByte(1)
      ..write(obj.isWicket)
      ..writeByte(2)
      ..write(obj.isWide)
      ..writeByte(3)
      ..write(obj.isNoBall)
      ..writeByte(4)
      ..write(obj.isBye)
      ..writeByte(5)
      ..write(obj.isLegBye)
      ..writeByte(6)
      ..write(obj.batsmanId)
      ..writeByte(7)
      ..write(obj.bowlerId)
      ..writeByte(8)
      ..write(obj.wicketType)
      ..writeByte(9)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BallAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
