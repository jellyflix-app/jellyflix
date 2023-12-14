import 'package:jellyflix/models/user.dart';
import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';

class ApiService {
  Openapi? _jellyfinApi;
  String? _baseUrl;
  User? _user;
  Map<String, String> headers = {
    "Accept": "application/json",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate",
    "Authorization":
        "MediaBrowser Client=\"AnotherJellyfinClient\", Device=\"notset\", DeviceId=\"Unknown Device Id\", Version=\"10.8.11\"",
    "Content-Type": "application/json",
    "Origin": "http://192.168.179.21:8096",
    "Connection": "keep-alive",
  };

  build() {
    return ApiService();
  }

  login(String baseUrl, String username, String pw) async {
    // TODO add error handling
    _jellyfinApi = Openapi(basePathOverride: baseUrl);
    var response = await _jellyfinApi!.getUserApi().authenticateUserByName(
        authenticateUserByNameRequest: AuthenticateUserByNameRequest((b) => b
          ..username = username
          ..pw = pw),
        headers: headers);

    headers["Authorization"] =
        "${headers["Authorization"]!}, Token=\"${response.data!.accessToken!}\"";
    _baseUrl = baseUrl;
    _user = User(
      id: response.data!.user!.id,
      name: response.data!.user!.name,
    );
  }

  Future<BaseItemDto> getItemDetails(String id) async {
    var response = await _jellyfinApi!.getUserLibraryApi().getItem(
          userId: _user!.id!,
          itemId: id,
          headers: headers,
        );
    return response.data!;
  }

  NetworkImage getImage(String id, ImageType type) {
    String url = "$_baseUrl/Items/$id/Images/${type.name}";
    return NetworkImage(url, headers: headers);
  }

  Future getContinueWatching() async {
    var response = await _jellyfinApi!
        .getItemsApi()
        .getResumeItems(userId: _user!.id!, headers: headers);
    return response.data!;
  }

  Future getLatestItems(String collectionType) async {
    var items = [];
    var folders = await getMediaFolders();
    // get all movie collections and their ids
    var movieCollections = folders.items!.where((element) {
      return element.collectionType == collectionType;
    }).toList();
    var movieCollectionIds = movieCollections.map((e) {
      return e.id!;
    }).toList();

    for (var id in movieCollectionIds) {
      var response = await _jellyfinApi!
          .getUserLibraryApi()
          .getLatestMedia(userId: _user!.id!, parentId: id, headers: headers);

      // add response to list
      items.addAll(response.data!);
    }
    return items;
  }

  Future getMediaFolders() async {
    var response =
        await _jellyfinApi!.getLibraryApi().getMediaFolders(headers: headers);

    return response.data!;
  }

  Future getEpisodes(String id) async {
    var response = await _jellyfinApi!
        .getTvShowsApi()
        .getEpisodes(userId: _user!.id!, seriesId: id, headers: headers);
    return response.data!;
  }

  getStreamUrl(String itemId) {
    if (_baseUrl == null) {
      throw Exception("Not logged in");
    } else {
      return "$_baseUrl/videos/$itemId/master.m3u8?MediaSourceId=$itemId";
    }
  }
}
