import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:jellyflix/components/profile_placeholder_image.dart';
import 'package:jellyflix/models/user.dart';
import 'package:flutter/material.dart';
import 'package:jellyflix/navigation/app_router.dart';
import 'package:jellyflix/services/device_info_service.dart';
import 'package:openapi/openapi.dart';
import 'package:built_collection/built_collection.dart';

class ApiService {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  Openapi? _jellyfinApi;
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

  Future buildHeader() async {
    var model = await _deviceInfoService.getDeviceModel();
    var deviceId = await _deviceInfoService.getDeviceId();
    var version = await _deviceInfoService.getVersion();
    headers["Authorization"] =
        "MediaBrowser Client=\"Jellyflix\", Device=\"$model\", DeviceId=\"$deviceId\", Version=\"$version\"";
  }

  Future<User> login(String baseUrl, String username, String pw) async {
    // TODO add error handling
    await buildHeader();
    _jellyfinApi = Openapi(
        dio: Dio(BaseOptions(
      baseUrl: baseUrl,
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
    )));
    var response = await _jellyfinApi!.getUserApi().authenticateUserByName(
        authenticateUserByName: AuthenticateUserByName((b) => b
          ..username = username
          ..pw = pw),
        headers: headers);

    headers["Authorization"] =
        "${headers["Authorization"]!}, Token=\"${response.data!.accessToken!}\"";
    headers["Origin"] = baseUrl;
    _user = User(
      id: response.data!.user!.id,
      name: response.data!.user!.name,
      serverAdress: baseUrl,
      token: response.data!.accessToken!,
    );
    return _user!;
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

  CachedNetworkImage getImage({
    required String id,
    required ImageType type,
    String? blurHash,
    BorderRadius? borderRadius,
    int? cacheHeight,
  }) {
    String url = getImageUrl(id, type);

    return CachedNetworkImage(
      //cacheManager: CustomCacheManager.instance,
      width: double.infinity,
      imageUrl: url,
      httpHeaders: headers,
      fit: BoxFit.cover,
      memCacheHeight: cacheHeight,
      maxHeightDiskCache: cacheHeight,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(10.0),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: blurHash == null
          ? null
          : (context, url) {
              return ClipRRect(
                borderRadius: borderRadius ?? BorderRadius.circular(10.0),
                child: BlurHash(
                  hash: blurHash,
                  imageFit: BoxFit.cover,
                ),
              );
            },
      errorWidget: (context, url, error) {
        return const SizedBox();
      },
      errorListener: (value) {
        //! Errors can't be caught right now
        //! There is a pr to fix this: https://github.com/Baseflow/flutter_cached_network_image/pull/777
      },
    );
  }

  CachedNetworkImage getProfileImage({User? user}) {
    user ??= _user!;
    return CachedNetworkImage(
      width: double.infinity,
      fit: BoxFit.cover,
      imageUrl: "${user.serverAdress}/Users/${user.id}/Images/Profile",
      placeholder: (context, url) {
        return const ProfilePlaceholderImage();
      },
      errorWidget: (context, url, error) {
        return const ProfilePlaceholderImage();
      },
      errorListener: (value) {
        //! Errors can't be caught right now
        //! There is a pr to fix this
      },
    );
  }

  Future<List<BaseItemDto>> getContinueWatching({String? parentId}) async {
    var response = await _jellyfinApi!.getItemsApi().getResumeItems(
        userId: _user!.id!, parentId: parentId, headers: headers);
    return response.data!.items!.toList();
  }

  Future<List<BaseItemDto>> getLatestItems(String collectionType,
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
    //keep only video folders
    var folders = response.data!.items!.where((element) {
      return element.collectionType == "movies" ||
          element.collectionType == "tvshows";
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
      List<String>? sortBy,
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

  Future<List<BaseItemDto>> getGenres() async {
    var response = await _jellyfinApi!.getGenresApi().getGenres(
          userId: _user!.id!,
          headers: headers,
          includeItemTypes: [
            BaseItemKind.movie,
            BaseItemKind.series,
            BaseItemKind.episode,
            BaseItemKind.boxSet
          ].toBuiltList(),
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
    if (response.data!.mediaSources!.toList().first.supportsDirectPlay ==
        true) {
      url =
          "${_user!.serverAdress}/Videos/$itemId/stream?mediaSourceId=$itemId&AudioStreamIndex=${audioStreamIndex ?? response.data!.mediaSources!.first.defaultAudioStreamIndex!}&SubtitleStreamIndex=${subtitleStreamIndex ?? response.data!.mediaSources!.first.defaultSubtitleStreamIndex ?? -1}";
    } else if (response.data!.mediaSources!
            .toList()
            .first
            .supportsDirectStream ==
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
    var deviceProfile = ClientCapabilitiesDeviceProfileBuilder();
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
          ..protocol = "hls",
      )
    ]);

    deviceProfile.containerProfiles = ListBuilder<ContainerProfile>([]);
    deviceProfile.subtitleProfiles = ListBuilder<SubtitleProfile>([
      SubtitleProfile((b) => b
        ..format = "vtt"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "ssa"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "ass"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "srt"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "pgs"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "pgssub"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "dvdsub"
        ..method = SubtitleDeliveryMethod.embed),
      SubtitleProfile((b) => b
        ..format = "dvbsub"
        ..method = SubtitleDeliveryMethod.embed),
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
      var response = await _jellyfinApi!.getQuickConnectApi().authorize(
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
    var recentlyPlayed =
        await getFilterItems(isPlayed: true, sortBy: ["LastPlayed"], limit: 1);
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
      if (view.collectionType == "playlists") {
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
      await _jellyfinApi!.getPlaylistsApi().addToPlaylist(
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
      await _jellyfinApi!.getPlaylistsApi().removeFromPlaylist(
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
      return element.collectionType == "movies";
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
    var response = await similarItemsByLastWatched();
    var response2 = await getFilterItems(
        sortBy: ["DateCreated"],
        sortOrder: [SortOrder.descending],
        includeItemTypes: [BaseItemKind.series, BaseItemKind.movie],
        limit: 5);

    return response + response2;
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
}
