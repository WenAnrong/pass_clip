import 'package:flutter/material.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/models/category.dart';
import 'package:pass_clip/services/storage_service.dart';
import 'dart:math';
import 'package:pass_clip/utils/refresh_notifier.dart';
import 'package:pass_clip/utils/snackbar_manager.dart';

class AddAccountPage extends StatefulWidget {
  final Account? account; // 编辑模式时传入的已有账号，新增时为null

  const AddAccountPage({super.key, this.account});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final StorageService _storageService = StorageService();
  List<Category> _categories = [];
  bool _isLoading = true;
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
    _loadCategories(); // 加载分类列表（初始化下拉选择框的选项）

    // 如果是编辑模式，加载现有数据
    if (widget.account != null) {
      _platformController.text = widget.account!.platform;
      _usernameController.text = widget.account!.username;
      _passwordController.text = widget.account!.password;
      _selectedCategory = widget.account!.category;
      _remarkController.text = widget.account!.remark ?? '';
      _urlController.text = widget.account!.url ?? '';

      // 加载自定义字段
      _customFields = widget.account!.customFields.entries
          .map((entry) => {'name': entry.key, 'value': entry.value})
          .toList();
    }
  }

  // 加载分类数据
  Future<void> _loadCategories() async {
    _categories = await _storageService.getCategories();
    setState(() {
      _isLoading = false;
    });
  }

  // 生成随机密码
  void _generatePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^&*()';
    final random = Random();
    // 生成12位随机密码：遍历12次，每次从字符集随机取一个字符
    final password = String.fromCharCodes(
      Iterable.generate(
        12,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    _passwordController.text = password;
  }

  // 添加自定义字段
  void _addCustomField() {
    if (_customFieldNameController.text.isNotEmpty) {
      setState(() {
        _customFields.add({
          'name': _customFieldNameController.text,
          'value': _customFieldValueController.text,
        });
        // 清空输入框
        _customFieldNameController.clear();
        _customFieldValueController.clear();
      });
    }
  }

  // 删除自定义字段
  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
    });
  }

  // 保存账号
  Future<void> _saveAccount() async {
    // 先检查页面是否存活，避免无效操作
    if (!mounted) return;
    final navigator = Navigator.of(context);

    // 验证表单所有字段是否填写完整
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // 转换自定义字段为Map
      Map<String, String> customFieldsMap = {};
      for (var field in _customFields) {
        customFieldsMap[field['name']!] = field['value']!;
      }

      // 构建账号对象
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

      setState(() {
        _isLoading = false;
      });

      // 保存成功后，发送刷新通知
      navigator.pop();
      RefreshNotifier.instance.notifyRefresh();
      if (mounted) {
        SnackBarManager().show(
          context,
          widget.account != null ? '更新成功' : '保存成功',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account != null ? '编辑账号密码' : '新增账号密码')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 平台名称
                      TextFormField(
                        controller: _platformController,
                        decoration: InputDecoration(
                          labelText: '平台名称',
                          hintText: '请输入平台名称（如抖音、支付宝）',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入平台名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // 账号
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: '账号',
                          hintText: '请输入账号（手机号/邮箱/用户名）',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入账号';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // 密码
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
                      // 分类
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
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // 备注
                      TextFormField(
                        controller: _remarkController,
                        decoration: InputDecoration(
                          labelText: '备注',
                          hintText: '可选：备注账号信息（如工作账号/常用密码）',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      // 网址
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: '网址',
                          hintText: '可选：输入平台官网地址',
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      // 自定义字段
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
                          // 已添加的自定义字段列表
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
                                            Text(
                                              _customFields[index]['value']!,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _removeCustomField(index),
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
                          // 添加自定义字段的输入框
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _customFieldNameController,
                                  decoration: const InputDecoration(
                                    labelText: '字段名',
                                    hintText: '如：邮箱、手机号',
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
                      // 保存按钮
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
