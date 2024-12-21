import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:jellyflix/models/user.dart';
import 'package:flutter/material.dart';
import 'package:jellyflix/navigation/app_router.dart';
import 'package:jellyflix/services/device_info_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tentacle/tentacle.dart';
import 'package:built_collection/built_collection.dart';

class ApiService {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  Tentacle? _jellyfinApi;
  User? _user;
  Map<String, String> headers = {
    "Accept": "application/json",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate",
    "Authorization":
        "MediaBrowser Client=\"Jellyflix\", Device=\"notset\", DeviceId=\"Unknown Device Id\", Version=\"10.8.11\"",
    "Content-Type": "application/json",
    "Connection": "keep-alive",
  };

  PlaybackInfoResponse? playbackInfo;

  User? get currentUser => _user;

  ApiService();

  Future<String> buildHeader() async {
    var model = await _deviceInfoService.getDeviceModel();
    var deviceId = await _deviceInfoService.getDeviceId();
    var version = await _deviceInfoService.getVersion();
    return "MediaBrowser Client=\"Jellyflix\", Device=\"$model\", DeviceId=\"$deviceId\", Version=\"$version\"";
  }

  Future<User> login(String baseUrl, String username, String pw) async {
    // TODO add error handling
    String authHeader = await buildHeader();
    await buildHeader();
    _jellyfinApi = Tentacle(
        dio: Dio(BaseOptions(
      baseUrl: baseUrl,
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 5),
    )));

