import 'package:flutter/material.dart';
import 'package:pass_clip/services/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  String _password = '';
  int _failedAttempts = 0;
  DateTime? _lockUntil;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _loadLockState();
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

  // 验证密码
  Future<void> _verifyPassword() async {
    // 提前获取NavigatorState
    final navigator = Navigator.of(context);

    // 对于密码验证，不显示加载指示器，避免快速闪烁
    // 因为密码验证通常是本地操作，速度很快

    try {
      final isPasswordCorrect = await _authService.verifyPassword(_password);

      if (isPasswordCorrect) {
        // 密码正确，重置失败次数和锁定状态
        _failedAttempts = 0;
        _lockUntil = null;

        // 保存重置后的状态到持久化存储
        await _authService.resetLockState();

        if (mounted) {
          navigator.pushReplacementNamed('/');
        }
      } else {
        final newFailedAttempts = _failedAttempts + 1;
        DateTime? newLockUntil;

        // 先保存失败次数到本地
        await _authService.saveFailedAttempts(newFailedAttempts);

        // 如果失败次数达到5次，锁定账号5分钟
        if (newFailedAttempts >= 5) {
          newLockUntil = DateTime.now().add(const Duration(minutes: 5));
          await _authService.saveLockUntil(newLockUntil);
        } else {
          // 未达到锁定条件，清除锁定时间
          await _authService.saveLockUntil(null);
        }

        // 合并所有状态更新到一个setState中
        if (mounted) {
          setState(() {
            _failedAttempts = newFailedAttempts;
            _password = '';
            _lockUntil = newLockUntil;
          });

          // 如果设置了锁定时间，启动定时器
          if (newLockUntil != null) {
            _startLockTimer();
          }

          // 延迟显示Toast，避开UI刷新的时机
          Future.delayed(const Duration(milliseconds: 50), () {
            Fluttertoast.showToast(
              msg: '密码错误，剩余尝试次数：${5 - newFailedAttempts}',
              gravity: ToastGravity.BOTTOM, // 固定在底部，避免布局跳动
            );
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '验证失败，请重试');
    }
  }

  // 显示密码提示
  void _onPasswordHint() {
    // 获取密码提示
    _authService
        .getPasswordHint()
        .then((hint) {
          if (mounted) {
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
            Fluttertoast.showToast(msg: '获取密码提示失败，请重试');
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
      key: const ValueKey('numberPad'), // 添加稳定的key
      crossAxisCount: 3, // 3列
      shrinkWrap: true, // 自适应高度
      mainAxisSpacing: 12.0, // 主轴间距（垂直方向）
      crossAxisSpacing: 12.0, // 交叉轴间距（水平方向）
      padding: const EdgeInsets.all(40.0), // 内边距（4个方向）
      children: numbers.map((number) {
        if (number.isEmpty) {
          return const SizedBox(key: ValueKey('emptyCell')); // 添加稳定的key
        }

        return ElevatedButton(
          key: ValueKey('numberButton_$number'), // 为每个按钮添加唯一key
          onPressed: _isAccountLocked()
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
                ? const EdgeInsets.all(6.0)
                : const EdgeInsets.all(10.0),
            textStyle: TextStyle(fontSize: number == '删除' ? 12.0 : 16.0),
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
    final Color primaryColor = theme.colorScheme.primary; // 取主题主色

    return Row(
      key: const ValueKey('passwordDisplay'), // 添加稳定的key，避免不必要的重建
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        return Container(
          key: ValueKey('passwordDot_$index'), // 为每个密码点添加唯一key
          width: 36.0,
          height: 36.0,
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),
            // 输入过的位置填充主色，未输入的透明
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32.0), // 顶部间距32
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '秘荚登录',
                style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
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
                  _buildPasswordDisplay(), // 密码显示区域
                  const SizedBox(height: 16.0), // 密码显示与键盘间距
                ],
              ),
            const SizedBox(height: 10.0), // 键盘与密码提示间距
            if (!_isAccountLocked()) _buildNumberPad(), // 数字键盘
            //const Spacer(), // 密码提示按钮与键盘之间的间距
            TextButton(onPressed: _onPasswordHint, child: const Text('密码提示？')),
            const SizedBox(height: 16.0), // 密码提示按钮与底部间距
          ],
        ),
      ),
    );
  }
}
