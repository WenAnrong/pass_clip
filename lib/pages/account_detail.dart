import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/services/storage_service.dart';
import 'package:pass_clip/pages/add_account.dart';
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
  bool _isLoading = true;
  bool _showPassword = false;

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
    super.dispose();
  }

  // 处理刷新通知
  void _onRefresh() {
    if (mounted) {
      _loadAccount();
    }
  }

  // 加载账号数据
  Future<void> _loadAccount() async {
    // 初始化加载状态
    setState(() {
      _isLoading = true;
      _account = null;
    });

    try {
      // 优先取构造函数传参，再取路由参数（修复参数获取逻辑）
      String? accountId = widget.accountId;
      // 此时ModalRoute.of(context)已能正常获取路由参数
      if (accountId == null) {
        final routeArgs = ModalRoute.of(context)?.settings.arguments;
        accountId = routeArgs is String ? routeArgs : routeArgs?.toString();
      }

      // 校验账号ID是否为空
      if (accountId == null || accountId.isEmpty) {
        throw Exception('未提供账号ID'); // 主动抛异常，统一处理
      }

      // 加载账号并查找匹配项（添加orElse避免StateError）
      final accounts = await _storageService.getAccounts();
      _account = accounts.firstWhere(
        (account) => account.id == accountId,
        orElse: () => throw Exception('未找到该账号信息'), // 无匹配项时主动抛异常
      );
    } catch (e) {
      // 先检查页面是否存活，避免无效操作
      if (!mounted) return;

      final navigator = Navigator.of(context);

      // 统一处理错误信息，显示提示（此时mounted=true，安全）
      final errorMsg = e.toString().contains('未找到') ? '未找到该账号信息' : '未提供账号ID';
      Fluttertoast.showToast(msg: errorMsg);

      // 延迟退出，使用缓存的navigator + mounted检查（消除跨异步警告）
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          navigator.pop();
        }
      });
    } finally {
      // 无论成功/失败，都更新加载状态（此时mounted=true）
      setState(() {
        _isLoading = false;
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

  // 构建自定义字段列表，为每个字段添加分隔线
  List<Widget> _buildCustomFieldsList() {
    final List<Widget> fieldsList = [];
    final entries = _account!.customFields.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];

      // 除了第一个字段，其他字段前都添加分隔线
      if (i > 0) {
        fieldsList.add(const Divider());
      }

      fieldsList.add(
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
      );
    }

    return fieldsList;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号详情'),
        actions: [
          IconButton(
            onPressed: () {
              // 跳转到编辑页，传递完整的账号对象
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAccountPage(account: _account!),
                ),
              );
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
              _account!.platform,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            // 分类标签
            Chip(
              label: Text(_account!.category),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24.0),
            // 账号信息
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('账号'),
                    subtitle: Text(_account!.username),
                    trailing: IconButton(
                      onPressed: () async {
                        await _copyToClipboard(_account!.username, '账号已复制');
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('密码'),
                    subtitle: Text(
                      _showPassword ? _account!.password : '••••••••',
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
                            await _copyToClipboard(_account!.password, '密码已复制');
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  if (_account!.url != null && _account!.url!.isNotEmpty)
                    const Divider(),
                  if (_account!.url != null && _account!.url!.isNotEmpty)
                    ListTile(
                      title: const Text('网址'),
                      subtitle: Text(_account!.url!),
                      trailing: IconButton(
                        onPressed: () async {
                          await _copyToClipboard(_account!.url!, '网址已复制');
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  if (_account!.remark != null && _account!.remark!.isNotEmpty)
                    const Divider(),
                  if (_account!.remark != null && _account!.remark!.isNotEmpty)
                    ListTile(
                      title: const Text('备注'),
                      subtitle: Text(_account!.remark!),
                      trailing: IconButton(
                        onPressed: () async {
                          await _copyToClipboard(_account!.remark!, '备注已复制');
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  // 自定义字段
                  if (_account!.customFields.isNotEmpty) const Divider(),
                  ..._buildCustomFieldsList(),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            // 最后修改时间
            Text('最后修改时间：${_account!.updatedAt.toString().substring(0, 10)}'),
          ],
        ),
      ),
    );
  }
}
