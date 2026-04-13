import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  bool _showFloatingMenu = false;
  Set<String> _selectedItemIds = {};

  static const primaryColor = Color(0xFF2A3F55);
  static const warmGold = Color(0xFFCFAF68);
  static const cardColor = Color(0xFFFFFFFF);

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
    setState(() {
      _showFloatingMenu = false;
    });
    final result = await showDialog<Item>(
      context: context,
      builder: (context) => ItemFormDialog(item: item),
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
    setState(() {
      _showFloatingMenu = false;
    });
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true, // Web平台需要这个
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      String content;
      try {
        if (kIsWeb) {
          // Web平台：使用bytes
          if (result.files.single.bytes == null) {
            throw Exception('文件内容为空');
          }
          content = utf8.decode(result.files.single.bytes!);
        } else {
          // 其他平台：使用path
          if (result.files.single.path == null) {
            throw Exception('文件路径为空');
          }
          final file = File(result.files.single.path!);
          if (!await file.exists()) {
            throw Exception('文件不存在');
          }
          content = await file.readAsString();
        }
      } catch (fileError) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('文件读取失败: $fileError')),
          );
        }
        return;
      }

      final lines = content.split('\n');
      int importedCount = 0;
      int failedCount = 0;

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        try {
          final parts = line.split('|').map((p) => p.trim()).toList();
          if (parts.length < 3) {
            failedCount++;
            continue;
          }

          final name = parts[0];
          final priceStr = parts[1];
          final dateStr = parts[2];

          final price = double.tryParse(priceStr);
          final date = DateTime.tryParse(dateStr);

          if (price == null || date == null) {
            failedCount++;
            continue;
          }

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
        } catch (parseError) {
          failedCount++;
          debugPrint('解析行失败: $line, 错误: $parseError');
        }
      }

      await _loadItems();
      if (mounted) {
        if (importedCount > 0) {
          String message = '成功导入 $importedCount 个物品';
          if (failedCount > 0) {
            message += ', 失败 $failedCount 个物品';
          }
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('没有成功导入任何物品，请检查文件格式')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('导入失败: ${e.toString()}')),
        );
      }
      debugPrint('导入文件时发生错误: $e');
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
      try {
        for (final item in items) {
          content +=
              '${item.name}|${item.price}|${item.purchaseDate.toIso8601String()}\n';
        }
      } catch (formatError) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('数据格式化失败: $formatError')),
          );
        }
        debugPrint('数据格式化错误: $formatError');
        return;
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: 'items_${DateTime.now().millisecondsSinceEpoch}.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: utf8.encode(content), // Web平台使用bytes
      );

      if (result == null) {
        // 用户取消了保存操作
        return;
      }

      // 根据平台保存文件
      if (!kIsWeb) {
        try {
          final file = File(result);
          // 确保目录存在
          final directory = file.parent;
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          await file.writeAsString(content);
        } catch (fileError) {
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('文件保存失败: $fileError')),
            );
          }
          debugPrint('文件保存错误: $fileError');
          return;
        }
      }

      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('导出成功')));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('导出失败: ${e.toString()}')),
        );
      }
      debugPrint('导出文件时发生错误: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: _isSelectionMode
              ? AppBar(
                  title: Text(
                    '已选择 ${_selectedItemIds.length} 个',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),

                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close),
                    ),
                    onPressed: _exitSelectionMode,
                    tooltip: '退出选择模式',
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _selectAll,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: primaryColor,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          _selectedItemIds.length == _items.length
                              ? Icons.deselect
                              : Icons.select_all,
                          size: 20,
                        ),
                        label: Text(
                          _selectedItemIds.length == _items.length
                              ? '取消全选'
                              : '全选',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _selectedItemIds.isNotEmpty
                            ? _batchDelete
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _selectedItemIds.isNotEmpty
                              ? Colors.red
                              : Colors.grey[400],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text(
                          '删除',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Image.asset(
                          'res/icon.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showUsageGuide,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Tooltip(
                              message: '使用说明',
                              child: Text(
                                '长物 / PERUSE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  leadingWidth: 200,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: _enterSelectionMode,
                      tooltip: '批量删除',
                      color: primaryColor,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _exportToFile,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: primaryColor,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: const Text(
                          '导出',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                            Icon(
                              Icons.inbox,
                              size: 80,
                              color: Colors.grey[400],
                            ),
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
                          return _buildItemCard(item, isSelected);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showFloatingMenu = true;
              });
            },
            child: const Icon(Icons.add),
          ),
        ),
        if (_showFloatingMenu)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: _buildFloatingMenu(),
          ),
      ],
    );
  }

  Widget _buildFloatingMenu() {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxButtonWidth = screenWidth * 0.35;
    final buttonSize = min(180.0, maxButtonWidth);
    final spacing = screenWidth < 500 ? 24.0 : 48.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showFloatingMenu = false;
        });
      },
      child: Container(
        color: Colors.black.withAlpha(89),

        child: Center(
          child: GestureDetector(
            onTap: () {
              // 阻止事件冒泡
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  minWidth: 320,
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),

                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '选择操作',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CHOOSE OPERATION',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            flex: 1,
                            child: _buildMenuButton(
                              'res/new_item_button.png',
                              '添加物品',
                              'ADD ITEM',
                              _navigateToForm,
                              buttonSize,
                            ),
                          ),
                          SizedBox(width: spacing),
                          Flexible(
                            flex: 1,
                            child: _buildMenuButton(
                              'res/import_from_file_button.png',
                              '从文件导入',
                              'IMPORT FILE',
                              _importFromFile,
                              buttonSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    String imagePath,
    String title,
    String subtitle,
    VoidCallback onTap,
    double buttonSize,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualSize = min(buttonSize, constraints.maxWidth - 10);
        final iconSize = actualSize * 0.3;
        final titleFontSize = actualSize * 0.08;
        final subtitleFontSize = actualSize * 0.06;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            width: actualSize,
            height: actualSize,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: warmGold.withAlpha(128), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.add_circle_outline,
                      size: iconSize,
                      color: primaryColor,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(Item item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isSelected ? Border.all(color: primaryColor, width: 2) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isSelectionMode ? () => _toggleItemSelection(item.id) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSelectionMode)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Checkbox(
                        value: isSelected,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (value) {
                          _toggleItemSelection(item.id);
                        },
                        activeColor: primaryColor,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  if (!_isSelectionMode)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 20, color: primaryColor),
                          onPressed: () => _navigateToForm(item),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteItem(item.id),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('购买价格:', item.formattedPrice),
              _buildInfoRow('购买日期:', item.formattedPurchaseDate),
              _buildInfoRow('使用天数:', '${item.daysUsed} 天'),
            ],
          ),
        ),
      ),
    );
  }

  void _showUsageGuide() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: primaryColor),
                        const SizedBox(width: 12),
                        const Text(
                          '使用说明',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGuideSection(
                            '本软件是免费，并且将所有的数据和使用记录都保存在本地',
                            '本应用用于记录长期消费，帮助你了解物品的使用价值和消费趋势。点击右下角的添加按钮，输入物品名称、购买价格和购买日期。系统会自动计算每个物品的平均每日成本，让你了解物品的使用价值。顶部显示总价值和平均每日开销，帮助你掌握整体消费情况。',
                          ),
                          const SizedBox(height: 16),
                          _buildGuideSection(
                            '📝 添加物品',
                            '点击右下角的添加按钮，输入物品名称、购买价格和购买日期。',
                          ),
                          const SizedBox(height: 16),
                          _buildGuideSection(
                            '💰 价值计算',
                            '系统会自动计算每个物品的平均每日成本，让你了解物品的使用价值。',
                          ),
                          const SizedBox(height: 16),
                          _buildGuideSection(
                            '📊 统计信息',
                            '顶部显示总价值和平均每日开销，帮助你掌握整体消费情况。',
                          ),
                          const SizedBox(height: 16),
                          _buildGuideSection(
                            '✏️ 编辑与删除',
                            '点击卡片上的编辑图标修改物品，点击删除图标移除物品。',
                          ),
                          const SizedBox(height: 16),
                          _buildGuideSection(
                            '📤 导入导出',
                            '支持从文件导入物品数据，也可以将数据导出备份。',
                          ),
                          const SizedBox(height: 16),
                          _buildGuideSection(
                            '🗑️ 批量删除',
                            '点击右上角的批量删除图标，选择多个物品一次性删除。',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                        ),
                        child: const Text('关闭'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 20, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          '总价值',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${totalValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: warmGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down,
                          size: 20,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '平均每日开销',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 20, color: warmGold),
                        const SizedBox(width: 6),
                        Text(
                          '¥${averageDailyCost.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: warmGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: warmGold,
            ),
          ),
        ],
      ),
    );
  }
}
