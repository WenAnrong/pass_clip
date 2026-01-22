import 'package:flutter/material.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/models/category.dart';
import 'package:pass_clip/services/storage_service.dart';
import 'dart:math';
import 'package:pass_clip/utils/refresh_notifier.dart';
import 'package:pass_clip/utils/snackbar_util.dart';

class AccountManagementPage extends StatefulWidget {
  final Account? account;

  const AccountManagementPage({super.key, this.account});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  final StorageService _storageService = StorageService();
  List<Category> _categories = [];
  bool _isObscure = true;

  // 表单控制器
  final _formKey = GlobalKey<FormState>();
  final _platformController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remarkController = TextEditingController();
  final _urlController = TextEditingController();

  // 自定义字段控制器
  final _customFieldNameController = TextEditingController();
  final _customFieldValueController = TextEditingController();

  // 自定义字段列表
  List<Map<String, String>> _customFields = [];

  // 分类选择
  String _selectedCategory = '未分类';

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.account != null) {
      _platformController.text = widget.account!.platform;
      _usernameController.text = widget.account!.username;
      _passwordController.text = widget.account!.password;
      _selectedCategory = widget.account!.category;
      _remarkController.text = widget.account!.remark ?? '';
      _urlController.text = widget.account!.url ?? '';

      _customFields = widget.account!.customFields.entries
          .map((entry) => {'name': entry.key, 'value': entry.value})
          .toList();
    }
  }

  Future<void> _loadCategories() async {
    _categories = await _storageService.getCategories();
    _categories.add(Category(name: '添加新分类', count: 0));
    setState(() {});
  }

  void _generatePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()';
    final random = Random();
    final password = String.fromCharCodes(
      Iterable.generate(
        12,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    _passwordController.text = password;
  }

  void _addCustomField() {
    if (_customFieldNameController.text.isNotEmpty) {
      setState(() {
        _customFields.add({
          'name': _customFieldNameController.text,
          'value': _customFieldValueController.text,
        });
        _customFieldNameController.clear();
        _customFieldValueController.clear();
      });
    }
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
    });
  }

  void _onCategoryChanged(String? value) {
    if (value == null) return;

    if (value == '添加新分类') {
      _showAddCategoryDialog();
    } else {
      setState(() {
        _selectedCategory = value;
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final TextEditingController categoryNameController =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加新分类'),
        content: TextField(
          controller: categoryNameController,
          decoration: const InputDecoration(
            labelText: '分类名称',
            hintText: '请输入新分类名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCategoryName = categoryNameController.text.trim();

              if (newCategoryName.isEmpty) {
                SnackBarUtil.show(dialogContext, '分类名称不能为空');
                return;
              }

              final categoryExists = _categories.any(
                (category) => category.name == newCategoryName,
              );

              if (categoryExists) {
                SnackBarUtil.show(dialogContext, '分类已存在');
                return;
              }

              final navigator = Navigator.of(dialogContext);
              await _saveNewCategory(newCategoryName);
              navigator.pop();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewCategory(String newCategoryName) async {
    try {
      final newCategory = Category(name: newCategoryName, count: 0);
      await _storageService.saveCategory(newCategory);

      setState(() {
        _categories.removeLast();
        _categories.add(newCategory);
        _categories.add(Category(name: '添加新分类', count: 0));
        _selectedCategory = newCategoryName;
      });
      RefreshNotifier.instance.notifyRefresh();
    } catch (e) {
      if (mounted) {
        SnackBarUtil.show(context, '分类添加失败：$e');
      }
    }
  }

  Future<void> _saveAccount() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);

    if (_formKey.currentState!.validate()) {
      Map<String, String> customFieldsMap = {};
      for (var field in _customFields) {
        customFieldsMap[field['name']!] = field['value']!;
      }

      final account = Account(
        id:
            widget.account?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        platform: _platformController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        category: _selectedCategory,
        remark: _remarkController.text.isNotEmpty
            ? _remarkController.text
            : null,
        url: _urlController.text.isNotEmpty ? _urlController.text : null,
        customFields: customFieldsMap,
        createdAt: widget.account?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storageService.saveAccount(account);
      await _storageService.updateCategoryCount(_selectedCategory);

      navigator.pop();
      RefreshNotifier.instance.notifyRefresh();
      if (mounted) {
        SnackBarUtil.show(context, widget.account != null ? '更新成功' : '保存成功');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account != null ? '编辑账号密码' : '新增账号密码')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _platformController,
                  decoration: InputDecoration(
                    labelText: '平台名称',
                    hintText: '请输入平台名称',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入平台名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '账号',
                    hintText: '请输入账号',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入账号';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '请输入密码',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _passwordController.clear();
                            });
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _generatePassword,
                    child: const Text('生成密码'),
                  ),
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '分类'),
                  initialValue: _selectedCategory,
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.name,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: _onCategoryChanged,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _remarkController,
                  decoration: InputDecoration(
                    labelText: '备注',
                    hintText: '可选：备注账号信息',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: '网址',
                    hintText: '可选：输入平台官网地址',
                  ),
                ),
                const SizedBox(height: 24.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '自定义字段',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    if (_customFields.isNotEmpty)
                      Column(
                        children: List.generate(
                          _customFields.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _customFields[index]['name']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(_customFields[index]['value']!),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeCustomField(index),
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customFieldNameController,
                            decoration: const InputDecoration(
                              labelText: '字段名',
                              hintText: '字段名',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextFormField(
                            controller: _customFieldValueController,
                            decoration: const InputDecoration(
                              labelText: '值',
                              hintText: '输入字段值',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: _addCustomField,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                          ),
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAccount,
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