    var response = await _jellyfinApi!.getUserApi().authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName((b) => b
          ..username = username
          ..pw = pw),
        headers: headers);

    headers["Authorization"] =
        "$authHeader, Token=\"${response.data!.accessToken!}\"";

    headers["Origin"] = baseUrl;
    _user = User(
      id: response.data!.user!.id,
      name: response.data!.user!.name,
      password: pw,
      serverAdress: baseUrl,
      token: response.data!.accessToken!,
    );
    return _user!;
  }

  Future<void> registerAccessToken(User user) async {
    _user = user;

    String authHeader = await buildHeader();

    _jellyfinApi = Tentacle(
        dio: Dio(BaseOptions(
      baseUrl: user.serverAdress!,
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 5),
    )));

    headers["Authorization"] =
        "$authHeader, Token=\"${user.token}\"";

    headers["Origin"] = user.serverAdress!;
  }

  Future<User?> loginByQuickConnect(String baseUrl,
      Function(String) secretCallback, CancelToken token) async {
    // TODO add error handling
    String authHeader = await buildHeader();
    await buildHeader();
    _jellyfinApi = Tentacle(
        dio: Dio(BaseOptions(
      baseUrl: baseUrl,
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 5),
    )));

    var response = await _jellyfinApi!
        .getQuickConnectApi()
        .initiateQuickConnect(headers: headers);

    if (response.statusCode != 200) {
      return null;
    }

    var code = response.data?.code;

    if (code == null) {
      return null;
    }

    secretCallback(code);

    while (!token.isCancelled) {
      var stateResponse = await _jellyfinApi
          ?.getQuickConnectApi()
          .getQuickConnectState(secret: response.data!.secret!, cancelToken: token);

      if (stateResponse?.data?.authenticated == true) {
        var response =
            await _jellyfinApi?.getUserApi().authenticateWithQuickConnect(
                  quickConnectDto: QuickConnectDto(
                      (b) => b..secret = stateResponse!.data!.secret),
                  headers: headers,
                  cancelToken: token,
                );

        if (response!.statusCode != 200) {
          return null;
        }

        headers["Authorization"] =
            "$authHeader, Token=\"${response.data!.accessToken!}\"";

        headers["Origin"] = baseUrl;
        _user = User(
          id: response.data!.user!.id,
          name: response.data!.user!.name,
          serverAdress: baseUrl,
          token: response.data!.accessToken!,
        );

        return _user;
      }
    }

    return null;
  }

  Future<void> logout() async {
    _user = null;
    _jellyfinApi = null;
  }

  Future checkAuthentication() async {
    if (_user == null) {
      return false;
    }
    try {
      var response = await _jellyfinApi!.getUserApi().getCurrentUser(
            headers: headers,
          );
      if (response.data!.id == _user!.id) {
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<BaseItemDto> getItemDetails(String id) async {
    var response = await _jellyfinApi!.getUserLibraryApi().getItem(
          userId: _user!.id!,
          itemId: id,
          headers: headers,
        );
    return response.data!;
  }

  String getImageUrl(String id, ImageType type) {
    return "${_user!.serverAdress}/Items/$id/Images/${type.name}";
  }

  Future<List<BaseItemDto>> getContinueWatching({String? parentId}) async {
    var response = await _jellyfinApi!.getItemsApi().getResumeItems(
        userId: _user!.id!, parentId: parentId, headers: headers);
    return response.data!.items!.toList();
  }

  Future<List<BaseItemDto>> getLatestItems(CollectionType collectionType,
      {int? limit}) async {
    List<BaseItemDto> items = [];
    var folders = await getMediaFolders();
    // get all movie collections and their ids
    var movieCollections = folders.where((element) {
      return element.collectionType == collectionType;
    }).toList();
    var movieCollectionIds = movieCollections.map((e) {
      return e.id!;
    }).toList();
    if (limit != null) {
      limit = (limit / movieCollectionIds.length).floor();
      if (limit == 0) {
        limit = 1;
      }
    }

    for (var id in movieCollectionIds) {
      var response = await _jellyfinApi!.getUserLibraryApi().getLatestMedia(
          userId: _user!.id!,
          parentId: id,
          headers: headers,
          fields: BuiltList<ItemFields>([ItemFields.overview]),
          limit: limit);

      // add response to list
      items.addAll(response.data!);
    }
    return items;
  }

  Future<List<BaseItemDto>> getMediaFolders() async {
    var response = await _jellyfinApi!
        .getUserViewsApi()
        .getUserViews(userId: _user!.id!, headers: headers);
    // keep only video folders
    var folders = response.data!.items!.where((element) {
      return element.collectionType == CollectionType.movies ||
          element.collectionType == CollectionType.tvshows;
    }).toList();
    return folders;
    //return response.data!;
  }

  Future<List<BaseItemDto>> getEpisodes(String id) async {
    var response = await _jellyfinApi!.getTvShowsApi().getEpisodes(
        userId: _user!.id!,
        seriesId: id,
        headers: headers,
        fields: [ItemFields.mediaSources].toBuiltList());
    return response.data!.items!.toList();
  }

  Future<List<BaseItemDto>> getFilterItems(
      {List<BaseItemDto>? genreIds,
      String? searchTerm,
      bool? isPlayed,
      List<ItemSortBy>? sortBy,
      int? limit,
      int? startIndex,
      List<BaseItemKind>? includeItemTypes,
      List<SortOrder>? sortOrder,
      List<ItemFilter>? filters,
      double? minCommunityRating}) async {
    var ids = genreIds == null
        ? null
        : BuiltList<String>.from(genreIds.map((e) => e.id!));
    try {
      var response = await _jellyfinApi!.getItemsApi().getItems(
            userId: _user!.id!,
            headers: headers,
            genreIds: ids,
            searchTerm: searchTerm,
            recursive: true,
            isPlayed: isPlayed,
            filters: filters?.toBuiltList(),
            sortBy: sortBy?.toBuiltList(),
            sortOrder:
                sortOrder == null ? null : BuiltList<SortOrder>(sortOrder),
            limit: limit,
            startIndex: startIndex,
            enableTotalRecordCount: false,
            minCommunityRating: minCommunityRating,
            includeItemTypes: BuiltList<BaseItemKind>(
              includeItemTypes ??
                  [
                    BaseItemKind.movie,
                    BaseItemKind.series,
                    BaseItemKind.episode,
                    BaseItemKind.boxSet
                  ],
            ),
            fields: BuiltList<ItemFields>([
              ItemFields.overview,
              ItemFields.providerIds,
              ItemFields.mediaSources
            ]),
          );

      return response.data!.items!.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BaseItemDto>> getGenres(
      {List<BaseItemKind>? includeItemTypes}) async {
    var response = await _jellyfinApi!.getGenresApi().getGenres(
          userId: _user!.id!,
          headers: headers,
          includeItemTypes: (includeItemTypes ??
                  [
                    BaseItemKind.movie,
                    BaseItemKind.series,
                    BaseItemKind.episode,
                    BaseItemKind.boxSet
                  ])
              .toBuiltList(),
        );
    return response.data!.items!.toList();
  }

  /// Retrieves the stream URL and playback information for a video.
  ///
  /// Returns a [Future] that completes with a tuple containing the stream URL
  /// and the [PlaybackInfoResponse] object.
  ///
  /// The [streamUrl] is a [String] representing the URL of the video stream.
  /// The [playbackInfo] is a [PlaybackInfoResponse] object containing information
  /// about the playback, such as duration, bitrate, and video format.
  ///
  /// maxStreamingBitrate is the default bitrate set in the settings if null
  /// audioStreamIndex is the default audioStreamIndex set by jellyfin if null
  /// subtitleStreamIndex is the default subtitleStreamIndex set by jellyfin if null
  Future<(String, PlaybackInfoResponse)> getStreamUrlAndPlaybackInfo({
    required String itemId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? maxStreamingBitrate,
    int? startTimeTicks,
  }) async {
    Response<PlaybackInfoResponse> response = await postPlaybackInfoRequest(
        itemId,
        maxStreamingBitrate,
        audioStreamIndex,
        subtitleStreamIndex,
        startTimeTicks,
        false);

    String? url;
    // if (response.data!.mediaSources!.toList().first.supportsDirectPlay ==
    //     true) {
    //   url =
    //       "${_user!.serverAdress}/Videos/$itemId/stream?mediaSourceId=$itemId&AudioStreamIndex=${audioStreamIndex ?? response.data!.mediaSources!.first.defaultAudioStreamIndex!}&SubtitleStreamIndex=${subtitleStreamIndex ?? response.data!.mediaSources!.first.defaultSubtitleStreamIndex ?? -1}&Static=true";
    // } else
    if (response.data!.mediaSources!.toList().first.supportsDirectStream ==
        true) {
      url =
          "${_user!.serverAdress}/Videos/$itemId/stream.${response.data!.mediaSources!.first.container}?mediaSourceId=$itemId&AudioStreamIndex=${audioStreamIndex ?? response.data!.mediaSources!.first.defaultAudioStreamIndex!}&SubtitleStreamIndex=${subtitleStreamIndex ?? response.data!.mediaSources!.first.defaultSubtitleStreamIndex ?? -1}&Static=true";
    } else if (response.data!.mediaSources!.first.supportsTranscoding == true) {
      if (response.data!.mediaSources!.first.transcodingUrl == null) {
        response = await postPlaybackInfoRequest(itemId, maxStreamingBitrate,
            audioStreamIndex, subtitleStreamIndex, startTimeTicks, true);
      }
      url =
          "${_user!.serverAdress}${response.data!.mediaSources!.first.transcodingUrl}";
    }

    if (url != null) {
      playbackInfo = response.data!;
      return (url, response.data!);
    }

    throw Exception("Couldn't get stream url");
  }

  Future<Response<PlaybackInfoResponse>> postPlaybackInfoRequest(
      String itemId,
      int? maxStreaminBitrate,
      int? audioStreamIndex,
      int? subtitleStreamIndex,
      int? startTimeTicks,
      bool forceTranscoding) async {
    var deviceProfile = DeviceProfileBuilder();
    deviceProfile.directPlayProfiles = ListBuilder([
      DirectPlayProfile((b) => b..type = DlnaProfileType.video),
    ]);
    deviceProfile.transcodingProfiles = ListBuilder<TranscodingProfile>([
      TranscodingProfile(
        (b) => b
          ..container = "ts"
          ..type = DlnaProfileType.video
          ..audioCodec = "aac,ac3,eac3"
          ..videoCodec = "h264,hevc"
          ..protocol = MediaStreamProtocol.hls,
      )
    ]);

    deviceProfile.containerProfiles = ListBuilder<ContainerProfile>([]);
    deviceProfile.subtitleProfiles = ListBuilder<SubtitleProfile>([
      SubtitleProfile((b) => b
        ..format = "vtt"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "vtt"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "ssa"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "ssa"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "ass"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "ass"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "srt"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "srt"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "pgs"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "pgs"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "pgssub"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "pgssub"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "dvdsub"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "dvdsub"
        ..method = SubtitleDeliveryMethod.external_),
      SubtitleProfile((b) => b
        ..format = "dvbsub"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "dvbsub"
        ..method = SubtitleDeliveryMethod.external_),
    ]);
    var response = await _jellyfinApi!.getMediaInfoApi().getPostedPlaybackInfo(
          itemId: itemId,
          headers: headers,
          playbackInfoDto: PlaybackInfoDto((b) => b
            ..userId = _user!.id!
            ..mediaSourceId = itemId
            ..autoOpenLiveStream = true
            ..enableDirectPlay = !forceTranscoding
            ..enableDirectStream = !forceTranscoding
            ..startTimeTicks = startTimeTicks
            ..maxStreamingBitrate =
                maxStreaminBitrate ?? 1000000000 // TODO set in settings
            ..audioStreamIndex =
                audioStreamIndex // should use the default audioStream determined by jellyfin if null
            ..subtitleStreamIndex = subtitleStreamIndex
            ..deviceProfile = deviceProfile),
        );

    playbackInfo = response.data;
    return response;
  }

  Future<int> authorizeQuickConnect(String secret) async {
    try {
      var response =
          await _jellyfinApi!.getQuickConnectApi().authorizeQuickConnect(
                code: secret,
                headers: headers,
              );
      if (response.data! == true) {
        return 200;
      } else {
        return 400;
      }
    } on DioException catch (_) {
      return _.response!.statusCode ?? 400;
    }
  }

  Future<List<BaseItemDto>> getTopTenPopular() async {
    // TODO cache to increase performance
    // get locale
    Locale locale = Localizations.localeOf(navigatorKey.currentContext!);
    String countryCode = locale.countryCode ?? locale.languageCode;
    countryCode = countryCode.toUpperCase();
    Response responseMovie;
    // get top 10000 from url
    try {
      responseMovie = await Dio().get(
          "https://raw.githubusercontent.com/jellyflix-app/popular-movies-data/main/$countryCode-popular-movie.json");
    } catch (e) {
      responseMovie = await Dio().get(
          "https://raw.githubusercontent.com/jellyflix-app/popular-movies-data/main/US-popular-movie.json");
    }
    // TMDB tv shows regions filter doesn't work
    var responseTv = await Dio().get(
        "https://raw.githubusercontent.com/jellyflix-app/popular-movies-data/main/US-popular-tv.json");

    List movieJson = jsonDecode(responseMovie.data);
    List tvJson = jsonDecode(responseTv.data);

    List<BaseItemDto> library = await getFilterItems(
        includeItemTypes: [BaseItemKind.movie, BaseItemKind.series]);
    List<BaseItemDto> movieLibrary = library.where((element) {
      return element.type == BaseItemKind.movie;
    }).toList();
    List<BaseItemDto> tvLibrary = library.where((element) {
      return element.type == BaseItemKind.series;
    }).toList();
    library = movieLibrary + tvLibrary;

    List<dynamic> popular = matchItemWithPopularity(movieLibrary, movieJson);
    List<dynamic> popularTv = matchItemWithPopularity(tvLibrary, tvJson);

    popular.addAll(popularTv);

    // sort by popularity
    popular.sort((a, b) {
      return b["p"].compareTo(a["p"]);
    });

    // find the top then in library
    List<BaseItemDto> top10 = [];
    for (var i = 0; i < popular.length; i++) {
      var movie = popular[i];
      int movieId = movie["i"];
      for (var element in library) {
        if (element.providerIds == null) continue;
        if (element.providerIds!["Tmdb"] == null) continue;
        if (int.parse(element.providerIds!["Tmdb"]!) == movieId) {
          top10.add(element);
          break;
        }
      }

      if (top10.length == 10) {
        break;
      }
    }

    return top10;
  }

  List<dynamic> matchItemWithPopularity(
      List<BaseItemDto> library, List<dynamic> movieJson) {
    var popular = [];
    // check if providerId in library is in json file and return the movieJson entry
    for (var movie in library) {
      if (movie.providerIds == null) continue;
      var movieId = movie.providerIds!["Tmdb"];
      if (movieId != null) {
        var movieEntry = movieJson.firstWhere((element) {
          return element["i"] == int.parse(movieId);
        }, orElse: () => null);
        if (movieEntry != null) {
          popular.add(movieEntry);
        }
      }
    }

    // sort by popularity
    popular.sort((a, b) {
      return b["p"].compareTo(a["p"]);
    });
    return popular;
  }

  Future<void> reportStartPlayback(int positionTicks) async {
    await _jellyfinApi!.getPlaystateApi().reportPlaybackStart(
        headers: headers,
        playbackStartInfo: PlaybackStartInfo((b) => b
          ..itemId = playbackInfo!.mediaSources!.first.id!
          ..mediaSourceId = playbackInfo!.mediaSources!.first.id!
          ..playbackStartTimeTicks =
              DateTime.now().millisecondsSinceEpoch * 10000
          ..positionTicks = positionTicks
          ..playSessionId = playbackInfo!.playSessionId
          ..audioStreamIndex =
              playbackInfo!.mediaSources!.first.defaultAudioStreamIndex
          ..subtitleStreamIndex =
              playbackInfo!.mediaSources!.first.defaultSubtitleStreamIndex));
  }

  Future<void> reportPlaybackProgress(int positionTicks,
      {int? audioStreamIndex, int? subtitleStreamIndex}) async {
    await _jellyfinApi!.getPlaystateApi().reportPlaybackProgress(
        headers: headers,
        playbackProgressInfo: PlaybackProgressInfo((b) => b
          ..itemId = playbackInfo!.mediaSources!.first.id!
          ..mediaSourceId = playbackInfo!.mediaSources!.first.id!
          ..positionTicks = positionTicks
          ..playSessionId = playbackInfo!.playSessionId
          ..audioStreamIndex = audioStreamIndex ??
              playbackInfo!.mediaSources!.first.defaultAudioStreamIndex
          ..subtitleStreamIndex = subtitleStreamIndex ??
              playbackInfo!.mediaSources!.first.defaultSubtitleStreamIndex));
  }

  reportStopPlayback(int positionTicks,
      {String? itemId, String? playSessionId}) async {
    await _jellyfinApi!.getPlaystateApi().reportPlaybackStopped(
        headers: headers,
        playbackStopInfo: PlaybackStopInfo((b) => b
          ..itemId = itemId ?? playbackInfo?.mediaSources?.first.id
          ..mediaSourceId = itemId ?? playbackInfo?.mediaSources?.first.id
          ..positionTicks = positionTicks
          ..playSessionId = playSessionId ?? playbackInfo?.playSessionId));
  }

  Future<List<BaseItemDto>> getNextUpEpisode({String? seriesId}) async {
    try {
      Response<BaseItemDtoQueryResult> response = await _jellyfinApi!
          .getTvShowsApi()
          .getNextUp(
              headers: headers,
              seriesId: seriesId,
              enableTotalRecordCount: false,
              userId: _user!.id!,
              disableFirstEpisode: true);
      return response.data!.items!.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BaseItemDto>> continueWatchingAndNextUp() async {
    var continueWatching = await getContinueWatching();
    var nextUp = await getNextUpEpisode();

    // keep only unique items
    nextUp = nextUp.where((element) {
      return !continueWatching.contains(element);
    }).toList();

    return continueWatching + nextUp;
  }

  Future<List<BaseItemDto>> similarItems(String itemId, {int? limit}) async {
    var similarItems = await _jellyfinApi!.getLibraryApi().getSimilarItems(
          headers: headers,
          userId: _user!.id!,
          itemId: itemId,
          limit: limit,
          fields: [ItemFields.overview].toBuiltList(),
        );

    return similarItems.data!.items!.toList();
  }

  Future<List<BaseItemDto>> similarItemsByLastWatched() async {
    var recentlyPlayed = await getFilterItems(
        isPlayed: true, sortBy: [ItemSortBy.datePlayed], limit: 1);
    if (recentlyPlayed.isEmpty) {
      return [];
    }
    if (recentlyPlayed.first.type == BaseItemKind.episode) {
      return await similarItems(recentlyPlayed.first.seriesId!);
    }
    return await similarItems(recentlyPlayed.first.id!);
  }

  Future<List<BaseItemDto>> getPlaylistItems(String playlistId) async {
    var response = await _jellyfinApi!.getPlaylistsApi().getPlaylistItems(
          headers: headers,
          userId: _user!.id!,
          playlistId: playlistId,
        );
    return response.data!.items!.toList();
  }

  Future<String> getWatchlistId() async {
    var views = await _jellyfinApi!
        .getUserViewsApi()
        .getUserViews(userId: _user!.id!, headers: headers);
    // firstWhere views name == playlist
    Response<BaseItemDtoQueryResult>? playlist;
    for (var view in views.data!.items!) {
      if (view.collectionType == CollectionType.playlists) {
        String? playlistsId = view.id;
        // abort if no playlists folder exists
        if (playlistsId == null) {
          break;
        }

        // filter playlist by name
        playlist = await _jellyfinApi!.getItemsApi().getItems(
              userId: _user!.id!,
              headers: headers,
              includeItemTypes: BuiltList<BaseItemKind>(
                [
                  BaseItemKind.folder,
                ],
              ),
              parentId: playlistsId,
              searchTerm: "watchlist",
            );
        break;
      }
    }

    if (playlist != null && playlist.data!.items!.isNotEmpty) {
      return playlist.data!.items!.first.id!;
    } else {
      // create watchlist playlist
      var playlistResult = await _jellyfinApi!.getPlaylistsApi().createPlaylist(
            headers: headers,
            createPlaylistDto: CreatePlaylistDto(
              (b) => b
                ..isPublic = false
                ..name = "watchlist"
                ..userId = _user!.id!,
            ),
          );

      return playlistResult.data!.id!;
    }
  }

  Future<List<BaseItemDto>> getWatchlist() async {
    String watchlistId = await getWatchlistId();

    var watchlist = await getPlaylistItems(watchlistId);

    return watchlist;
  }

  Future<void> updateWatchlist(String itemId, bool add) async {
    String watchlistId = await getWatchlistId();
    if (add) {
      await _jellyfinApi!.getPlaylistsApi().addItemToPlaylist(
          headers: headers,
          userId: _user!.id!,
          playlistId: watchlistId,
          ids: [itemId].toBuiltList());
    } else {
      var watchlistItems = await getWatchlist();
      // get playlist item id
      String playlistItemId = watchlistItems.firstWhere((element) {
            return element.id! == itemId;
          }).playlistItemId ??
          "";
      await _jellyfinApi!.getPlaylistsApi().removeItemFromPlaylist(
            headers: headers,
            playlistId: watchlistId,
            entryIds: [playlistItemId].toBuiltList(),
          );
    }
  }

  Future<List<RecommendationDto>> getRecommendations() async {
    //! api only exists for movies
    var folders = await getMediaFolders();

    var movieCollections = folders.where((element) {
      return element.collectionType == CollectionType.movies;
    }).toList();
    var movieCollectionIds = movieCollections.map((e) {
      return e.id!;
    }).toList();

    List<RecommendationDto> recommendations = [];
    for (String folderId in movieCollectionIds) {
      var response = await _jellyfinApi!.getMoviesApi().getMovieRecommendations(
            userId: _user!.id!,
            headers: headers,
            parentId: folderId,
          );
      // add response to list
      recommendations.addAll(response.data!);
    }

    return recommendations;
  }

  Future<void> startLibraryScan() async {
    await _jellyfinApi!.getLibraryApi().refreshLibrary(
          headers: headers,
        );
  }

  Future<List<BaseItemDto>> getHeaderRecommendation() async {
    return await getFilterItems(
            sortBy: [ItemSortBy.dateCreated],
            sortOrder: [SortOrder.descending],
            includeItemTypes: [BaseItemKind.movie],
            limit: 3) +
        await getFilterItems(
            sortBy: [ItemSortBy.dateLastContentAdded],
            sortOrder: [SortOrder.descending],
            includeItemTypes: [BaseItemKind.series],
            limit: 4);
  }

  Future<void> markAsPlayed(
      {required String itemId, required bool played}) async {
    if (played) {
      await _jellyfinApi!
          .getPlaystateApi()
          .markPlayedItem(userId: _user!.id!, itemId: itemId, headers: headers);
    } else {
      await _jellyfinApi!.getPlaystateApi().markUnplayedItem(
          userId: _user!.id!, itemId: itemId, headers: headers);
    }
  }

  Future<bool?> ping({User? user}) async {
    user ?? _user;
    // returns false if serverAdress is null or server is unreachable
    if (user?.serverAdress == null) {
      return null;
    }

    try {
      var result = await Dio()
          .get(
            "${user!.serverAdress!}/System/Ping",
          )
          .timeout(const Duration(seconds: 2));
      if (result.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<SubtitleTrack> getExternalSubtitle(
      {required String deliveryUrl}) async {
    if (deliveryUrl.split("?")[0].endsWith(".vtt")) {
      var response = await Dio().get(_user!.serverAdress! + deliveryUrl);
      final lines = response.data!.split('\n');
      final result = <String>[];
      for (var line in lines) {
        // Skip lines that contain 'Region:' or 'region:'
        if (!line.startsWith('Region:') && !line.contains('region:')) {
          result.add(line);
        } else if (line.contains('region:')) {
          // Remove 'region:' parameter within timestamp lines
          final modifiedLine = line.replaceAll(RegExp(r'region:[^\s]+'), '');
          result.add(modifiedLine.trim());
        }
      }
      return SubtitleTrack.data(result.join("\n"));
    } else {
      return SubtitleTrack.uri(_user!.serverAdress! + deliveryUrl);
    }
  }
}
