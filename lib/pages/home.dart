import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pass_clip/components/account_list_item.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/models/category.dart';
import 'package:pass_clip/services/storage_service.dart';
import 'package:pass_clip/utils/refresh_notifier.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  // 缓存筛选和排序后的账号列表
  List<Account> _filteredAndSortedAccounts = [];

  // 搜索防抖计时器
  Timer? _searchTimer;

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

    // 取消搜索计时器
    _searchTimer?.cancel();

    super.dispose();
  }

  // 加载数据
  Future<void> _loadData() async {
    _accounts = await _storageService.getAccounts();

    // 批量更新分类计数
    final categoryNames = _categories.map((c) => c.name).toList();
    for (final name in categoryNames) {
      await _storageService.updateCategoryCount(name);
    }

    _categories = await _storageService.getCategories();

    // 重新筛选和排序账号
    _updateFilteredAndSortedAccounts();
  }

  // 更新筛选和排序后的账号列表
  void _updateFilteredAndSortedAccounts() {
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

    setState(() {
      _filteredAndSortedAccounts = filtered;
    });
  }

  // 处理搜索文本变化（防抖）
  void _onSearchTextChanged(String text) {
    setState(() {
      _searchText = text;
    });

    // 取消之前的计时器
    _searchTimer?.cancel();

    // 延迟50毫秒后更新筛选结果
    _searchTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        _updateFilteredAndSortedAccounts();
      }
    });
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
                  _sortOption = '按时间最新';
                  _updateFilteredAndSortedAccounts();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按名称升序'),
                trailing: _sortOption == '按名称升序'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  _sortOption = '按名称升序';
                  _updateFilteredAndSortedAccounts();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按名称降序'),
                trailing: _sortOption == '按名称降序'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  _sortOption = '按名称降序';
                  _updateFilteredAndSortedAccounts();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按时间最早'),
                trailing: _sortOption == '按时间最早'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  _sortOption = '按时间最早';
                  _updateFilteredAndSortedAccounts();
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
                  // 先关闭弹出菜单
                  Navigator.pop(context);
                  // 然后跳转到分类管理页面
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
                final navigator = Navigator.of(context);

                // 执行异步操作
                await _storageService.deleteAccount(account.id);
                await _loadData();

                // 检查主页是否存活
                if (!mounted) return;

                // 用缓存的对象执行操作
                navigator.pop();

                Fluttertoast.showToast(msg: '删除成功');
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
      appBar: AppBar(
        title: const Text('秘荚'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _showSortOptions, icon: const Icon(Icons.sort)),
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _onSearchTextChanged,
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
                      _selectedCategory = category;
                      _updateFilteredAndSortedAccounts();
                    },
                  ),
                );
              },
            ),
          ),
          // 账号列表
          Expanded(
            child: _filteredAndSortedAccounts.isEmpty
                ? const Center(child: Text('暂无账号信息'))
                : ListView.builder(
                    itemCount: _filteredAndSortedAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _filteredAndSortedAccounts[index];
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
