import 'package:intl/intl.dart';

/// 物品模型类，用于表示用户的购买物品
class Item {
  /// 物品唯一标识符
  final String id;
  /// 物品名称
  final String name;
  /// 购买价格
  final double price;
  /// 购买日期
  final DateTime purchaseDate;

  /// 创建物品实例
  /// 
  /// [id]: 物品唯一标识符
  /// [name]: 物品名称
  /// [price]: 购买价格
  /// [purchaseDate]: 购买日期
  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.purchaseDate,
  });

  /// 计算物品已使用天数
  /// 
  /// 返回从购买日期到当前日期的天数，最少为1天
  int get daysUsed {
    final now = DateTime.now();
    final difference = now.difference(purchaseDate);
    final days = difference.inDays;
    return days < 0 ? 0 : days + 1;
  }

  /// 计算物品的平均每日成本
  /// 
  /// 返回价格除以使用天数的结果，如果使用天数为0，则返回原价
  double get averagePricePerDay {
    if (daysUsed <= 0) return price;
    return price / daysUsed;
  }

  /// 格式化价格为货币形式
  /// 
  /// 返回格式化后的价格字符串，如 "¥100.00"
  String get formattedPrice {
    return NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    ).format(price);
  }

  /// 格式化平均每日成本为货币形式
  /// 
  /// 返回格式化后的平均每日成本字符串，如 "¥1.00"
  String get formattedAveragePrice {
    return NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    ).format(averagePricePerDay);
  }

  /// 格式化购买日期为字符串
  /// 
  /// 返回格式化后的日期字符串，格式为 "yyyy-MM-dd"
  String get formattedPurchaseDate {
    return DateFormat('yyyy-MM-dd').format(purchaseDate);
  }

  /// 将物品转换为JSON格式
  /// 
  /// 返回包含物品信息的JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  /// 从JSON格式创建物品实例
  /// 
  /// [json]: 包含物品信息的JSON映射
  /// 返回创建的物品实例
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as double,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
    );
  }

  /// 创建物品的副本，可选择性修改属性
  /// 
  /// [id]: 可选，新的物品ID
  /// [name]: 可选，新的物品名称
  /// [price]: 可选，新的购买价格
  /// [purchaseDate]: 可选，新的购买日期
  /// 返回修改后的物品实例
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
