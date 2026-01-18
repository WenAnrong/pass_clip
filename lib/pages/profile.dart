import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // 修改解锁密码
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('修改解锁密码'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          // 分类管理
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('分类管理'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          // 数据导出
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('数据导出'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          // 数据导入
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('数据导入'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          // 生物识别设置
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('生物识别设置'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
          ),
          // 关于我们
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('关于我们'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          // 退出登录
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('退出登录'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          // 清除所有数据
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('清除所有数据'),
              textColor: Colors.red,
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
