// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 24;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      currency: fields[2] as String,
      type: fields[3] as TransactionType,
      scope: fields[4] as TransactionScope,
      categoryId: fields[5] as String,
      date: fields[6] as DateTime,
      description: fields[7] as String,
      note: fields[8] as String?,
      photoPath: fields[9] as String?,
      paymentMethod: fields[10] as PaymentMethod?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      tags: fields[13] == null ? [] : (fields[13] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
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
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.photoPath)
      ..writeByte(10)
      ..write(obj.paymentMethod)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionScopeAdapter extends TypeAdapter<TransactionScope> {
  @override
  final int typeId = 22;

  @override
  TransactionScope read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionScope.personal;
      case 1:
        return TransactionScope.family;
      default:
        return TransactionScope.personal;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionScope obj) {
    switch (obj) {
      case TransactionScope.personal:
        writer.writeByte(0);
        break;
      case TransactionScope.family:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionScopeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final int typeId = 23;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.cash;
      case 1:
        return PaymentMethod.card;
      case 2:
        return PaymentMethod.eWallet;
      case 3:
        return PaymentMethod.bankTransfer;
      case 4:
        return PaymentMethod.other;
      default:
        return PaymentMethod.cash;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.cash:
        writer.writeByte(0);
        break;
      case PaymentMethod.card:
        writer.writeByte(1);
        break;
      case PaymentMethod.eWallet:
        writer.writeByte(2);
        break;
      case PaymentMethod.bankTransfer:
        writer.writeByte(3);
        break;
      case PaymentMethod.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
