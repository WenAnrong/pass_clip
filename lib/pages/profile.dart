import 'package:flutter/material.dart';
import 'package:pass_clip/routers/index.dart';

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
          // 分类管理
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('分类管理'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/categoryManagement');
              },
            ),
          ),
          // 关于我们
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ListTile(
              title: const Text('关于我们'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 关于我们页面
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('关于我们'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('版本号：1.0.0'),
                          SizedBox(height: 8.0),
                          Text('开发信息：本地账号密码管理工具'),
                          SizedBox(height: 8.0),
                          Text('隐私政策：本APP所有数据仅存储在本地设备，无任何网络传输，保障数据安全。'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    );
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
