import 'package:flutter/material.dart';
import 'package:pass_clip/components/account_list_item.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/models/category.dart';
import 'package:pass_clip/services/storage_service.dart';
import 'package:pass_clip/utils/refresh_notifier.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storageService = StorageService(); // 本地存储服务（读写账号/分类）
  late final VoidCallback _refreshCallback; // 刷新通知回调函数
  List<Account> _accounts = [];
  List<Category> _categories = [];
  String _selectedCategory = '全部分类';
  String _searchText = '';
  String _sortOption = '按时间最新';
  bool _isLoading = true; // 数据加载状态（控制加载动画）

  @override
  void initState() {
    super.initState();
    _loadData();
    // 定义刷新回调函数
    _refreshCallback = () {
      if (mounted) {
        _loadData(); // 收到通知后，重新加载数据
      }
    };
    // 监听刷新通知
    RefreshNotifier.instance.addListener(_refreshCallback);
  }

  @override
  void dispose() {
    // 取消刷新通知器订阅
    RefreshNotifier.instance.removeListener(_refreshCallback);
    super.dispose();
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
      filtered = filtered
          .where((account) => account.category == _selectedCategory)
          .toList();
    }

    // 按搜索文本筛选
    if (_searchText.isNotEmpty) {
      final searchLower = _searchText.toLowerCase();
      filtered = filtered
          .where(
            (account) =>
                account.platform.toLowerCase().contains(searchLower) ||
                account.username.toLowerCase().contains(searchLower) ||
                account.category.toLowerCase().contains(searchLower),
          )
          .toList();
    }

    // 排序
    switch (_sortOption) {
      case '按时间最新':
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case '按名称升序':
        filtered.sort((a, b) => a.platform.compareTo(b.platform));
        break;
      case '按名称降序':
        filtered.sort((a, b) => b.platform.compareTo(a.platform));
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
        // 适配刘海屏/底部导航栏，避免内容被遮挡
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('按时间最新'),
                trailing: _sortOption == '按时间最新'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() {
                    _sortOption = '按时间最新';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按名称升序'),
                trailing: _sortOption == '按名称升序'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() {
                    _sortOption = '按名称升序';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按名称降序'),
                trailing: _sortOption == '按名称降序'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() {
                    _sortOption = '按名称降序';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按时间最早'),
                trailing: _sortOption == '按时间最早'
                    ? const Icon(Icons.check)
                    : null,
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
                // 异步操作前，提前缓存需要的对象（避免跨异步用context）
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                // 执行异步操作
                await _storageService.deleteAccount(account.id);
                await _loadData();

                // 检查主页是否存活
                if (!mounted) return;

                // 用缓存的对象执行操作
                navigator.pop();
                scaffoldMessenger.showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = _getFilteredAccounts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号密码管理'),
        actions: [
          IconButton(onPressed: _showSortOptions, icon: const Icon(Icons.sort)),
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
                            color: _selectedCategory == category
                                ? Colors.white
                                : null,
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
                            return AccountListItem(
                              account: account,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/accountDetail',
                                  arguments: account.id,
                                );
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
