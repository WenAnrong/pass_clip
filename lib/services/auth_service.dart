import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';

class AuthService {
  // 静态私有实例（唯一的管家）
  static final AuthService _instance = AuthService._internal();
  // 工厂构造函数（对外提供唯一实例）
  factory AuthService() => _instance;
  // 私有构造函数（禁止外部new AuthService()）
  AuthService._internal();

  // 根据平台选择存储方式
  dynamic _storage;
  bool _isStorageInitialized = false;

  // 初始化存储服务
  Future<void> _initializeStorage() async {
    if (_isStorageInitialized) return;

    if (Platform.isAndroid || Platform.isIOS) {
      // 在安卓和iOS平台使用flutter_secure_storage
      _storage = const FlutterSecureStorage();
    } else {
      // 在其他平台使用shared_preferences
      _storage = await SharedPreferences.getInstance();
    }

    _isStorageInitialized = true;
  }

  // 读取存储数据
  Future<String?> _read(String key) async {
    await _initializeStorage();

    if (_storage is FlutterSecureStorage) {
      return await (_storage as FlutterSecureStorage).read(key: key);
    } else if (_storage is SharedPreferences) {
      return (_storage as SharedPreferences).getString(key);
    }
    return null;
  }

  // 写入存储数据
  Future<void> _write(String key, String value) async {
    await _initializeStorage();

    if (_storage is FlutterSecureStorage) {
      await (_storage as FlutterSecureStorage).write(key: key, value: value);
    } else if (_storage is SharedPreferences) {
      await (_storage as SharedPreferences).setString(key, value);
    }
  }

  // 删除存储数据
  Future<void> _delete(String key) async {
    await _initializeStorage();

    if (_storage is FlutterSecureStorage) {
      await (_storage as FlutterSecureStorage).delete(key: key);
    } else if (_storage is SharedPreferences) {
      await (_storage as SharedPreferences).remove(key);
    }
  }

  // 删除所有存储数据
  Future<void> _deleteAll() async {
    await _initializeStorage();

    if (_storage is FlutterSecureStorage) {
      await (_storage as FlutterSecureStorage).deleteAll();
    } else if (_storage is SharedPreferences) {
      // 对于SharedPreferences，只删除我们应用相关的键
      await (_storage as SharedPreferences).remove('encryption_key');
      await (_storage as SharedPreferences).remove('encryption_iv');
      await (_storage as SharedPreferences).remove('encrypted_password');
      await (_storage as SharedPreferences).remove('failed_attempts');
      await (_storage as SharedPreferences).remove('lock_until');
      await (_storage as SharedPreferences).remove('password_hint');
    }
  }

  // 加密密钥和初始化向量
  late Key _key;
  late IV _iv;
  late Encrypter _encrypter;

  // 初始化完成的Future
  Future<void>? _initializationFuture;

  // 缓存常用值
  bool? _isPasswordSetCache;

  // 初始化加密参数
  Future<void> _initialize() async {
    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    final completer = Completer<void>();
    _initializationFuture = completer.future;

    try {
      await _initializeStorage();
      // 尝试从存储中获取密钥和IV
      final keyString = await _read('encryption_key');
      final ivString = await _read('encryption_iv');

      if (keyString != null && ivString != null) {
        // 使用已存储的密钥和IV
        _key = Key.fromBase64(keyString);
        _iv = IV.fromBase64(ivString);
      } else {
        // 生成新的密钥和IV
        _key = Key.fromLength(32);
        _iv = IV.fromLength(16);

        // 存储密钥和IV
        await _write('encryption_key', _key.base64);
        await _write('encryption_iv', _iv.base64);
      }

      _encrypter = Encrypter(AES(_key));
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      _initializationFuture = null; // 允许重新初始化
    }
  }

  // 保存密码（应用密码，用于登录验证）
  Future<void> savePassword(String password) async {
    await _initialize();
    // 加密密码
    final encryptedPassword = _encrypter.encrypt(password, iv: _iv);
    await _write('encrypted_password', encryptedPassword.base64);
    // 更新缓存
    _isPasswordSetCache = true;
  }

  // 验证密码
  Future<bool> verifyPassword(String password) async {
    final encryptedPassword = await _read('encrypted_password');
    if (encryptedPassword == null) {
      _isPasswordSetCache = false;
      return false; // 没设置过密码
    }

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
    if (_isPasswordSetCache != null) {
      return _isPasswordSetCache!;
    }

    final encryptedPassword = await _read('encrypted_password');
    _isPasswordSetCache = encryptedPassword != null;
    return _isPasswordSetCache!;
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
    await _write('failed_attempts', attempts.toString());
  }

  // 获取失败尝试次数
  Future<int> getFailedAttempts() async {
    final attempts = await _read('failed_attempts');
    return attempts != null ? int.parse(attempts) : 0;
  }

  // 保存锁定截止时间
  Future<void> saveLockUntil(DateTime? lockUntil) async {
    if (lockUntil != null) {
      await _write('lock_until', lockUntil.toIso8601String());
    } else {
      await _delete('lock_until');
    }
  }

  // 获取锁定截止时间
  Future<DateTime?> getLockUntil() async {
    final lockUntil = await _read('lock_until');
    return lockUntil != null ? DateTime.parse(lockUntil) : null;
  }

  // 重置锁定状态
  Future<void> resetLockState() async {
    await _delete('failed_attempts');
    await _delete('lock_until');
  }

  // 保存密码提示
  Future<void> savePasswordHint(String hint) async {
    // 密码提示不需要加密，直接保存
    await _write('password_hint', hint);
  }

  // 获取密码提示
  Future<String?> getPasswordHint() async {
    return await _read('password_hint');
  }

  // 检查是否已设置密码提示
  Future<bool> isPasswordHintSet() async {
    final hint = await _read('password_hint');
    return hint != null && hint.isNotEmpty;
  }

  // 删除密码提示
  Future<void> deletePasswordHint() async {
    await _delete('password_hint');
  }

  // 清除所有数据
  Future<void> clearAllData() async {
    // 删除所有存储的数据
    await _deleteAll();
    // 重置状态和缓存
    _initializationFuture = null;
    _isPasswordSetCache = false;
  }
}
