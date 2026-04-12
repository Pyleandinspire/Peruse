import 'package:intl/intl.dart';

class Item {
  final String id;
  final String name;
  final double price;
  final DateTime purchaseDate;

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.purchaseDate,
  });

  int get daysUsed {
    final now = DateTime.now();
    final difference = now.difference(purchaseDate);
    return difference.inDays + 1;
  }

  double get averagePricePerDay {
    if (daysUsed <= 0) return price;
    return price / daysUsed;
  }

  String get formattedPrice {
    return NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(price);
  }

  String get formattedAveragePrice {
    return NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(averagePricePerDay);
  }

  String get formattedPurchaseDate {
    return DateFormat('yyyy-MM-dd').format(purchaseDate);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as double,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
    );
  }

  Item copyWith({
    String? id,
    String? name,
    double? price,
    DateTime? purchaseDate,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }
}
