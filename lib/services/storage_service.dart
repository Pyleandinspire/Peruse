import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

/// 存储服务类，用于管理物品数据的本地存储
class StorageService {
  /// 存储物品数据的键名
  static const String _itemsKey = 'items';
  /// 单例实例
  static StorageService? _instance;
  /// SharedPreferences实例
  SharedPreferences? _prefs;
  /// 初始化状态
  bool _isInitialized = false;
  /// 缓存的物品列表
  List<Item>? _cachedItems;

  /// 私有构造函数
  StorageService._();

  /// 获取存储服务单例
  /// 
  /// 返回存储服务实例
  factory StorageService() {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// 初始化存储服务
  /// 
  /// 初始化SharedPreferences实例
  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  /// 确保存储服务已初始化
  /// 
  /// 如果未初始化，则调用init()方法
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  /// 获取物品列表
  /// 
  /// [forceRefresh]: 是否强制刷新缓存
  /// 返回物品列表的不可修改副本
  Future<List<Item>> getItems({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedItems != null) {
      return List.unmodifiable(_cachedItems!);
    }

    await _ensureInitialized();
    if (_prefs == null) return [];

    try {
      final jsonString = _prefs!.getString(_itemsKey);
      if (jsonString == null) {
        _cachedItems = [];
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      _cachedItems = jsonList
          .map((json) => Item.fromJson(json as Map<String, dynamic>))
          .toList();
      return List.unmodifiable(_cachedItems!);
    } catch (e) {
      debugPrint('Error reading items: $e');
      _cachedItems = [];
      return [];
    }
  }

  /// 保存物品列表
  /// 
  /// [items]: 要保存的物品列表
  Future<void> saveItems(List<Item> items) async {
    await _ensureInitialized();
    if (_prefs == null) return;

    try {
      _cachedItems = List.from(items);
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs!.setString(_itemsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving items: $e');
    }
  }

  /// 添加物品
  /// 
  /// [item]: 要添加的物品
  Future<void> addItem(Item item) async {
    final items = await getItems();
    final newItems = List<Item>.from(items)..add(item);
    await saveItems(newItems);
  }

  /// 更新物品
  /// 
  /// [item]: 要更新的物品
  Future<void> updateItem(Item item) async {
    final items = await getItems();
    final newItems = List<Item>.from(items);
    final index = newItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      newItems[index] = item;
      await saveItems(newItems);
    }
  }

  /// 删除物品
  /// 
  /// [itemId]: 要删除的物品ID
  Future<void> deleteItem(String itemId) async {
    final items = await getItems();
    final newItems = List<Item>.from(items)
      ..removeWhere((item) => item.id == itemId);
    await saveItems(newItems);
  }

  /// 清除缓存
  /// 
  /// 清除当前缓存的物品列表
  Future<void> clearCache() async {
    _cachedItems = null;
  }
}
