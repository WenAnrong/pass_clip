import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账号密码管理'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: () {},
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
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                final categories = ['全部分类', '社交', '办公', '金融', '其他'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Chip(
                    label: Text(categories[index]),
                    backgroundColor: index == 0 ? Theme.of(context).primaryColor : null,
                    labelStyle: TextStyle(
                      color: index == 0 ? Colors.white : null,
                    ),
                  ),
                );
              },
            ),
          ),
          // 账号列表
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  title: const Text('微信'),
                  subtitle: const Text('138****1234'),
                  trailing: const Chip(
                    label: Text('社交'),
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onTap: () {},
                  onLongPress: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
