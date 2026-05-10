import 'package:flutter_test/flutter_test.dart';
import 'package:longterm_app/models/item.dart';

void main() {
  group('Item Model Tests - 平均价格计算', () {
    const String testId = 'test-id-123';
    const String testName = 'Test Item';

    test('平均价格计算 - 正常情况', () {
      final item = Item(
        id: testId,
        name: testName,
        price: 100.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 9)),
      );

      expect(item.daysUsed, 10);
      expect(item.averagePricePerDay, 10.0);
      expect(item.formattedAveragePrice, '¥10.00');
    });

    test('平均价格计算 - 购买价格为0', () {
      final item = Item(
        id: testId,
        name: testName,
        price: 0.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 9)),
      );

      expect(item.daysUsed, 10);
      expect(item.averagePricePerDay, 0.0);
      expect(item.formattedAveragePrice, '¥0.00');
    });

    test('平均价格计算 - 使用天数为1', () {
      final item = Item(
        id: testId,
        name: testName,
        price: 50.0,
        purchaseDate: DateTime.now(),
      );

      expect(item.daysUsed, 1);
      expect(item.averagePricePerDay, 50.0);
      expect(item.formattedAveragePrice, '¥50.00');
    });

    test('平均价格计算 - 使用天数为0（未来日期）', () {
      final item = Item(
        id: testId,
        name: testName,
        price: 100.0,
        purchaseDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(item.daysUsed, 0);
      expect(item.averagePricePerDay, 100.0);
      expect(item.formattedAveragePrice, '¥100.00');
    });

    test('平均价格计算 - 需要四舍五入', () {
      final item = Item(
        id: testId,
        name: testName,
        price: 100.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(item.daysUsed, 4);
      expect(item.averagePricePerDay, 25.0);
      expect(item.formattedAveragePrice, '¥25.00');
    });

    test('平均价格计算 - 复杂小数', () {
      final item = Item(
        id: testId,
        name: testName,
        price: 99.99,
        purchaseDate: DateTime.now().subtract(const Duration(days: 7)),
      );

      expect(item.daysUsed, 8);
      expect(item.averagePricePerDay, closeTo(12.49875, 0.0001));
      expect(item.formattedAveragePrice, '¥12.50');
    });

    test('平均价格计算 - 大额价格', () {
      final item = Item(
        id: testId,
        name: testName,
        price: 12999.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 364)),
      );

      expect(item.daysUsed, 365);
      expect(item.averagePricePerDay, closeTo(35.6137, 0.0001));
      expect(item.formattedAveragePrice, '¥35.61');
    });

    test('平均价格计算 - 边界值测试', () {
      final item = Item(
        id: testId,
        name: testName,
        price: 0.01,
        purchaseDate: DateTime.now().subtract(const Duration(days: 99)),
      );

      expect(item.daysUsed, 100);
      expect(item.averagePricePerDay, 0.0001);
      expect(item.formattedAveragePrice, '¥0.00');
    });
  });
}
