import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';
import '../services/storage_service.dart';
import 'item_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    await _storageService.init();
    final items = await _storageService.getItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _navigateToForm([Item? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemFormScreen(item: item)),
    );
    if (result != null) {
      if (item == null) {
        await _storageService.addItem(result);
      } else {
        await _storageService.updateItem(result);
      }
      await _loadItems();
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个物品吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storageService.deleteItem(itemId);
      await _loadItems();
    }
  }

  Future<void> _importFromFile() async {
    BuildContext currentContext = context;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final lines = content.split('\n');

      int importedCount = 0;
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final parts = line.split('|').map((p) => p.trim()).toList();
        if (parts.length >= 3) {
          final name = parts[0];
          final priceStr = parts[1];
          final dateStr = parts[2];

          final price = double.tryParse(priceStr);
          final date = DateTime.tryParse(dateStr);

          if (price != null && date != null) {
            final item = Item(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  importedCount.toString(),
              name: name,
              price: price,
              purchaseDate: date,
            );
            await _storageService.addItem(item);
            importedCount++;
          }
        }
      }

      await _loadItems();
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(SnackBar(content: Text('成功导入 $importedCount 个物品')));
    } catch (e) {
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(const SnackBar(content: Text('导入失败，请检查文件格式')));
    }
  }

  Future<void> _exportToFile() async {
    BuildContext currentContext = context;
    try {
      final items = await _storageService.getItems();
      if (items.isEmpty) {
        ScaffoldMessenger.of(
          currentContext,
        ).showSnackBar(const SnackBar(content: Text('没有数据可导出')));
        return;
      }

      String content = '';
      for (final item in items) {
        content +=
            '${item.name} | ${item.price} | ${item.formattedPurchaseDate} |\n';
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: 'items_${DateTime.now().millisecondsSinceEpoch}.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result == null) return;

      final file = File(result);
      await file.writeAsString(content);

      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(SnackBar(content: Text('导出成功，文件保存在: ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(const SnackBar(content: Text('导出失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物品价值计算器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToFile,
            tooltip: '导出到文件',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '还没有添加物品',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _navigateToForm(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _deleteItem(item.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('购买价格', item.formattedPrice),
                        _buildInfoRow('购买日期', item.formattedPurchaseDate),
                        _buildInfoRow('使用天数', '${item.daysUsed} 天'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '平均每日成本',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              item.formattedAveragePrice,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('添加物品'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToForm();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('从文件导入'),
                  onTap: () {
                    Navigator.pop(context);
                    _importFromFile();
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
