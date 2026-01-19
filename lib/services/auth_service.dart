import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:math';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();

  // 加密密钥和初始化向量
  late Key _key;
  late IV _iv;
  late Encrypter _encrypter;
  bool _isInitialized = false;

  // 初始化加密参数
  Future<void> _initialize() async {
    if (_isInitialized) return;

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

  // 保存密码
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
    if (encryptedPassword == null) return false;

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

  // 检查生物识别是否可用
  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // 进行生物识别验证
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(localizedReason: '使用生物识别登录');
    } catch (e) {
      return false;
    }
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
}
