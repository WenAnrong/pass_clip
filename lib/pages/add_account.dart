import 'package:flutter/material.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/models/category.dart';
import 'package:pass_clip/services/storage_service.dart';
import 'dart:math';
import 'package:pass_clip/utils/refresh_notifier.dart';

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

  // 保存账号
  Future<void> _saveAccount() async {
    // 先检查页面是否存活，避免无效操作
    if (!mounted) return;

    // 提前缓存ScaffoldMessenger和Navigator（避免跨异步用context）
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 验证表单所有字段是否填写完整
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

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
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(widget.account != null ? '更新成功' : '保存成功')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account != null ? '编辑账号密码' : '新增账号密码')),
      body: _isLoading
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
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                            IconButton(
                              onPressed: _generatePassword,
                              icon: const Icon(Icons.refresh),
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
                      maxLines: 3,
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
    );
  }
}
