import 'package:flutter/material.dart';
import 'package:pass_clip/models/category.dart';
import 'package:pass_clip/services/storage_service.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final StorageService _storageService = StorageService();
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isAdding = false;
  bool _isEditing = false;
  String _editingCategory = '';

  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // 加载分类数据
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    _categories = await _storageService.getCategories();

    setState(() {
      _isLoading = false;
    });
  }

  // 新增分类
  Future<void> _addCategory() async {
    if (_formKey.currentState!.validate()) {
      final categoryName = _categoryController.text.trim();

      // 检查分类是否已存在
      if (_categories.any((category) => category.name == categoryName)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分类已存在')));
        return;
      }

      final newCategory = Category(name: categoryName);
      await _storageService.saveCategory(newCategory);

      _categoryController.clear();
      await _loadCategories();

      setState(() {
        _isAdding = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分类创建成功')));
    }
  }

  // 编辑分类
  void _startEditCategory(String categoryName) {
    _editingCategory = categoryName;
    _categoryController.text = categoryName;
    setState(() {
      _isEditing = true;
      _isAdding = false;
    });
  }

  // 保存编辑
  Future<void> _saveEditCategory() async {
    if (_formKey.currentState!.validate()) {
      final newCategoryName = _categoryController.text.trim();

      // 检查分类是否已存在
      if (_categories.any(
        (category) =>
            category.name == newCategoryName &&
            category.name != _editingCategory,
      )) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分类已存在')));
        return;
      }

      // 更新分类名称
      final accounts = await _storageService.getAccounts();
      for (var account in accounts) {
        if (account.category == _editingCategory) {
          account.category = newCategoryName;
          account.updatedAt = DateTime.now();
          await _storageService.saveAccount(account);
        }
      }

      // 更新分类列表
      final categoryIndex = _categories.indexWhere(
        (c) => c.name == _editingCategory,
      );
      if (categoryIndex != -1) {
        _categories[categoryIndex].name = newCategoryName;
        await _storageService.saveCategories(_categories);
      }

      _categoryController.clear();
      await _loadCategories();

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分类更新成功')));
    }
  }

  // 删除分类
  void _showDeleteConfirm(String categoryName) {
    if (categoryName == '未分类') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('默认分类不可删除')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('该分类下的账号将移至未分类，是否确认删除？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await _storageService.deleteCategory(categoryName);
                await _loadCategories();
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('分类删除成功')));
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分类管理')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 新增/编辑分类表单
                if (_isAdding || _isEditing)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _categoryController,
                              decoration: InputDecoration(
                                labelText: _isEditing ? '编辑分类' : '新增分类',
                                hintText: '请输入分类名称',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入分类名称';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          ElevatedButton(
                            onPressed: _isEditing
                                ? _saveEditCategory
                                : _addCategory,
                            child: Text(_isEditing ? '保存' : '新增'),
                          ),
                          const SizedBox(width: 8.0),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isAdding = false;
                                _isEditing = false;
                                _categoryController.clear();
                                _editingCategory = '';
                              });
                            },
                            child: const Text('取消'),
                          ),
                        ],
                      ),
                    ),
                  ),
                // 分类列表
                Expanded(
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return ListTile(
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (category.name != '未分类')
                              IconButton(
                                onPressed: () {
                                  _startEditCategory(category.name);
                                },
                                icon: const Icon(Icons.edit),
                              ),
                            IconButton(
                              onPressed: () {
                                _showDeleteConfirm(category.name);
                              },
                              icon: const Icon(Icons.delete),
                              color: category.name != '未分类'
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _isAdding || _isEditing
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isAdding = true;
                  _isEditing = false;
                  _categoryController.clear();
                  _editingCategory = '';
                });
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
