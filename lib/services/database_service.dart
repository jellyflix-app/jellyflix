import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/services/secure_storage_service.dart';

class DatabaseService {
  static final Map<String, DatabaseService> _instances = {};

  Box? _box;
  String? boxName;
  SecureStorageService secureStorage;

  factory DatabaseService(String boxName, SecureStorageService secureStorage) {
    if (_instances.containsKey(boxName)) {
      return _instances[boxName]!;
    }
    _instances[boxName] = DatabaseService._internal(boxName, secureStorage);
    return _instances[boxName]!;
  }

  DatabaseService._internal(this.boxName, this.secureStorage);

  static Future<void> initialize() async {
    await Hive.initFlutter("jellyflix");
    Hive.registerAdapter(UserAdapter());
    await DatabaseService('auth', SecureStorageService()).openBox();
    await DatabaseService('settings', SecureStorageService()).openBox();
  }

  Future<void> openBox() async {
    String? key = await secureStorage
        .read('encryptionKey')
        .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
    if (key == null) {
      // create a new key
      final encryptionKeyUint8List = Hive.generateSecureKey();
      await secureStorage
          .write('encryptionKey', base64Url.encode(encryptionKeyUint8List))
          .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
      // verify key was created
      key = await secureStorage
          .read('encryptionKey')
          .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
      // fallback
      key ??= const String.fromEnvironment('ENCRYPTION_KEY',
          defaultValue: '7HJ6Y_RzPoOxrPyBFVHJJlrr8gsRL2N09o7ee10f8fk=');
    }
    final encryptionKeyUint8List = base64Url.decode(key);
    _box ??= await Hive.openBox(boxName!,
        encryptionCipher: HiveAesCipher(encryptionKeyUint8List));
  }

  Future<void> put(String key, dynamic value) async {
    await _box!.put(key, value);
  }

  dynamic get(String key) {
    return _box!.get(key);
  }

  dynamic getAll() {
    return _box!.toMap();
  }

  Future<void> delete(String key) async {
    await _box!.delete(key);
  }
}
