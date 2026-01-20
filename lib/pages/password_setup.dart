import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PasswordSetupPage extends StatefulWidget {
  const PasswordSetupPage({super.key, this.isFirstTime = true});

  final bool isFirstTime; // 是否是首次登录

  @override
  State<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends State<PasswordSetupPage> {
  final AuthService _authService = AuthService(); // 认证服务
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordHintController = TextEditingController();

  bool _hasOldPassword = false; // 是否有旧密码
  bool _isObscureOld = true; // 是否隐藏旧密码
  bool _isObscureNew = true; // 是否隐藏新密码
  bool _isObscureConfirm = true; // 是否隐藏确认密码
  bool _isLoading = false; // 是否正在加载

  @override
  void initState() {
    super.initState();
    _checkIfPasswordExists();
  }

  // 检查是否已设置密码
  Future<void> _checkIfPasswordExists() async {
    final isSet = await _authService.isPasswordSet();
    setState(() {
      _hasOldPassword = isSet;
    });
  }

  // 检查密码是否为4位数字
  bool _isPasswordValid(String password) {
    // 检查长度和是否全为数字
    return password.length == 4 && RegExp(r'^\d+$').hasMatch(password);
  }

  // 保存密码
  Future<void> _savePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 如果有旧密码，先验证
        if (_hasOldPassword) {
          final isCorrect = await _authService.verifyPassword(
            _oldPasswordController.text,
          );
          if (!isCorrect) {
            setState(() {
              _isLoading = false;
            });
            Fluttertoast.showToast(msg: '旧密码错误，请重新输入');
            return;
          }
        }

        // 保存新密码
        await _authService.savePassword(_passwordController.text);
        await _authService.saveLoginStatus(true);

        // 保存密码提示
        if (_passwordHintController.text.isNotEmpty) {
          await _authService.savePasswordHint(_passwordHintController.text);
        }

        Fluttertoast.showToast(msg: '密码设置成功');

        // 导航到主界面
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
          }
        });
      } catch (e) {
        Fluttertoast.showToast(msg: '密码设置失败：$e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isFirstTime ? '设置解锁密码' : '修改解锁密码')),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 旧密码（如果有）
                    if (_hasOldPassword)
                      Column(
                        children: [
                          TextFormField(
                            controller: _oldPasswordController,
                            decoration: InputDecoration(
                              labelText: '旧密码',
                              hintText: '请输入旧的4位数字密码',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscureOld
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscureOld = !_isObscureOld;
                                  });
                                },
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: _isObscureOld,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入旧密码';
                              }
                              if (!_isPasswordValid(value)) {
                                return '请输入4位数字密码';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),

                    // 新密码
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '新密码',
                        hintText: '请输入新的4位数字密码',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscureNew = !_isObscureNew;
                            });
                          },
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: _isObscureNew,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ], // 只允许输入数字
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入新密码';
                        }
                        if (!_isPasswordValid(value)) {
                          return '请输入4位数字密码';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // 确认密码
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: '确认密码',
                        hintText: '请再次输入新密码',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscureConfirm = !_isObscureConfirm;
                            });
                          },
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: _isObscureConfirm,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请确认新密码';
                        }
                        if (!_isPasswordValid(value)) {
                          return '请输入4位数字密码';
                        }
                        if (value != _passwordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),

                    // 密码提示
                    TextFormField(
                      controller: _passwordHintController,
                      decoration: const InputDecoration(
                        labelText: '密码提示（可选）',
                        hintText: '请输入密码提示，帮助你回忆密码',
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 32.0),

                    // 保存按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          textStyle: const TextStyle(fontSize: 18.0),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20.0,
                                height: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 加载指示器
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
