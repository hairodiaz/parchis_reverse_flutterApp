// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameSettingsAdapter extends TypeAdapter<GameSettings> {
  @override
  final int typeId = 1;

  @override
  GameSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameSettings(
      musicVolume: fields[0] as double,
      effectsVolume: fields[1] as double,
      notificationsVolume: fields[2] as double,
      soundEnabled: fields[3] as bool,
      musicEnabled: fields[4] as bool,
      notificationsEnabled: fields[5] as bool,
      vibrationEnabled: fields[6] as bool,
      language: fields[7] as String,
      theme: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GameSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.musicVolume)
      ..writeByte(1)
      ..write(obj.effectsVolume)
      ..writeByte(2)
      ..write(obj.notificationsVolume)
      ..writeByte(3)
      ..write(obj.soundEnabled)
      ..writeByte(4)
      ..write(obj.musicEnabled)
      ..writeByte(5)
      ..write(obj.notificationsEnabled)
      ..writeByte(6)
      ..write(obj.vibrationEnabled)
      ..writeByte(7)
      ..write(obj.language)
      ..writeByte(8)
      ..write(obj.theme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
