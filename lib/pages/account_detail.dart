import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/services/storage_service.dart';
import 'package:pass_clip/utils/refresh_notifier.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AccountDetailPage extends StatefulWidget {
  final String? accountId;

  const AccountDetailPage({super.key, this.accountId});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  final StorageService _storageService = StorageService();
  Account? _account;
  bool _showPassword = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 监听刷新通知
    RefreshNotifier.instance.addListener(_onRefresh);
    // 延迟获取路由参数（等Widget挂载完成）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccount();
    });
  }

  @override
  void dispose() {
    // 移除刷新通知监听
    RefreshNotifier.instance.removeListener(_onRefresh);
    // 取消刷新定时器，避免内存泄漏
    _refreshTimer?.cancel();
    super.dispose();
  }

  // 处理刷新通知（添加防抖机制）
  void _onRefresh() {
    if (!mounted) return;

    // 取消之前的定时器
    _refreshTimer?.cancel();

    // 创建新的定时器，延迟500毫秒后执行加载操作
    _refreshTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadAccount();
      }
    });
  }

  // 加载账号数据
  Future<void> _loadAccount() async {
    Account? loadedAccount;

    try {
      // 优先取构造函数传参，再取路由参数
      String? accountId = widget.accountId;
      // 此时ModalRoute.of(context)已能正常获取路由参数
      if (accountId == null) {
        final routeArgs = ModalRoute.of(context)?.settings.arguments;
        accountId = routeArgs is String ? routeArgs : routeArgs?.toString();
      }

      // 校验账号ID是否为空
      if (accountId == null || accountId.isEmpty) {
        throw Exception('未提供账号ID');
      }

      // 使用新添加的getAccountById方法获取单个账号
      final account = await _storageService.getAccountById(accountId);
      if (account == null) {
        throw Exception('未找到该账号信息');
      }
      loadedAccount = account;
    } catch (e) {
      // 先检查页面是否存活，避免无效操作
      if (!mounted) return;

      final navigator = Navigator.of(context);

      // 统一处理错误信息，显示提示
      final errorMsg = e.toString().contains('未找到') ? '未找到该账号信息' : '未提供账号ID';
      Fluttertoast.showToast(msg: errorMsg);

      // 延迟退出，使用缓存的navigator + mounted检查
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          navigator.pop();
        }
      });
      return;
    }

    // 只在获取到有效账号后更新UI，减少不必要的状态更新
    if (mounted) {
      setState(() {
        _account = loadedAccount;
      });
    }
  }

  // 复制文本到剪贴板
  Future<void> _copyToClipboard(String text, String successMessage) async {
    // 先检查页面是否存活，避免无效操作
    if (!mounted) return;

    try {
      await Clipboard.setData(ClipboardData(text: text));

      Fluttertoast.showToast(msg: successMessage);
    } catch (e) {
      Fluttertoast.showToast(msg: '复制失败，请重试');
    }
  }

  // 格式化日期为YYYY-MM-DD格式
  String _formatDate(DateTime date) {
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
  }

  // 将数字格式化为两位数
  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  // 构建自定义字段列表，为每个字段添加分隔线
  List<Widget> _buildCustomFieldsList(Account account) {
    final entries = account.customFields.entries.toList();
    if (entries.isEmpty) return [];

    final List<Widget> fieldsList = [];

    // 添加第一个字段（不添加分隔线）
    final firstEntry = entries.first;
    fieldsList.add(
      ListTile(
        title: Text(firstEntry.key),
        subtitle: Text(firstEntry.value),
        trailing: IconButton(
          onPressed: () async {
            await _copyToClipboard(firstEntry.value, '${firstEntry.key}已复制');
          },
          icon: const Icon(Icons.copy),
        ),
      ),
    );

    // 添加剩余字段（每个字段前都添加分隔线）
    for (int i = 1; i < entries.length; i++) {
      final entry = entries[i];
      fieldsList.addAll([
        const Divider(),
        ListTile(
          title: Text(entry.key),
          subtitle: Text(entry.value),
          trailing: IconButton(
            onPressed: () async {
              await _copyToClipboard(entry.value, '${entry.key}已复制');
            },
            icon: const Icon(Icons.copy),
          ),
        ),
      ]);
    }

    return fieldsList;
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    if (account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 提取可能为null的字段，避免重复的null检查
    final url = account.url;
    final remark = account.remark;
    final hasUrl = url != null && url.isNotEmpty;
    final hasRemark = remark != null && remark.isNotEmpty;
    final hasCustomFields = account.customFields.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号详情'),
        actions: [
          IconButton(
            onPressed: () {
              // 跳转到编辑页，传递完整的账号对象
              Navigator.pushNamed(context, '/addAccount', arguments: account);
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 平台名称
            Text(
              account.platform,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            // 分类标签
            Chip(
              label: Text(account.category),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24.0),
            // 账号信息
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('账号'),
                    subtitle: Text(account.username),
                    trailing: IconButton(
                      onPressed: () async {
                        await _copyToClipboard(account.username, '账号已复制');
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('密码'),
                    subtitle: Text(
                      _showPassword ? account.password : '••••••••',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _copyToClipboard(account.password, '密码已复制');
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  // 网址
                  if (hasUrl) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('网址'),
                      subtitle: Text(url),
                      trailing: IconButton(
                        onPressed: () async {
                          await _copyToClipboard(url, '网址已复制');
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  ],
                  // 备注
                  if (hasRemark) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('备注'),
                      subtitle: Text(remark),
                      trailing: IconButton(
                        onPressed: () async {
                          await _copyToClipboard(remark, '备注已复制');
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  ],
                  // 自定义字段
                  if (hasCustomFields) ...[
                    const Divider(),
                    ..._buildCustomFieldsList(account),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            // 最后修改时间
            Text('最后修改时间：${_formatDate(account.updatedAt)}'),
          ],
        ),
      ),
    );
  }
}
