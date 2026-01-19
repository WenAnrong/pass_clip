import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'dart:async';

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
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadLockState();
  }

  // 检查生物识别是否可用
  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _authService.isBiometricAvailable();
    // 加mounted检查，避免更新已销毁的State
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
      });
    }
  }

  // 加载锁定状态
  Future<void> _loadLockState() async {
    final attempts = await _authService.getFailedAttempts();
    final lockUntil = await _authService.getLockUntil();
    // 加mounted检查
    if (mounted) {
      setState(() {
        _failedAttempts = attempts;
        _lockUntil = lockUntil;
      });
    }
    // 启动定时器
    _startLockTimer();
  }

  // 启动定时器
  void _startLockTimer() {
    // 先停止已有的定时器
    _stopLockTimer();

    // 如果当前处于锁定状态，启动定时器
    if (_isAccountLocked()) {
      _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // 加mounted检查
        if (mounted) {
          setState(() {
            // 检查锁定时间是否已过
            if (!_isAccountLocked()) {
              // 锁定时间已过，停止定时器并重置锁定状态
              timer.cancel();
              _resetLockState();
            }
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  // 停止定时器
  void _stopLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  // 重置锁定状态
  Future<void> _resetLockState() async {
    // 加mounted检查
    if (mounted) {
      setState(() {
        _failedAttempts = 0;
        _lockUntil = null;
      });
    }
    await _authService.resetLockState();
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

  @override
  void dispose() {
    // 组件卸载时停止定时器
    _stopLockTimer();
    super.dispose();
  }

  // 处理数字输入
  void _onNumberPressed(String number) {
    if (_isAccountLocked()) return;
    if (_password.length < 4) {
      setState(() {
        _password += number;
      });

      // 如果密码长度符合要求，自动进行验证
      if (_password.length == 4) {
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

  // 验证密码（核心修复：跳转前加mounted检查）
  Future<void> _verifyPassword() async {
    // 提前缓存需要的对象，避免异步后用context
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // 提前获取NavigatorState（可选，进一步降低风险）
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final isPasswordCorrect = await _authService.verifyPassword(_password);

      if (isPasswordCorrect) {
        // 密码正确，重置失败次数和锁定状态
        _failedAttempts = 0;
        _lockUntil = null;

        // 保存重置后的状态到持久化存储
        await _authService.resetLockState();

        // 保存登录状态
        await _authService.saveLoginStatus(true);

        // 修复关键1：跳转前检查mounted，避免操作已销毁的context
        if (mounted) {
          // 用提前获取的navigator跳转，而非直接用context
          navigator.pushReplacementNamed('/');
        }
      } else {
        // 密码错误，增加失败次数
        if (mounted) {
          setState(() {
            _failedAttempts++;
            _password = '';
          });
        }

        // 保存失败尝试次数到持久化存储
        await _authService.saveFailedAttempts(_failedAttempts);

        // 如果失败次数达到5次，锁定账号5分钟
        if (_failedAttempts >= 5) {
          final newLockUntil = DateTime.now().add(const Duration(minutes: 5));
          if (mounted) {
            setState(() {
              _lockUntil = newLockUntil;
            });
          }
          // 保存锁定时间到持久化存储
          await _authService.saveLockUntil(newLockUntil);
          // 启动定时器
          _startLockTimer();
        } else {
          // 未达到锁定条件，清除锁定时间
          await _authService.saveLockUntil(null);
        }

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('密码错误，剩余尝试次数：${5 - _failedAttempts}')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('验证失败，请重试')));
    } finally {
      // 修复关键2：更新状态前检查mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 使用生物识别登录（核心修复：跳转前加mounted检查）
  Future<void> _loginWithBiometrics() async {
    // 提前缓存需要的对象
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_isBiometricAvailable) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isAuthenticated = await _authService.authenticateWithBiometrics();
      if (isAuthenticated) {
        // 生物识别成功，重置锁定状态
        await _authService.resetLockState();

        // 保存登录状态
        await _authService.saveLoginStatus(true);
        // 修复关键：跳转前检查mounted
        if (mounted) {
          navigator.pushReplacementNamed('/');
        }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('生物识别失败，请重试或使用密码登录')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('生物识别失败，请重试')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 显示密码提示
  void _onPasswordHint() {
    // 提前缓存需要的对象
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    // 获取密码提示
    _authService
        .getPasswordHint()
        .then((hint) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            // 显示密码提示对话框
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('密码提示'),
                content: Text(
                  hint != null && hint.isNotEmpty ? '你的密码提示：$hint' : '你未设置密码提示',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('获取密码提示失败，请重试')),
            );
          }
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
          onPressed: (_isLoading || _isAccountLocked())
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
            color: index < _password.length ? primaryColor : Colors.transparent,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32.0),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '秘荚登录',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (_isAccountLocked())
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '密码错误次数过多，${_getRemainingLockTime()}后重试',
                      style: const TextStyle(color: Colors.red, fontSize: 16.0),
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildPasswordDisplay(),
                      const SizedBox(height: 24.0),
                      if (_isBiometricAvailable)
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loginWithBiometrics,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('使用生物识别登录'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 10.0,
                            ),
                            textStyle: const TextStyle(fontSize: 16.0),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16.0),
                if (!_isAccountLocked()) _buildNumberPad(),
                const Spacer(),
                TextButton(
                  onPressed: _onPasswordHint,
                  child: const Text('密码提示？'),
                ),
                const SizedBox(height: 16.0),
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
