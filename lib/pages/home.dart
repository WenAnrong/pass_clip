import 'package:flutter/material.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/models/category.dart';
import 'package:pass_clip/services/storage_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storageService = StorageService();
  List<Account> _accounts = [];
  List<Category> _categories = [];
  String _selectedCategory = '全部分类';
  String _searchText = '';
  String _sortOption = '按名称升序';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    _accounts = await _storageService.getAccounts();
    _categories = await _storageService.getCategories();
    
    // 更新分类计数
    for (var category in _categories) {
      await _storageService.updateCategoryCount(category.name);
    }
    _categories = await _storageService.getCategories();
    
    setState(() {
      _isLoading = false;
    });
  }

  // 搜索和筛选账号
  List<Account> _getFilteredAccounts() {
    List<Account> filtered = _accounts;
    
    // 按分类筛选
    if (_selectedCategory != '全部分类') {
      filtered = filtered.where((account) => account.category == _selectedCategory).toList();
    }
    
    // 按搜索文本筛选
    if (_searchText.isNotEmpty) {
      final searchLower = _searchText.toLowerCase();
      filtered = filtered.where((account) => 
        account.platform.toLowerCase().contains(searchLower) ||
        account.username.toLowerCase().contains(searchLower) ||
        account.category.toLowerCase().contains(searchLower)
      ).toList();
    }
    
    // 排序
    switch (_sortOption) {
      case '按名称升序':
        filtered.sort((a, b) => a.platform.compareTo(b.platform));
        break;
      case '按名称降序':
        filtered.sort((a, b) => b.platform.compareTo(a.platform));
        break;
      case '按时间最新':
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case '按时间最早':
        filtered.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
    }
    
    return filtered;
  }

  // 显示排序选项
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('按名称升序'),
                trailing: _sortOption == '按名称升序' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _sortOption = '按名称升序';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按名称降序'),
                trailing: _sortOption == '按名称降序' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _sortOption = '按名称降序';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按时间最新'),
                trailing: _sortOption == '按时间最新' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _sortOption = '按时间最新';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按时间最早'),
                trailing: _sortOption == '按时间最早' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _sortOption = '按时间最早';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示更多选项
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('分类管理'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/categoryManagement');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示删除确认
  void _showDeleteConfirm(Account account) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确认删除${account.platform}的账号信息？删除后不可恢复。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await _storageService.deleteAccount(account.id);
                await _loadData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('删除成功')),
                );
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 格式化账号（隐藏中间字符）
  String _formatUsername(String username) {
    if (username.isEmpty) return '';
    if (username.length <= 4) return username;
    if (username.contains('@')) {
      // 邮箱格式
      final parts = username.split('@');
      if (parts[0].length > 3) {
        final hidden = '*' * (parts[0].length - 3);
        return '${parts[0].substring(0, 3)}$hidden@${parts[1]}';
      }
      return username;
    } else if (username.length >= 11) {
      // 手机号格式
      return '${username.substring(0, 3)}****${username.substring(7)}';
    } else {
      // 其他格式
      final hidden = '*' * (username.length - 4);
      return '${username.substring(0, 2)}$hidden${username.substring(username.length - 2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = _getFilteredAccounts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号密码管理'),
        actions: [
          IconButton(
            onPressed: _showSortOptions,
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 搜索栏
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (text) {
                      setState(() {
                        _searchText = text;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '搜索平台、账号或分类',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                // 分类筛选栏
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      String category;
                      if (index == 0) {
                        category = '全部分类';
                      } else {
                        category = _categories[index - 1].name;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0, left: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: _selectedCategory == category ? Colors.white : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 账号列表
                Expanded(
                  child: filteredAccounts.isEmpty
                      ? const Center(child: Text('暂无账号信息'))
                      : ListView.builder(
                          itemCount: filteredAccounts.length,
                          itemBuilder: (context, index) {
                            final account = filteredAccounts[index];
                            return ListTile(
                              title: Text(account.platform),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_formatUsername(account.username)),
                                  Text(
                                    account.updatedAt.toString().substring(0, 10),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(account.category),
                                labelStyle: const TextStyle(fontSize: 10),
                              ),
                              onTap: () {
                                Navigator.pushNamed(context, '/accountDetail');
                              },
                              onLongPress: () {
                                _showDeleteConfirm(account);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
