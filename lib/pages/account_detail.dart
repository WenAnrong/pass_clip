import 'package:flutter/material.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账号详情'),
        actions: [
          IconButton(
            onPressed: () {},
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
            const Text(
              '微信',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            // 分类标签
            Chip(
              label: const Text('社交'),
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
                    subtitle: const Text('138****1234'),
                    trailing: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('密码'),
                    subtitle: const Text('••••••••'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.visibility),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('网址'),
                    subtitle: const Text('https://weixin.qq.com'),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('备注'),
                    subtitle: const Text('工作账号'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            // 最后修改时间
            const Text(
              '最后修改时间：2026-01-18',
              style: TextStyle(
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
