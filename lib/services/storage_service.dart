import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class StorageService {
  static const String _itemsKey = 'items';
  static StorageService? _instance;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  List<Item>? _cachedItems;

  StorageService._();

  factory StorageService() {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

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
      _cachedItems = [];
      return [];
    }
  }

  Future<void> saveItems(List<Item> items) async {
    await _ensureInitialized();
    if (_prefs == null) return;

    try {
      _cachedItems = List.from(items);
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs!.setString(_itemsKey, jsonString);
    } catch (e) {
    }
  }

  Future<void> addItem(Item item) async {
    final items = await getItems();
    final newItems = List<Item>.from(items)..add(item);
    await saveItems(newItems);
  }

  Future<void> updateItem(Item item) async {
    final items = await getItems();
    final newItems = List<Item>.from(items);
    final index = newItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      newItems[index] = item;
      await saveItems(newItems);
    }
  }

  Future<void> deleteItem(String itemId) async {
    final items = await getItems();
    final newItems = List<Item>.from(items)
      ..removeWhere((item) => item.id == itemId);
    await saveItems(newItems);
  }

  Future<void> clearCache() async {
    _cachedItems = null;
  }
}
