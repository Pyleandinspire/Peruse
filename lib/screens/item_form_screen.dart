import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
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
    const primaryColor = Color(0xFF2C5F8C);
    const jadeGreen = Color(0xFF4CAF50);
    const warmGold = Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? '添加物品' : '编辑物品',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('res/close_button.png', width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ListView(
                  children: [
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _nameController,
                      label: '商品名称',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入商品名称';
                        }
                        return null;
                      },
                      color: primaryColor,
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _priceController,
                      label: '购买价格',
                      prefix: '¥',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
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
                      color: primaryColor,
                    ),
                    const SizedBox(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '购买日期',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: jadeGreen,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: primaryColor,
                                    height: 1.2,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: warmGold,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(60),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor,
                          ),
                          child: Center(
                            child: Image.asset(
                              'res/add_button.png',
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: color,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: TextStyle(fontSize: 18, color: color, height: 1.2),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    onPressed: () => controller.clear(),
                    icon: Icon(
                      Icons.clear,
                      color: color.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  )
                : null,
          ),
          style: TextStyle(fontSize: 18, color: color, height: 1.2),
        ),
        Container(height: 1, width: double.infinity, color: color),
      ],
    );
  }
}
