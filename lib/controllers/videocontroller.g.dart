// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'videocontroller.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskInfoAdapter extends TypeAdapter<TaskInfo> {
  @override
  final int typeId = 0;

  @override
  TaskInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskInfo(
      name: fields[1] as String,
      link: fields[2] as String,
      taskId: fields[3] as String,
      progress: fields[4] as int,
      status: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TaskInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.link)
      ..writeByte(3)
      ..write(obj.taskId)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
