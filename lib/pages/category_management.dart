import 'package:flutter/material.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        children: [
          // 分类列表
          ListTile(
            title: const Text('未分类'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('社交'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('办公'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('金融'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('其他'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
