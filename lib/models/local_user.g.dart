// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalUserAdapter extends TypeAdapter<LocalUser> {
  @override
  final int typeId = 0;

  @override
  LocalUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalUser(
      name: fields[0] as String,
      gamesWon: fields[1] as int,
      gamesPlayed: fields[2] as int,
      currentStreak: fields[3] as int,
      bestStreak: fields[4] as int,
      achievements: (fields[5] as List).cast<String>(),
      isGuest: fields[6] as bool,
      lastLoginDate: fields[7] as DateTime?,
      facebookId: fields[8] as String?,
      email: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalUser obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.gamesWon)
      ..writeByte(2)
      ..write(obj.gamesPlayed)
      ..writeByte(3)
      ..write(obj.currentStreak)
      ..writeByte(4)
      ..write(obj.bestStreak)
      ..writeByte(5)
      ..write(obj.achievements)
      ..writeByte(6)
      ..write(obj.isGuest)
      ..writeByte(7)
      ..write(obj.lastLoginDate)
      ..writeByte(8)
      ..write(obj.facebookId)
      ..writeByte(9)
      ..write(obj.email);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
