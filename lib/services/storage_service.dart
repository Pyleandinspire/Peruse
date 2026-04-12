import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class StorageService {
  static const String _itemsKey = 'items';
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  factory StorageService() {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Item>> getItems() async {
    final jsonString = _prefs?.getString(_itemsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Item.fromJson(json)).toList();
  }

  Future<void> saveItems(List<Item> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await _prefs?.setString(_itemsKey, jsonString);
  }

  Future<void> addItem(Item item) async {
    final items = await getItems();
    items.add(item);
    await saveItems(items);
  }

  Future<void> updateItem(Item item) async {
    final items = await getItems();
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      await saveItems(items);
    }
  }

  Future<void> deleteItem(String itemId) async {
    final items = await getItems();
    items.removeWhere((item) => item.id == itemId);
    await saveItems(items);
  }
}
