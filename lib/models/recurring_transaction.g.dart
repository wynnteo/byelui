// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionAdapter extends TypeAdapter<RecurringTransaction> {
  @override
  final int typeId = 26;

  @override
  RecurringTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      currency: fields[2] as String,
      type: fields[3] as TransactionType,
      scope: fields[4] as TransactionScope,
      categoryId: fields[5] as String,
      description: fields[6] as String,
      note: fields[7] as String?,
      frequency: fields[8] as RecurrenceFrequency,
      startDate: fields[9] as DateTime,
      nextDueDate: fields[10] as DateTime?,
      endDate: fields[11] as DateTime?,
      isActive: fields[12] == null ? true : fields[12] as bool,
      paymentMethod: fields[13] as PaymentMethod?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransaction obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.currency)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.scope)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.frequency)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.nextDueDate)
      ..writeByte(11)
      ..write(obj.endDate)
      ..writeByte(12)
      ..write(obj.isActive)
      ..writeByte(13)
      ..write(obj.paymentMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceFrequencyAdapter extends TypeAdapter<RecurrenceFrequency> {
  @override
  final int typeId = 25;

  @override
  RecurrenceFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceFrequency.daily;
      case 1:
        return RecurrenceFrequency.weekly;
      case 2:
        return RecurrenceFrequency.monthly;
      case 3:
        return RecurrenceFrequency.yearly;
      default:
        return RecurrenceFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceFrequency obj) {
    switch (obj) {
      case RecurrenceFrequency.daily:
        writer.writeByte(0);
        break;
      case RecurrenceFrequency.weekly:
        writer.writeByte(1);
        break;
      case RecurrenceFrequency.monthly:
        writer.writeByte(2);
        break;
      case RecurrenceFrequency.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
