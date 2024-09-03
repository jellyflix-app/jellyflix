import 'dart:async';

import 'package:jellyflix/models/user.dart';
import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/database_service.dart';

class AuthService {
  final ApiService _apiService;

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

  Future<bool> checkAuthentication() async {
    bool authenticated = await _apiService.checkAuthentication();
    if (authenticated) {
      _authStateStream.add(true);
      return true;
    } else {
      String? profileId = currentProfileid();
      if (profileId == null) {
        _authStateStream.add(false);
        return false;
      }
      User? user = _databaseService.get(profileId);
      try {
        await login(user!);
        _authStateStream.add(true);
        return true;
      } catch (_) {
        _authStateStream.add(false);
        return false;
      }
    }
  }

  Future<User> login(User user) async {
    if (!user.serverAdress!.startsWith("http://") &&
        !user.serverAdress!.startsWith("https://")) {
      user.serverAdress = "http://${user.serverAdress}";
    }
    try {
      user = await _apiService.login(
          user.serverAdress!, user.name!, user.password!);
    } catch (e) {
      if (user.serverAdress!.split(":").last != "8096" &&
          user.serverAdress!.split(":").length == 2) {
        user.serverAdress = "${user.serverAdress}:8096";
        user = await _apiService.login(
            user.serverAdress!, user.name!, user.password!);
      } else {
        rethrow;
      }
    }
    _databaseService.put(user.id! + user.serverAdress!, user);
    _databaseService.put("currentProfileId", user.id! + user.serverAdress!);

    _authStateStream.add(true);
    return user;
  }

  void updateCurrentProfileId(String? profileId) async {
    if (profileId == null) {
      _databaseService.delete("currentProfileId");
    }
    _databaseService.put("currentProfileId", profileId);
  }

  Future<void> logout() async {
    await _apiService.logout();
    _authStateStream.add(false);
  }

  /// [profileId] is a combination of userid and server url
  Future<void> logoutAndDeleteProfile({String? profileId}) async {
    await logout();
    profileId ??= currentProfileid();
    _databaseService.delete(profileId!);
    _databaseService.delete("currentProfileId");
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

  Future<bool?> checkServerReachable({String? profileId}) async {
    // get latest element from the stream
    profileId ??= currentProfileid();
    if (profileId == null) {
      return null;
    }
    User? user = _databaseService.get(profileId);

    return await _apiService.ping(user: user);
  }
}
