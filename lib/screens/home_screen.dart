import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  bool _isSelectionMode = false;
  Set<String> _selectedItemIds = {};

  double get totalValue {
    return _items.fold<double>(0, (sum, item) => sum + item.price);
  }

  double get averageDailyCost {
    if (_items.isEmpty) return 0;
    final totalDailyCost = _items.fold<double>(
      0,
      (sum, item) => sum + item.averagePricePerDay,
    );
    return totalDailyCost / _items.length;
  }

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

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedItemIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
    });
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedItemIds.length == _items.length) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds = _items.map((item) => item.id).toSet();
      }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedItemIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedItemIds.length} 个物品吗？'),
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
      for (final itemId in _selectedItemIds) {
        await _storageService.deleteItem(itemId);
      }
      await _loadItems();
      _exitSelectionMode();
    }
  }

  Future<void> _importFromFile() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('成功导入 $importedCount 个物品')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('导入失败，请检查文件格式')),
        );
      }
    }
  }

  Future<void> _exportToFile() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final items = await _storageService.getItems();
      if (items.isEmpty) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('没有数据可导出')),
          );
        }
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

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('导出成功，文件保存在: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('导出失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('已选择 ${_selectedItemIds.length} 个'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                TextButton(
                  onPressed: _selectAll,
                  child: Text(
                    _selectedItemIds.length == _items.length ? '取消全选' : '全选',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _batchDelete,
                ),
              ],
            )
          : AppBar(
              title: TextButton(
                onPressed: _showUsageGuide,
                child: const Text(
                  '长物',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: _enterSelectionMode,
                  tooltip: '批量删除',
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _exportToFile,
                  tooltip: '导出到文件',
                ),
              ],
            ),
      body: Column(
        children: [
          if (_items.isNotEmpty) _buildSummaryCard(),
          Expanded(
            child: _isLoading
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
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = _selectedItemIds.contains(item.id);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: InkWell(
                          onTap: _isSelectionMode
                              ? () => _toggleItemSelection(item.id)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_isSelectionMode)
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          _toggleItemSelection(item.id);
                                        },
                                      ),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (!_isSelectionMode)
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _navigateToForm(item),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            onPressed: () =>
                                                _deleteItem(item.id),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('购买价格', item.formattedPrice),
                                _buildInfoRow(
                                  '购买日期',
                                  item.formattedPurchaseDate,
                                ),
                                _buildInfoRow('使用天数', '${item.daysUsed} 天'),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                        ),
                      );
                    },
                  ),
          ),
        ],
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

  void _showUsageGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text('使用说明'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideSection('📝 添加物品', '点击右下角的添加按钮，输入物品名称、购买价格和购买日期。'),
              const SizedBox(height: 16),
              _buildGuideSection('💰 价值计算', '系统会自动计算每个物品的平均每日成本，让你了解物品的使用价值。'),
              const SizedBox(height: 16),
              _buildGuideSection('📊 统计信息', '顶部显示总价值和平均每日开销，帮助你掌握整体消费情况。'),
              const SizedBox(height: 16),
              _buildGuideSection('✏️ 编辑与删除', '点击卡片上的编辑图标修改物品，点击删除图标移除物品。'),
              const SizedBox(height: 16),
              _buildGuideSection('📤 导入导出', '支持从文件导入物品数据，也可以将数据导出备份。'),
              const SizedBox(height: 16),
              _buildGuideSection('🗑️ 批量删除', '点击右上角的批量删除图标，选择多个物品一次性删除。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总价值',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥${totalValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 50, color: Colors.grey[300]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '平均每日开销',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥${averageDailyCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
