import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/routers/index.dart';

class PasswordSetupPage extends StatefulWidget {
  const PasswordSetupPage({super.key, this.isFirstTime = true});

  final bool isFirstTime;

  @override
  State<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends State<PasswordSetupPage> {
  final AuthService _authService = AuthService();
  String _password = '';
  String _confirmPassword = '';
  bool _isSecondStep = false;
  bool _isLoading = false;

  // 检查密码长度是否为4或6位
  bool _isPasswordValid(String password) {
    return password.length == 4 || password.length == 6;
  }

  // 处理数字输入
  void _onNumberPressed(String number) {
    if (_isSecondStep) {
      if (_confirmPassword.length < 6) {
        setState(() {
          _confirmPassword += number;
        });

        // 如果密码长度符合要求，自动进入下一步
        if (_isPasswordValid(_confirmPassword)) {
          _verifyPassword();
        }
      }
    } else {
      if (_password.length < 6) {
        setState(() {
          _password += number;
        });

        // 如果密码长度符合要求，自动进入下一步
        if (_isPasswordValid(_password)) {
          setState(() {
            _isSecondStep = true;
          });
        }
      }
    }
  }

  // 删除最后一位密码
  void _onDeletePressed() {
    if (_isSecondStep) {
      if (_confirmPassword.isNotEmpty) {
        setState(() {
          _confirmPassword = _confirmPassword.substring(0, _confirmPassword.length - 1);
        });
      }
    } else {
      if (_password.isNotEmpty) {
        setState(() {
          _password = _password.substring(0, _password.length - 1);
        });
      }
    }
  }

  // 验证两次密码是否一致
  void _verifyPassword() {
    if (_password != _confirmPassword) {
      // 两次密码不一致
      setState(() {
        _isSecondStep = false;
        _password = '';
        _confirmPassword = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次密码不一致，请重新输入')),
      );
    } else {
      // 密码一致，保存密码
      _savePassword();
    }
  }

  // 保存密码
  Future<void> _savePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.savePassword(_password);
      await _authService.saveLoginStatus(true);

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码设置成功')),
      );

      // 延迟导航到主界面
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('密码设置失败：$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 构建数字键盘
  Widget _buildNumberPad() {
    final numbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '删除'];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      padding: const EdgeInsets.all(16.0),
      children: numbers.map((number) {
        if (number.isEmpty) {
          return const SizedBox();
        }

        return ElevatedButton(
          onPressed: _isLoading ? null : () {
            if (number == '删除') {
              _onDeletePressed();
            } else {
              _onNumberPressed(number);
            }
          },
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: const EdgeInsets.all(20.0),
            textStyle: const TextStyle(fontSize: 24.0),
          ),
          child: Text(number),
        );
      }).toList(),
    );
  }

  // 构建密码显示区域
  Widget _buildPasswordDisplay() {
    final password = _isSecondStep ? _confirmPassword : _password;
    final maxLength = 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        return Container(
          width: 40.0,
          height: 40.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
            color: index < password.length ? Colors.orange : Colors.transparent,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstTime ? '设置解锁密码' : '修改解锁密码'),
        leading: _isSecondStep
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSecondStep = false;
                    _confirmPassword = '';
                  });
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _isSecondStep
                      ? '请再次输入密码确认' 
                      : '请设置4/6位纯数字解锁密码，保护你的账号安全',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18.0),
                ),
              ),
              const SizedBox(height: 32.0),
              _buildPasswordDisplay(),
              const SizedBox(height: 64.0),
              _buildNumberPad(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
