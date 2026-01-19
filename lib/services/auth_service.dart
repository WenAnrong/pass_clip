import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:math';

class AuthService {
  // 静态私有实例（唯一的管家）
  static final AuthService _instance = AuthService._internal();
  // 工厂构造函数（对外提供唯一实例）
  factory AuthService() => _instance;
  // 私有构造函数（禁止外部new AuthService()）
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 加密密钥和初始化向量
  late Key _key;
  late IV _iv;
  late Encrypter _encrypter;
  bool _isInitialized = false;

  // 初始化加密参数
  Future<void> _initialize() async {
    if (_isInitialized) return; // 避免重复初始化

    // 尝试从存储中获取密钥和IV
    final keyString = await _storage.read(key: 'encryption_key');
    final ivString = await _storage.read(key: 'encryption_iv');

    if (keyString != null && ivString != null) {
      // 使用已存储的密钥和IV
      _key = Key.fromBase64(keyString);
      _iv = IV.fromBase64(ivString);
    } else {
      // 生成新的密钥和IV
      _key = Key.fromLength(32);
      _iv = IV.fromLength(16);

      // 存储密钥和IV
      await _storage.write(key: 'encryption_key', value: _key.base64);
      await _storage.write(key: 'encryption_iv', value: _iv.base64);
    }

    _encrypter = Encrypter(AES(_key));
    _isInitialized = true;
  }

  // 保存密码（应用密码，用于登录验证）
  Future<void> savePassword(String password) async {
    await _initialize();
    // 加密密码
    final encryptedPassword = _encrypter.encrypt(password, iv: _iv);
    await _storage.write(
      key: 'encrypted_password',
      value: encryptedPassword.base64,
    );
  }

  // 验证密码
  Future<bool> verifyPassword(String password) async {
    final encryptedPassword = await _storage.read(key: 'encrypted_password');
    if (encryptedPassword == null) return false; // 没设置过密码

    await _initialize();

    try {
      final decryptedPassword = _encrypter.decrypt(
        Encrypted.fromBase64(encryptedPassword),
        iv: _iv,
      );
      return decryptedPassword == password;
    } catch (e) {
      return false;
    }
  }

  // 检查是否已设置密码
  Future<bool> isPasswordSet() async {
    final encryptedPassword = await _storage.read(key: 'encrypted_password');
    return encryptedPassword != null;
  }

  // 保存登录状态
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await _storage.write(key: 'is_logged_in', value: isLoggedIn.toString());
  }

  // 获取登录状态
  Future<bool> getLoginStatus() async {
    final status = await _storage.read(key: 'is_logged_in');
    return status == 'true';
  }

  // 清除登录状态
  Future<void> clearLoginStatus() async {
    await _storage.delete(key: 'is_logged_in');
  }

  // 生成随机密码
  String generateRandomPassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*()';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // 保存失败尝试次数
  Future<void> saveFailedAttempts(int attempts) async {
    await _storage.write(key: 'failed_attempts', value: attempts.toString());
  }

  // 获取失败尝试次数
  Future<int> getFailedAttempts() async {
    final attempts = await _storage.read(key: 'failed_attempts');
    return attempts != null ? int.parse(attempts) : 0;
  }

  // 保存锁定截止时间
  Future<void> saveLockUntil(DateTime? lockUntil) async {
    if (lockUntil != null) {
      await _storage.write(
        key: 'lock_until',
        value: lockUntil.toIso8601String(),
      );
    } else {
      await _storage.delete(key: 'lock_until');
    }
  }

  // 获取锁定截止时间
  Future<DateTime?> getLockUntil() async {
    final lockUntil = await _storage.read(key: 'lock_until');
    return lockUntil != null ? DateTime.parse(lockUntil) : null;
  }

  // 重置锁定状态
  Future<void> resetLockState() async {
    await _storage.delete(key: 'failed_attempts');
    await _storage.delete(key: 'lock_until');
  }

  // 保存密码提示
  Future<void> savePasswordHint(String hint) async {
    // 密码提示不需要加密，直接保存
    await _storage.write(key: 'password_hint', value: hint);
  }

  // 获取密码提示
  Future<String?> getPasswordHint() async {
    return await _storage.read(key: 'password_hint');
  }

  // 检查是否已设置密码提示
  Future<bool> isPasswordHintSet() async {
    final hint = await _storage.read(key: 'password_hint');
    return hint != null && hint.isNotEmpty;
  }

  // 删除密码提示
  Future<void> deletePasswordHint() async {
    await _storage.delete(key: 'password_hint');
  }
}
