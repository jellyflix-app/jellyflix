import 'package:jellyflix/services/api_service.dart';
import 'package:jellyflix/services/secure_storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final SecureStorageService _secureStorageService;
  bool isAuthenticated = false;

  AuthService(
      {required ApiService apiService,
      required SecureStorageService secureStorageService})
      : _apiService = apiService,
        _secureStorageService = secureStorageService;

  Future<bool> checkAuthentication() async {
    String? storedUsername = await _secureStorageService.read("username");
    String? storedPassword = await _secureStorageService.read("password");
    String? storedServerAdress =
        await _secureStorageService.read("serverAdress");
    try {
      if (storedUsername != null &&
          storedPassword != null &&
          storedServerAdress != null) {
        await _apiService.login(
            storedServerAdress, storedUsername, storedPassword);
        isAuthenticated = true;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future login(String serverAdress, String username, String password) async {
    if (!serverAdress.startsWith("http://") &&
        !serverAdress.startsWith("https://")) {
      serverAdress = "http://$serverAdress";
    }
    try {
      await _apiService.login(serverAdress, username, password);
    } catch (e) {
      if (serverAdress.split(":").last != "8096" &&
          serverAdress.split(":").length == 2) {
        serverAdress = "$serverAdress:8096";
        await _apiService.login(serverAdress, username, password);
      } else {
        rethrow;
      }
    }
    await _secureStorageService.write("username", username);
    await _secureStorageService.write("password", password);
    await _secureStorageService.write("serverAdress", serverAdress);
    isAuthenticated = true;
  }

  Future logout() async {
    await _secureStorageService.delete("username");
    await _secureStorageService.delete("password");
    await _secureStorageService.delete("serverAdress");
    isAuthenticated = false;
  }
}
