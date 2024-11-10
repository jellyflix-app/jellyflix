import 'dart:async';

import 'package:dio/dio.dart';
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
        if (user != null) {
          await _apiService.registerAccessToken(user);
          _authStateStream.add(true);
          return true;
        }
      } catch (_) {
      }

        _authStateStream.add(false);
        return false;
    }
  }

  Future<User?> loginByQuickConnect(
      String serverAddress, Function(String) code, CancelToken token) async {
    final (url, candidates) = await inferServerUrl(serverAddress);
    if (url == null) {
      throw Exception('No valid server found on the given url\n'
          '\nTried the following urls:\n'
          '${candidates.join('\n-------------\n')}');
    }

    final user = await _apiService.loginByQuickConnect(
      url,
      code,
      token,
    );

    if (user == null) {
      return null;
    }

    _databaseService.put(user.id! + serverAddress, user);
    _databaseService.put("currentProfileId", user.id! + serverAddress);

    _authStateStream.add(true);
    return user;
  }

  Future<User> login(User user) async {
    final (url, candidates) = await inferServerUrl(user.serverAdress!);
    if (url == null) {
      throw Exception('No valid server found on the given url\n'
          '\nTried the following urls:\n'
          '${candidates.join('\n-------------\n')}');
    }

    user = await _apiService.login(
      url,
      user.name!,
      user.password!,
    );

    _databaseService.put(user.id! + user.serverAdress!, user);
    _databaseService.put("currentProfileId", user.id! + user.serverAdress!);

    _authStateStream.add(true);
    return user;
  }

  /// infer the server URL based on the provided incomplete URL.
  Future<(String?, List<String>)> inferServerUrl(String url) async {
    final candidates = generateUrlCandidates(url);
    for (final url in candidates) {
      if (await _isValidJellyfinServer(url)) {
        return (url, <String>[]);
      }
    }
    return (null, candidates);
  }

  Future<bool> _isValidJellyfinServer(String url) async =>
      await _apiService.ping(user: User(serverAdress: url)) ?? false;

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
    if (user != null && user.serverAdress != null && user.token != null) {
      await _apiService.registerAccessToken(user);
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

/// Function to generate URL candidates based on the input URL.
List<String> generateUrlCandidates(String input) {
  if (input.endsWith('/')) {
    input = input.substring(0, input.length - 1);
  }

  final result = parseUrl(input);
  if (result == null) return [];

  final (scheme, host, port, path) = result;

  List<String> protoCandidates = [];
  List<String> supportedProtos = ['https:', 'http:'];

  if (scheme.isNotEmpty) {
    protoCandidates.add('$scheme//$host');
  } else {
    // The user did not declare a protocol
    for (String proto in supportedProtos) {
      protoCandidates.add('$proto//$host');
    }
  }

  List<String> finalCandidates = [];
  if (port.isNotEmpty) {
    for (String candidate in protoCandidates) {
      finalCandidates.add('$candidate:$port$path');
    }
  } else {
    // The port wasn't declared, so use default Jellyfin and protocol ports
    for (final finalUrl in protoCandidates) {
      // add url without port
      finalCandidates.add('$finalUrl$path');
      // Jellyfin defaults
      if (finalUrl.startsWith('https')) {
        finalCandidates.add('$finalUrl:8920$path');
      } else if (finalUrl.startsWith('http')) {
        finalCandidates.add('$finalUrl:8096$path');
      }
    }
  }

  return finalCandidates;
}

/// parse url and separate it into its components
/// if you are wondering why we don't use Uri.tryParse() it cannot parse ipv4 or ipv6 addresses
(String, String, String, String)? parseUrl(String input) {
  if (!(input.startsWith('http://') || input.startsWith('https://'))) {
    // fill in a empty protocol, so regex matches
    input = 'none://$input';
  }

  final rgx = RegExp(r'^(.*:)//([A-Za-z0-9\-.]+)(:[0-9]+)?(.*)$');
  final match = rgx.firstMatch(input);

  if (match != null) {
    var scheme = match.group(1) ?? '';
    final body = match.group(2) ?? '';
    final port = match.group(3)?.substring(1) ?? ''; // Remove leading colon
    final path = match.group(4) ?? '';

    if (scheme == 'none:') {
      scheme = '';
    }
    return (scheme, body, port, path);
  }
  return null;
}
