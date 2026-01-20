import 'package:flutter/material.dart';
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
  String _password = ''; // 密码
  String _confirmPassword = ''; // 确认密码
  bool _isSecondStep = false; // 是否是确认密码步骤
  bool _isSettingHint = false; // 是否是设置密码提示步骤
  String _passwordHint = ''; // 密码提示
  bool _isLoading = false; // 是否正在加载

  // 检查密码长度是否为4位
  bool _isPasswordValid(String password) {
    return password.length == 4;
  }

  // 处理数字输入
  void _onNumberPressed(String number) {
    if (_isSecondStep) {
      if (_confirmPassword.length < 4) {
        setState(() {
          _confirmPassword += number;
        });

        // 如果密码长度符合要求，自动进入下一步
        if (_isPasswordValid(_confirmPassword)) {
          _verifyPassword();
        }
      }
    } else {
      if (_password.length < 4) {
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
          _confirmPassword = _confirmPassword.substring(
            0,
            _confirmPassword.length - 1,
          );
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

      Fluttertoast.showToast(msg: '两次密码不一致，请重新输入');
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
      await _authService.savePassword(_password); // 保存密码到本地存储
      await _authService.saveLoginStatus(true); // 标记“已设置密码”，跳过后续首次启动流程
      Fluttertoast.showToast(msg: '密码设置成功'); // 显示成功提示

      // 进入密码提示设置步骤
      setState(() {
        _isSettingHint = true;
        _isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: '密码设置失败：$e'); // 显示失败提示

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存密码提示
  Future<void> _savePasswordHint() async {
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.savePasswordHint(_passwordHint); // 保存密码提示到本地存储
      Fluttertoast.showToast(msg: '密码提示设置成功'); // 显示成功提示

      // 延迟导航到主界面，清除所有之前的界面
      Future.delayed(const Duration(milliseconds: 200), () {
        navigator.pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      });
    } catch (e) {
      Fluttertoast.showToast(msg: '密码提示设置失败：$e'); // 显示失败提示

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 处理密码提示输入变化
  void _onHintChanged(String value) {
    setState(() {
      _passwordHint = value;
    });
  }

  // 构建数字键盘
  Widget _buildNumberPad() {
    final numbers = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      '删除',
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 12.0,
      crossAxisSpacing: 12.0,
      padding: const EdgeInsets.all(16.0),
      children: numbers.map((number) {
        if (number.isEmpty) {
          return const SizedBox();
        }

        return ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (number == '删除') {
                    _onDeletePressed();
                  } else {
                    _onNumberPressed(number);
                  }
                },
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: number == '删除'
                ? const EdgeInsets.all(10.0)
                : const EdgeInsets.all(16.0),
            textStyle: TextStyle(fontSize: number == '删除' ? 16.0 : 20.0),
          ),
          child: Text(number),
        );
      }).toList(),
    );
  }

  // 构建密码显示区域
  Widget _buildPasswordDisplay() {
    final password = _isSecondStep ? _confirmPassword : _password;
    final maxLength = 4;
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        return Container(
          width: 36.0,
          height: 36.0,
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
            color: index < password.length ? primaryColor : Colors.transparent,
          ),
        );
      }),
    );
  }

  // 构建密码提示设置界面
  Widget _buildPasswordHintSetup() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '请设置密码提示，帮助你回忆密码（可选）',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18.0),
          ),
        ),
        const SizedBox(height: 32.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: TextField(
            onChanged: _onHintChanged,
            decoration: InputDecoration(
              hintText: '输入密码提示',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.all(16.0),
            ),
            maxLength: 50,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20.0),
            onSubmitted: (value) {
              _savePasswordHint();
            },
          ),
        ),
        const SizedBox(height: 64.0),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePasswordHint,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 64.0,
              vertical: 16.0,
            ),
            textStyle: const TextStyle(fontSize: 18.0),
          ),
          child: const Text('完成'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSettingHint
              ? '设置密码提示'
              : widget.isFirstTime
              ? '设置解锁密码'
              : '修改解锁密码',
        ),
        leading: _isSettingHint
            ? null // 密码提示设置步骤不允许返回
            : _isSecondStep
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
      body: SafeArea(
        child: Stack(
          children: [
            if (_isSettingHint)
              _buildPasswordHintSetup() // 显示密码提示设置界面
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _isSecondStep ? '请再次输入密码确认' : '请设置4位纯数字解锁密码，保护你的账号安全',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _buildPasswordDisplay(),
                  const SizedBox(height: 32.0),
                  _buildNumberPad(),
                ],
              ),
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
