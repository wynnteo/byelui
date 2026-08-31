import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'payment_card.g.dart';

/// A named card or payment source the user wants to select on individual
/// transactions and see broken down in Analytics — e.g. "Trust Card",
/// "Mari Card". Plain cash/e-wallet/etc. is still handled by the existing
/// [PaymentMethod] enum on Transaction; this is only for named cards.
@HiveType(typeId: 28)
class PaymentCard extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconName;

  @HiveField(3)
  int colorValue;

  @HiveField(4, defaultValue: true)
  bool isActive;

  @HiveField(5)
  DateTime createdAt;

  PaymentCard({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.isActive = true,
    required this.createdAt,
  });

  IconData get icon {
    switch (iconName) {
      case 'bank':
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'star':
        return Icons.star;
      case 'gift':
        return Icons.card_giftcard;
      case 'card':
      default:
        return Icons.credit_card;
    }
  }

  Color get color => Color(colorValue);

  static const List<String> selectableIconNames = ['card', 'bank', 'wallet', 'star', 'gift'];

  PaymentCard copyWith({
    String? name,
    String? iconName,
    int? colorValue,
    bool? isActive,
  }) {
    return PaymentCard(
      id: id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
