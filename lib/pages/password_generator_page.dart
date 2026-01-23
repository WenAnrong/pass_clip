import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_clip/utils/password_generator.dart';
import 'package:pass_clip/utils/snackbar_util.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  int _passwordLength = 12;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSpecialChars = true;
  String _generatedPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('密码生成器'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 密码长度设置
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('密码长度'),
                      Text(
                        '$_passwordLength',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _passwordLength.toDouble(),
                    min: 6,
                    max: 32,
                    divisions: 26,
                    onChanged: (value) {
                      setState(() {
                        _passwordLength = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),

              // 密码选项设置
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('包含大写字母 (A-Z)'),
                    value: _includeUppercase,
                    onChanged: (value) {
                      setState(() {
                        _includeUppercase = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('包含小写字母 (a-z)'),
                    value: _includeLowercase,
                    onChanged: (value) {
                      setState(() {
                        _includeLowercase = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('包含数字 (0-9)'),
                    value: _includeNumbers,
                    onChanged: (value) {
                      setState(() {
                        _includeNumbers = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('包含特殊符号 (!@#%^&*)'),
                    value: _includeSpecialChars,
                    onChanged: (value) {
                      setState(() {
                        _includeSpecialChars = value;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 生成密码按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generatePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('生成密码'),
                ),
              ),

              const SizedBox(height: 24),

              // 生成的密码显示
              if (_generatedPassword.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('生成的密码:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SelectableText(
                              _generatedPassword,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyPassword,
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 生成密码
  void _generatePassword() {
    final password = PasswordGenerator.generatePassword(
      length: _passwordLength,
      includeUppercase: _includeUppercase,
      includeLowercase: _includeLowercase,
      includeNumbers: _includeNumbers,
      includeSpecialChars: _includeSpecialChars,
    );

    setState(() {
      _generatedPassword = password;
    });
  }

  // 复制密码到剪贴板并返回
  void _copyPassword() {
    if (_generatedPassword.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      SnackBarUtil.show(context, '密码已复制到剪贴板');
      Navigator.pop(context, _generatedPassword);
    }
  }
}
