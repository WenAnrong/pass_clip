import 'package:flutter/material.dart';
import 'package:pass_clip/models/account.dart';
import 'package:pass_clip/services/storage_service.dart';
import 'package:pass_clip/routers/index.dart';

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
    _loadAccount();
  }

  // 加载账号数据
  Future<void> _loadAccount() async {
    setState(() {
      _isLoading = true;
    });
    
    if (widget.accountId != null) {
      final accounts = await _storageService.getAccounts();
      _account = accounts.firstWhere(
        (account) => account.id == widget.accountId,
        orElse: () => Account(
          id: '1',
          platform: '微信',
          username: '138****1234',
          password: '12345678',
          category: '社交',
          remark: '工作账号',
          url: 'https://weixin.qq.com',
        ),
      );
    } else {
      // 模拟数据
      _account = Account(
        id: '1',
        platform: '微信',
        username: '138****1234',
        password: '12345678',
        category: '社交',
        remark: '工作账号',
        url: 'https://weixin.qq.com',
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  // 复制文本到剪贴板
  void _copyToClipboard(String text, String message) {
    // 这里简化处理，实际应用中需要使用clipboard库
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _account == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号详情'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/addAccount',
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
              labelStyle: const TextStyle(color: Colors.white),
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
                      onPressed: () {
                        _copyToClipboard(_account!.username, '账号已复制');
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('密码'),
                    subtitle: Text(_showPassword ? _account!.password : '••••••••'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                        ),
                        IconButton(
                          onPressed: () {
                            _copyToClipboard(_account!.password, '密码已复制');
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  if (_account!.url != null)
                    const Divider(),
                  if (_account!.url != null)
                    ListTile(
                      title: const Text('网址'),
                      subtitle: Text(_account!.url!),
                    ),
                  if (_account!.remark != null)
                    const Divider(),
                  if (_account!.remark != null)
                    ListTile(
                      title: const Text('备注'),
                      subtitle: Text(_account!.remark!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            // 最后修改时间
            Text(
              '最后修改时间：${_account!.updatedAt.toString().substring(0, 10)}',
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
