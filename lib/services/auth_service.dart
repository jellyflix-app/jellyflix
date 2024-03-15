import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/database_service.dart';

class AuthService {
  final ApiService _apiService;
  //final SecureStorageService _secureStorageService;
  final DatabaseService _databaseService;

  final StreamController<bool> _authStateStream = StreamController();
  Stream<bool> get authStateChange => _authStateStream.stream;

  Future<bool> get isAuthenticated => _authStateStream.stream.last;

  User? get currentProfile => _apiService.currentUser;

  AuthService(
      {required ApiService apiService,
      required DatabaseService databaseService})
      : _apiService = apiService,
        _databaseService = databaseService {
    _authStateStream.add(false);
    checkAuthentication().then((value) {
      _authStateStream.add(value);
    });
  }

  Future<bool> checkAuthentication({String? profileId}) async {
    profileId ??= currentProfileid();
    if (profileId == null) {
      _authStateStream.add(false);
      return false;
    }
    User? user = _databaseService.get(profileId);
    try {
      if (user != null &&
          user.name != null &&
          user.password != null &&
          user.serverAdress != null) {
        await _apiService.login(user.serverAdress!, user.name!, user.password!);
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
    user.password = password;
    _databaseService.put(user.id! + user.serverAdress!, user);
    _databaseService.put("currentProfileId", user.id! + user.serverAdress!);

    _authStateStream.add(true);
  }

  void updateCurrentProfileIndex(String? profileId) async {
    if (profileId == null) {
      _databaseService.delete("currentProfileId");
    }
    _databaseService.put("currentProfileId", profileId);
  }

  Future logout({String? profileId}) async {
    profileId ??= currentProfileid();
    _databaseService.delete(profileId!);
    _databaseService.delete("currentProfileId");
    _authStateStream.add(false);
  }

  Future switchProfile(String profileId) async {
    User? user = _databaseService.get(profileId);
    if (user != null &&
        user.serverAdress != null &&
        user.name != null &&
        user.password != null) {
      await _apiService.login(user.serverAdress!, user.name!, user.password!);
      _authStateStream.add(true);
    } else {
      throw Exception("Profile not found");
    }
  }

  String? currentProfileid() {
    String? currentProfileIndexString =
        _databaseService.get("currentProfileId");
    return currentProfileIndexString;
  }

  Future<List<User>> getAllProfiles() async {
    Map allValues = await _databaseService.getAll();
    allValues.remove("currentProfileId");
    List<User> profiles = allValues.values.map((e) => e as User).toList();

    return profiles;
  }
}
