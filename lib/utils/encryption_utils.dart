import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

class EncryptionUtils {
  // 静态私有实例（唯一的管家）
  static final EncryptionUtils _instance = EncryptionUtils._internal();
  // 工厂构造函数（对外提供唯一实例）
  factory EncryptionUtils() => _instance;
  // 私有构造函数（禁止外部new EncryptionUtils()）
  EncryptionUtils._internal();

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

  // 加密密钥和初始化向量
  late Key _key;
  late IV _iv;
  late Encrypter _encrypter;

  // 初始化完成的Future
  Future<void>? _initializationFuture;

  // 初始化加密参数
  Future<void> _initialize() async {
    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    final completer = Completer<void>();
    _initializationFuture = completer.future;

    try {
      await _initializeStorage();
      // 直接从存储中获取密钥和IV
      // 登录时已经确保了密钥的存在
      final keyString = await _read('encryption_key');
      final ivString = await _read('encryption_iv');

      if (keyString == null || ivString == null) {
        // 密钥不存在，抛出异常让调用者处理
        throw Exception('加密密钥未初始化，请先登录');
      }

      // 使用已存储的密钥和IV
      _key = Key.fromBase64(keyString);
      _iv = IV.fromBase64(ivString);
      _encrypter = Encrypter(AES(_key));
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      _initializationFuture = null; // 允许重新初始化
    }
  }

  // 加密字符串
  Future<String> encrypt(String plainText) async {
    await _initialize();
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  // 解密字符串
  Future<String> decrypt(String encryptedText) async {
    await _initialize();
    final decrypted = _encrypter.decrypt(
      Encrypted.fromBase64(encryptedText),
      iv: _iv,
    );
    return decrypted;
  }

  // 批量加密Map中的值
  Future<Map<String, String>> encryptMap(Map<String, String> data) async {
    await _initialize();
    final encryptedMap = <String, String>{};

    for (final entry in data.entries) {
      final encrypted = _encrypter.encrypt(entry.value, iv: _iv);
      encryptedMap[entry.key] = encrypted.base64;
    }

    return encryptedMap;
  }

  // 批量解密Map中的值
  Future<Map<String, String>> decryptMap(
    Map<String, String> encryptedData,
  ) async {
    await _initialize();
    final decryptedMap = <String, String>{};

    for (final entry in encryptedData.entries) {
      final decrypted = _encrypter.decrypt(
        Encrypted.fromBase64(entry.value),
        iv: _iv,
      );
      decryptedMap[entry.key] = decrypted;
    }

    return decryptedMap;
  }
}
