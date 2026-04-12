import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? item;

  const ItemFormDialog({super.key, this.item});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class ItemFormScreen extends StatefulWidget {
  final Item? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toString();
      _selectedDate = widget.item!.purchaseDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final item = Item(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        price: double.parse(_priceController.text),
        purchaseDate: _selectedDate,
      );
      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepSlateBlue = Color(0xFF2A3F55);
    const warmGold = Color(0xFFCFAF68);
    const white = Color(0xFFFFFFFF);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        constraints: BoxConstraints(
          minWidth: 320,
          maxWidth: 600,
          maxHeight: 480,
        ),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.item == null ? '添加物品' : '编辑物品',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: deepSlateBlue,
                    ),
                  ),
                  Tooltip(
                    message: '取消',
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: deepSlateBlue,
                        ),
                        child: Center(
                          child: Icon(Icons.close, size: 16, color: warmGold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Item Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 17,
                              color: deepSlateBlue,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入商品名称';
                              }
                              return null;
                            },
                          ),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: deepSlateBlue,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '商品名称',
                            style: TextStyle(
                              fontSize: 13,
                              color: deepSlateBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '例如：Apple Watch',
                            style: TextStyle(fontSize: 11, color: warmGold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Price Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '¥',
                                style: TextStyle(fontSize: 17, color: warmGold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: deepSlateBlue,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入购买价格';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return '请输入有效的数字';
                                    }
                                    if (double.parse(value) <= 0) {
                                      return '价格必须大于0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: deepSlateBlue,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '购买价格',
                            style: TextStyle(
                              fontSize: 13,
                              color: deepSlateBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '例如：2499.00',
                            style: TextStyle(fontSize: 11, color: warmGold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Date Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 17,
                                  color: deepSlateBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: deepSlateBlue,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 17,
                                  color: warmGold,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: deepSlateBlue,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '购买日期',
                            style: TextStyle(
                              fontSize: 13,
                              color: deepSlateBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'yyyy-mm-dd',
                            style: TextStyle(fontSize: 11, color: warmGold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Add Button
                  Tooltip(
                    message: '确定',
                    child: InkWell(
                      onTap: _submit,
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: deepSlateBlue,
                          boxShadow: [
                            BoxShadow(
                              color: warmGold.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.add, size: 24, color: warmGold),
                        ),
                      ),
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
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toString();
      _selectedDate = widget.item!.purchaseDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final item = Item(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        price: double.parse(_priceController.text),
        purchaseDate: _selectedDate,
      );
      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepSlateBlue = Color(0xFF2A3F55);
    const warmGold = Color(0xFFCFAF68);
    const white = Color(0xFFFFFFFF);
    const offWhite = Color(0xFFF7F8F7);

    return Scaffold(
      backgroundColor: offWhite,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            minWidth: 400,
            maxWidth: 600,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.item == null ? '添加物品' : '编辑物品',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: deepSlateBlue,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: deepSlateBlue, width: 1.5),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: deepSlateBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Item Name Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                color: deepSlateBlue,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入商品名称';
                                }
                                return null;
                              },
                            ),
                            Container(
                              height: 1,
                              width: double.infinity,
                              color: deepSlateBlue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '商品名称',
                              style: TextStyle(
                                fontSize: 14,
                                color: deepSlateBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '例如：Apple Watch',
                              style: TextStyle(fontSize: 12, color: warmGold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Price Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '¥',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: warmGold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: deepSlateBlue,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return '请输入购买价格';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return '请输入有效的数字';
                                      }
                                      if (double.parse(value) <= 0) {
                                        return '价格必须大于0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 1,
                              width: double.infinity,
                              color: deepSlateBlue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '购买价格',
                              style: TextStyle(
                                fontSize: 14,
                                color: deepSlateBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '例如：2499.00',
                              style: TextStyle(fontSize: 12, color: warmGold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Date Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: deepSlateBlue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: deepSlateBlue,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: warmGold,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 1,
                              width: double.infinity,
                              color: deepSlateBlue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '购买日期',
                              style: TextStyle(
                                fontSize: 14,
                                color: deepSlateBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'yyyy-mm-dd',
                              style: TextStyle(fontSize: 12, color: warmGold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel Button
                    Tooltip(
                      message: '取消',
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: deepSlateBlue,
                          ),
                          child: Center(
                            child: Icon(Icons.close, size: 20, color: warmGold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Add Button
                    Tooltip(
                      message: '确定',
                      child: InkWell(
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: deepSlateBlue,
                            boxShadow: [
                              BoxShadow(
                                color: warmGold.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(Icons.add, size: 32, color: warmGold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
