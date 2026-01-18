import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:pass_clip/routers/index.dart';
import 'package:pass_clip/pages/password_setup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  String _password = '';
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  int _failedAttempts = 0;
  DateTime? _lockUntil;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _checkLoginStatus();
  }

  // 检查生物识别是否可用
  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _authService.isBiometricAvailable();
    setState(() {
      _isBiometricAvailable = isAvailable;
    });
  }

  // 检查是否已登录
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.getLoginStatus();
    if (isLoggedIn) {
      // 如果已登录，直接跳转到主界面
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  // 检查是否处于锁定状态
  bool _isAccountLocked() {
    if (_lockUntil == null) return false;
    return DateTime.now().isBefore(_lockUntil!);
  }

  // 获取锁定剩余时间
  String _getRemainingLockTime() {
    if (_lockUntil == null) return '';
    final remaining = _lockUntil!.difference(DateTime.now());
    return '${remaining.inMinutes}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  // 处理数字输入
  void _onNumberPressed(String number) {
    if (_isAccountLocked()) return;
    if (_password.length < 6) {
      setState(() {
        _password += number;
      });

      // 如果密码长度符合要求，自动进行验证
      if (_password.length == 4 || _password.length == 6) {
        _verifyPassword();
      }
    }
  }

  // 删除最后一位密码
  void _onDeletePressed() {
    if (_isAccountLocked()) return;
    if (_password.isNotEmpty) {
      setState(() {
        _password = _password.substring(0, _password.length - 1);
      });
    }
  }

  // 验证密码
  Future<void> _verifyPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isPasswordCorrect = await _authService.verifyPassword(_password);

      if (isPasswordCorrect) {
        // 密码正确，重置失败次数
        _failedAttempts = 0;
        _lockUntil = null;
        
        // 保存登录状态
        await _authService.saveLoginStatus(true);

        // 跳转到主界面
        Navigator.pushReplacementNamed(context, '/');
      } else {
        // 密码错误，增加失败次数
        setState(() {
          _failedAttempts++;
          _password = '';
        });

        // 如果失败次数达到5次，锁定账号5分钟
        if (_failedAttempts >= 5) {
          setState(() {
            _lockUntil = DateTime.now().add(const Duration(minutes: 5));
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('密码错误，剩余尝试次数：${5 - _failedAttempts}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证失败，请重试')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 使用生物识别登录
  Future<void> _loginWithBiometrics() async {
    if (!_isBiometricAvailable) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isAuthenticated = await _authService.authenticateWithBiometrics();
      if (isAuthenticated) {
        // 生物识别成功
        await _authService.saveLoginStatus(true);
        Navigator.pushReplacementNamed(context, '/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生物识别失败，请重试或使用密码登录')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生物识别失败，请重试')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 忘记密码
  void _onForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('忘记密码'),
        content: const Text('重置密码将清空所有数据，是否确认？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 清除所有数据
              setState(() {
                _isLoading = true;
              });

              try {
                // 清除本地存储的所有数据
                await _authService.saveLoginStatus(false);
                // TODO: 清除所有账号密码数据
                
                // 跳转到密码设置页面
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => const PasswordSetupPage(isFirstTime: false)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('重置失败，请重试')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
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
          onPressed: (_isLoading || _isAccountLocked()) ? null : () {
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
            color: index < _password.length ? Colors.orange : Colors.transparent,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 64.0),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '账号密码管理',
                  style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32.0),
              if (_isAccountLocked())
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '密码错误次数过多，${_getRemainingLockTime()}后重试',
                    style: const TextStyle(color: Colors.red, fontSize: 18.0),
                  ),
                )
              else
                Column(
                  children: [
                    _buildPasswordDisplay(),
                    const SizedBox(height: 32.0),
                    if (_isBiometricAvailable)
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _loginWithBiometrics,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('使用生物识别登录'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                          textStyle: const TextStyle(fontSize: 18.0),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 32.0),
              if (!_isAccountLocked()) _buildNumberPad(),
              const Spacer(),
              TextButton(
                onPressed: _onForgotPassword,
                child: const Text('忘记密码？'),
              ),
              const SizedBox(height: 16.0),
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
