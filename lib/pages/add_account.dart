import 'package:flutter/material.dart';

class AddAccountPage extends StatelessWidget {
  const AddAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增账号密码'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 平台名称
            TextField(
              decoration: InputDecoration(
                labelText: '平台名称',
                hintText: '请输入平台名称（如抖音、支付宝）',
              ),
            ),
            const SizedBox(height: 16.0),
            // 账号
            TextField(
              decoration: InputDecoration(
                labelText: '账号',
                hintText: '请输入账号（手机号/邮箱/用户名）',
              ),
            ),
            const SizedBox(height: 16.0),
            // 密码
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '请输入密码',
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('生成密码'),
              ),
            ),
            const SizedBox(height: 16.0),
            // 分类
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '分类',
              ),
              value: '未分类',
              items: ['未分类', '社交', '办公', '金融', '其他']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16.0),
            // 备注
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '备注',
                hintText: '可选：备注账号信息（如工作账号/常用密码）',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16.0),
            // 网址
            TextField(
              decoration: InputDecoration(
                labelText: '网址',
                hintText: '可选：输入平台官网地址',
              ),
            ),
            const SizedBox(height: 32.0),
            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
