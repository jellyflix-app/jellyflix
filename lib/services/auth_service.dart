import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/secure_storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final SecureStorageService _secureStorageService;

  final StreamController<bool> _authStateStream = StreamController();
  Stream<bool> get authStateChange => _authStateStream.stream;

  Future<bool> get isAuthenticated => _authStateStream.stream.last;

  User? get currentProfile => _apiService.currentUser;

  AuthService(
      {required ApiService apiService,
      required SecureStorageService secureStorageService})
      : _apiService = apiService,
        _secureStorageService = secureStorageService {
    _authStateStream.add(false);
    checkAuthentication().then((value) {
      _authStateStream.add(value);
    });
  }

  Future<bool> checkAuthentication({int? profileIndex}) async {
    profileIndex ??= await currentProfileIndex();
    if (profileIndex == null) {
      _authStateStream.add(false);
      return false;
    }
    String? storedUsername =
        await _secureStorageService.read("username$profileIndex");
    String? storedPassword =
        await _secureStorageService.read("password$profileIndex");
    String? storedServerAdress =
        await _secureStorageService.read("serverAdress$profileIndex");
    try {
      if (storedUsername != null &&
          storedPassword != null &&
          storedServerAdress != null) {
        await _apiService.login(
            storedServerAdress, storedUsername, storedPassword);
        _authStateStream.add(true);
        return true;
      }
      _authStateStream.add(false);
      return false;
    } catch (e) {
      debugPrint(e.toString());
      _authStateStream.add(false);
      return false;
    }
  }

  Future login(String serverAdress, String username, String password) async {
    if (!serverAdress.startsWith("http://") &&
        !serverAdress.startsWith("https://")) {
      serverAdress = "http://$serverAdress";
    }
    User? user;
    try {
      user = await _apiService.login(serverAdress, username, password);
    } catch (e) {
      if (serverAdress.split(":").last != "8096" &&
          serverAdress.split(":").length == 2) {
        serverAdress = "$serverAdress:8096";
        user = await _apiService.login(serverAdress, username, password);
      } else {
        rethrow;
      }
    }
    int profileIndex = await saveProfile(user, password, serverAdress);
    await updateCurrentProfileIndex(profileIndex);
    _authStateStream.add(true);
  }

  Future<void> updateCurrentProfileIndex(int? profileIndex) async {
    await _secureStorageService.delete("currentProfileIndex");
    await _secureStorageService.write(
        "currentProfileIndex", profileIndex == null ? null : "$profileIndex");
  }

  Future logout({int? profileIndex}) async {
    profileIndex ??= await currentProfileIndex();
    await _secureStorageService.delete("username${profileIndex!}");
    await _secureStorageService.delete("password$profileIndex");
    await _secureStorageService.delete("serverAdress$profileIndex");
    await _secureStorageService.delete("userid$profileIndex");
    await _secureStorageService.delete("currentProfileIndex");
    _authStateStream.add(false);
  }

  Future<int> saveProfile(
    User user,
    String password,
    String serverAdress,
  ) async {
    var profileIndex = 0;
    // check if username with same name exists
    var allValues = await _secureStorageService.readAll();
    // max 25 profiles
    while (
        allValues.containsKey("username$profileIndex") || profileIndex > 24) {
      profileIndex++;
    }
    if (profileIndex > 24) {
      throw Exception("Max 25 profiles allowed");
    }
    await _secureStorageService.write("username$profileIndex", user.name);
    await _secureStorageService.write("password$profileIndex", password);
    await _secureStorageService.write("userid$profileIndex", user.id);
    await _secureStorageService.write(
        "serverAdress$profileIndex", serverAdress);

    return profileIndex;
  }

  Future switchProfile(profileIndex) async {
    String? storedUsername =
        await _secureStorageService.read("username$profileIndex");
    String? storedPassword =
        await _secureStorageService.read("password$profileIndex");
    String? storedServerAdress =
        await _secureStorageService.read("serverAdress$profileIndex");
    if (storedUsername != null &&
        storedPassword != null &&
        storedServerAdress != null) {
      await _apiService.login(
          storedServerAdress, storedUsername, storedPassword);
      _authStateStream.add(true);
    } else {
      throw Exception("Profile not found");
    }
  }

  Future<int?> currentProfileIndex() async {
    String currentProfileIndexString =
        await _secureStorageService.read("currentProfileIndex") ?? "";
    return int.tryParse(currentProfileIndexString);
  }

  Future<bool> profilesIsNotEmpty() async {
    var allValues = await _secureStorageService.contains("username");
    return allValues.isNotEmpty;
  }

  Future<List<User>> getAllProfiles() async {
    var allValues = await _secureStorageService.contains("username");

    List<User> profiles = [];
    allValues.forEach((key, value) async {
      var profileIndex = int.parse(key.split("username").last);
      var serverAdress =
          await _secureStorageService.read("serverAdress$profileIndex");
      var userId = await _secureStorageService.read("userid$profileIndex");
      profiles.add(User(
          profileIndex: profileIndex,
          name: value,
          serverAdress: serverAdress!,
          id: userId));
    });
    return profiles;
  }
}
